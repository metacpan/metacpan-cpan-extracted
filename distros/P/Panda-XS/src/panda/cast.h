#pragma once
#include <map>
#include <typeinfo>
#include <stdint.h>
#include <stddef.h>
#include <type_traits>

namespace panda {


namespace {
    typedef std::map<intptr_t, ptrdiff_t> DynCastCacheMap;
    template <class DERIVED, class BASE> struct DynCastCache {
        static DynCastCacheMap map;
    };
    template <class DERIVED, class BASE> DynCastCacheMap DynCastCache<DERIVED,BASE>::map;

    const ptrdiff_t INCORRECT_PTRDIFF = sizeof(ptrdiff_t) == 4 ? 2147483647 : 9223372036854775807LL;
}

template <class DERIVED_PTR, class BASE>
DERIVED_PTR dyn_cast (BASE* obj) {
    typedef typename std::remove_pointer<DERIVED_PTR>::type DERIVED;
    if (!obj) return NULL;
    intptr_t key = (intptr_t)typeid(*obj).name();
    DynCastCacheMap::iterator it = DynCastCache<DERIVED,BASE>::map.find(key);
    if (it != DynCastCache<DERIVED,BASE>::map.end())
        return it->second != INCORRECT_PTRDIFF ? reinterpret_cast<DERIVED*>((char*)obj - it->second) : NULL;
    DERIVED* ret = dynamic_cast<DERIVED*>(obj);
    if (ret) DynCastCache<DERIVED,BASE>::map[key] = (char*)obj - (char*)ret;
    else DynCastCache<DERIVED,BASE>::map[key] = INCORRECT_PTRDIFF;
    return ret;
}

template <class DERIVED_REF, class BASE>
DERIVED_REF dyn_cast (BASE& obj) {
    typedef typename std::remove_reference<DERIVED_REF>::type DERIVED;
    intptr_t key = (intptr_t)typeid(obj).name();
    DynCastCacheMap::iterator it = DynCastCache<DERIVED,BASE>::map.find(key);
    if (it != DynCastCache<DERIVED,BASE>::map.end() && it->second != INCORRECT_PTRDIFF)
        return *(reinterpret_cast<DERIVED*>((char*)&obj - it->second));
    // dont cache fails, as exceptions are much slower than dynamic_cast, let it always fall here
    DERIVED& ret = dynamic_cast<DERIVED&>(obj);
    DynCastCache<DERIVED,BASE>::map[key] = (char*)&obj - (char*)&ret;
    return ret;
}

}
