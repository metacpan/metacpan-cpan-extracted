#pragma once

#include <panda/CallbackDispatcher.h>
#include <panda/lib/integer_sequence.h>
#include <xs/xs.h>
#include <vector>

namespace xs {
namespace lib {

using panda::CallbackDispatcher;
using panda::function;

struct NativeCallbackDispatcher {
    virtual ~NativeCallbackDispatcher() {};

    virtual void add(SvIntrPtr cv)= 0;
    virtual void remove(SvIntrPtr cv) = 0;
    virtual void call(SV** args, size_t items) = 0;

    template <typename... Args>
    static NativeCallbackDispatcher* create(CallbackDispatcher<void, Args...>& dispatcher,
                                     std::tuple<function<SV*(Args)>, function<Args(SV*)>>... convs);

    template <typename T>
    static T no_converter(SV*) {
        throw std::logic_error("converter from SV* to Args has not been set");
    }

    template <typename... Args>
    static NativeCallbackDispatcher* create(CallbackDispatcher<void, Args...>& dispatcher,
                                     std::tuple<function<SV*(Args)>, nullptr_t>... convs) {
        return create(dispatcher, std::make_tuple(std::get<0>(convs), function<Args(SV*)>(&no_converter<Args>))...);
    }

};


namespace {

using xs::my_perl;

template <typename... Args>
struct ArgsConverter {
    template <typename T>
    using Conv = std::tuple<function<SV*(T&)>, function<T(SV*)>>;

    SvIntrPtr cv;
    using Converters = std::tuple<Conv<Args>...>;
    Converters converters;

    ArgsConverter(Conv<Args>... convs) : converters(convs...) {}

    ArgsConverter(const ArgsConverter& oth)
        : cv(oth.cv), converters(oth.converters)
    {}

    ArgsConverter carry(SvIntrPtr cv) {
        ArgsConverter res(*this);
        res.cv = cv;
        return res;
    }

    void operator ()(Args... args) {
        SV* sv_args[sizeof...(Args)];
        push(sv_args, args...);
        xs::call_sub_void(aTHX_ cv.get<CV>(), sv_args, sizeof...(Args));
    }

    bool operator ==(const ArgsConverter& oth) const {
        SvIntrPtr ocv = oth.cv;
        return cv.get<CV>() == ocv.get<CV>();
    }

    template <size_t pos = 0>
    void push(SV**) {}

    template <size_t pos = 0, typename First, typename... Others>
    void push(SV** dest, First f, Others... oths) {
        dest[pos] = std::get<0>(std::get<pos>(converters))(f);
        push<pos+1>(dest, oths...);
    }
};

template <typename Ret, typename... Args>
struct NativeCallbackDispatcherImpl : public NativeCallbackDispatcher {

    using Dispatcher = CallbackDispatcher<Ret, Args...>;
    using Callback = typename Dispatcher::SimpleCallback;
    using Converter = ArgsConverter<Args...>;

    NativeCallbackDispatcherImpl(Dispatcher& dispatcher, Converter converter)
        : dispatcher(dispatcher), converter(converter)
    {}

    void add(SvIntrPtr cv) override {
        dispatcher.add(converter.carry(cv));
    }

    void remove(SvIntrPtr cv) override {
        dispatcher.remove(Callback(converter.carry(cv)));
    }

    void call(SV** sv_args, size_t items) override {
        if (items < sizeof...(Args)) croak("not enough arguments for dispatcher call()");
        call_impl(sv_args, std::make_integer_sequence<size_t, sizeof...(Args)>());
    }

    template <size_t... Inds>
    void call_impl (SV** args, std::integer_sequence<size_t, Inds...>) {
        dispatcher(std::get<1>(std::get<Inds>(converter.converters))(args[Inds])...);
    }

    Dispatcher& dispatcher;
    ArgsConverter<Args...> converter;
};

}//anonymous

template <typename... Args>
NativeCallbackDispatcher* NativeCallbackDispatcher::create(CallbackDispatcher<void, Args...>& dispatcher,
                                                           std::tuple<function<SV*(Args)>, function<Args(SV*)>>... convs)
{
    ArgsConverter<Args...> converter(convs...);
    return new NativeCallbackDispatcherImpl<void, Args...>(dispatcher, converter);
}

}//lib
}//xs

