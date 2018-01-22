#pragma once

#include <panda/CallbackDispatcher.h>
#include <xs/xs.h>
#include <vector>

namespace xs {

using namespace ::panda;

struct XSCallbackDispatcher : public virtual RefCounted {
    virtual void add(SvIntrPtr cv)= 0;
    virtual void remove(SvIntrPtr cv) = 0;
};

template <typename... Args>
XSCallbackDispatcher* make_xs_wrapper(CallbackDispatcher<void, Args...>& dispatcher,
                                      shared_ptr<RefCounted> parent,
                                      function<SV*(Args&)>... convs);

namespace {

using xs::my_perl;

template <typename... Args>
struct ArgsConverter {
    template <typename T>
    using Conv = function<SV*(T&)>;

    SvIntrPtr cv;
    using ConvertersTuple = std::tuple<Conv<Args>...>;
    using Converters = shared_ptr<ConvertersTuple>;
    Converters converters;

    ArgsConverter(Conv<Args>... convs)
        : converters(panda::make_shared<ConvertersTuple>(convs...))
    {}

    ArgsConverter(const ArgsConverter& oth)
        : cv(oth.cv), converters(oth.converters)
    {}

    ArgsConverter carry(SvIntrPtr cv) {
        ArgsConverter res(*this);
        res.cv = cv;
        return res;
    }

    void operator ()(Args... args) {
        std::vector<SV*> sv_args;
        push(sv_args, args...);
        xs::call_sub_void(aTHX_ cv.get<CV>(), sv_args.data(), sv_args.size());
    }

    bool operator ==(const ArgsConverter& o) const {
        SvIntrPtr oth = o.cv;
        return cv.get<CV>() == oth.get<CV>();
    }

    template <size_t pos = 0>
    void push(std::vector<SV*>&) {}

    template <size_t pos = 0, typename First, typename... Others>
    void push(std::vector<SV*>& vec, First f, Others... oths) {
        vec.push_back(std::get<pos>(*converters)(f));
        push<pos+1>(vec, oths...);
    }
};

template <typename Ret, typename... Args>
struct XSCallbackDispatcherImpl : public XSCallbackDispatcher {

    using Dispatcher = CallbackDispatcher<Ret, Args...>;
    using Callback = typename Dispatcher::SimpleCallback;
    using Converter = ArgsConverter<Args...>;
    using Parent = shared_ptr<::panda::RefCounted>;

    XSCallbackDispatcherImpl(Dispatcher& dispatcher, Converter converter, Parent parent)
        : dispatcher(dispatcher)
        , converter(converter)
        , parent(parent)
    {}


    virtual void add(SvIntrPtr cv) override {
        dispatcher.add(converter.carry(cv));
    }

    virtual void remove(SvIntrPtr cv) override {
        dispatcher.remove(Callback(converter.carry(cv)));
    }

    Dispatcher& dispatcher;
    ArgsConverter<Args...> converter;
    Parent parent;
};

}//anonymous

template <typename... Args>
XSCallbackDispatcher* make_xs_wrapper(CallbackDispatcher<void, Args...>& dispatcher,
                                      shared_ptr<RefCounted> parent,
                                      function<SV*(Args&)>... convs)
{
    ArgsConverter<Args...> converter(convs...);
    return new XSCallbackDispatcherImpl<void, Args...>(dispatcher, converter, parent);
}
}//xs
