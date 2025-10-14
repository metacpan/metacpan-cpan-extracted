#!perl

requires 'perl' => '5.26.0'; # combination of Future::AsyncAwait and signatures
requires 'Feature::Compat::Try';
requires 'Future';
requires 'Future::AsyncAwait';
requires 'Future::Queue';
requires 'IO::Async::Notifier';
requires 'IO::Async::Stream';
requires 'Log::Any';
requires 'Object::Pad' => '0.821';
requires 'Protocol::Sys::Virt' => '11.8.0';
requires 'Protocol::Sys::Virt::KeepAlive' => '11.8.0';
requires 'Protocol::Sys::Virt::Remote' => '11.8.0';
requires 'Protocol::Sys::Virt::Remote::XDR' => '11.8.0';
requires 'Protocol::Sys::Virt::UNIXSocket' => '11.8.0';
requires 'Protocol::Sys::Virt::URI' => '11.8.0';
requires 'Sublike::Extended' => '0.29';  # treat 'method' and 'sub' as extended keywords

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Carp::Always';
    requires 'Protocol::Sys::Virt::Devel' => '1.0.1';
    requires 'Test::Pod' => '1.0';
    requires 'Test::Pod::Coverage' => '1.10';
    requires 'Pod::ProjectDocs';
};

feature 'examples', 'Dependencies for examples' => sub {
    requires 'IO::Async::Loop';
};
