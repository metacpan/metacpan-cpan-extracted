#pragma once

#include <panda/CallbackDispatcher.h>
#include <iostream>
#include <xs/xs.h>

namespace xs {
namespace lib {

using XSCallbackDispatcher = panda::CallbackDispatcher<SV*(SV**, size_t)>;

using xs::my_perl;

struct CallbackCVWrapperBase {
    CallbackCVWrapperBase(CV* cv) : cv(cv) {};

    SvIntrPtr cv;

    bool operator ==(CV* oth) const{
        return cv.get<CV>() == oth;
    }

    bool operator ==(const CallbackCVWrapperBase& oth) const {
        return cv.get<CV>() == oth.cv.get<CV>();
    }
};

struct CallbackCVWrapperSimple : CallbackCVWrapperBase {
    using CallbackCVWrapperBase::CallbackCVWrapperBase;

    SV* operator()(SV** args, size_t items) {
        return xs::call_sub_scalar(aTHX_ cv.get<CV>(), args, items);
    }
};

struct CallbackCVWrapperExt : CallbackCVWrapperBase{
    template <typename T>
    CallbackCVWrapperExt(T&& lambda, CV* cv)
        : CallbackCVWrapperBase(cv)
        , lambda(std::forward<T>(lambda))
    {}

    panda::optional<SV*> operator()(XSCallbackDispatcher::Event& e, SV** args, size_t items) {
        return lambda(e, args, items);
    }

    XSCallbackDispatcher::Callback lambda;
};

}//lib
}//xs

