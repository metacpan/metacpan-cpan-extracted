#!perl

requires 'perl' => '5.26.0'; # combination of Future::AsyncAwait and signatures
requires 'Feature::Compat::Try';
requires 'Future';
requires 'Future::AsyncAwait';
requires 'Future::IO';
requires 'Future::Selector';
requires 'Future::Queue';
requires 'Log::Any';
requires 'Object::Pad' => '0.821';
requires 'Protocol::Sys::Virt' => '12.5.0';
requires 'Protocol::Sys::Virt::KeepAlive' => '12.5.0';
requires 'Protocol::Sys::Virt::Remote' => '12.5.0';
requires 'Protocol::Sys::Virt::Remote::XDR' => '12.5.0';
requires 'Protocol::Sys::Virt::TypedParams' => '12.5.0';
requires 'Protocol::Sys::Virt::UNIXSocket' => '12.5.0';
requires 'Protocol::Sys::Virt::URI' => '12.5.0';
requires 'Sublike::Extended' => '0.29';  # treat 'method' and 'sub' as extended keywords

recommends 'Future::IO::Resolver';

on configure => sub {
    requires 'ExtUtils::MakeMaker' => '7.78';
};

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Carp::Always';
    # requires 'Log::Any::Adapter::TAP';
    requires 'Protocol::Sys::Virt::Devel' => '1.0.1';
    requires 'Test::Pod' => '1.0';
    requires 'Test::Pod::Coverage' => '1.10';
    requires 'Pod::ProjectDocs';
};

feature 'examples', 'Dependencies for examples' => sub {
    requires 'IO::Async::Loop';
};
