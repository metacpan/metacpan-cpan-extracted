#pragma once
#include <panda/lib.h>
#include <panda/string.h>
#include <panda/string_map.h>
#include <panda/string_view.h>

namespace panda { namespace uri {

using panda::string;
using std::string_view;

class Query : public panda::string_multimap<string, string> {
private:
    typedef panda::string_multimap<key_type,mapped_type> Base;

public:
    uint32_t rev;

    Query ()               : Base(),  rev(1) {}
    Query (const Query& x) : Base(x), rev(1) {}

    Query& operator= (const Query& x) {
        rev++;
        Base::operator=(x);
        return *this;
    }

    iterator insert (const value_type& val)                        { rev++; return Base::insert(val); }
    template <class P>
    iterator insert (P&& value)                                    { rev++; return Base::insert(std::forward(value)); }
    iterator insert (const_iterator hint, const value_type& value) { rev++; return Base::insert(hint, value); }
    template <class P>
    iterator insert (const_iterator hint, P&& value)               { rev++; return Base::insert(hint, std::forward(value)); }
    template <class InputIt>
    void     insert (InputIt first, InputIt last)                  { rev++; Base::insert(first, last); }
    void     insert (std::initializer_list<value_type> ilist)      { rev++; return Base::insert(ilist); }

    template <class... Args>
    iterator emplace (Args&&... args) { rev++; return Base::emplace(std::forward<Args>(args)...); }

    template <class... Args>
    iterator emplace_hint (const_iterator hint, Args&&... args) { rev++; return Base::emplace(hint, std::forward(args)...); }

    iterator  erase (const_iterator pos)                        { rev++; return Base::erase(pos); }
    iterator  erase (const_iterator first, const_iterator last) { rev++; return Base::erase(first, last); }
    size_type erase (const key_type& key)                       { rev++; return Base::erase(key); }
    size_type erase (const string_view& sv)                     { rev++; return Base::erase(sv); }

    void swap (Query& x) {
        rev++;
        x.rev++;
        Base::swap(x);
    }

    void clear () { rev++; Base::clear(); }

    using Base::begin;
    using Base::rbegin;
    using Base::end;
    using Base::rend;
    using Base::find;
    using Base::lower_bound;
    using Base::upper_bound;
    using Base::equal_range;

    iterator         begin  () { rev++; return Base::begin(); }
    reverse_iterator rbegin () { rev++; return Base::rbegin(); }
    iterator         end    () { rev++; return Base::end(); }
    reverse_iterator rend   () { rev++; return Base::rend(); }

    iterator find        (const key_type& k)     { rev++; return Base::find(k); }
    iterator find        (const string_view& sv) { rev++; return Base::find(sv); }
    iterator lower_bound (const key_type& k)     { rev++; return Base::lower_bound(k); }
    iterator lower_bound (const string_view& sv) { rev++; return Base::lower_bound(sv); }
    iterator upper_bound (const key_type& k)     { rev++; return Base::upper_bound(k); }
    iterator upper_bound (const string_view& sv) { rev++; return Base::upper_bound(sv); }

    std::pair<iterator,iterator> equal_range (const key_type& k)     { rev++; return Base::equal_range(k); }
    std::pair<iterator,iterator> equal_range (const string_view& sv) { rev++; return Base::equal_range(sv); }
};

}}
