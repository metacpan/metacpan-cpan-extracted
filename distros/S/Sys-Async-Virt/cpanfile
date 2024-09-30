#!perl

requires 'perl' => '5.26.0'; # combination of Future::AsyncAwait and signatures
requires 'Feature::Compat::Try';
requires 'Future::AsyncAwait';
requires 'Future::Queue';
requires 'IO::Async::Notifier';
requires 'Log::Any';
requires 'Protocol::Sys::Virt' => '10.3.12';
requires 'Sublike::Extended';

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Carp::Always';
    requires 'Protocol::Sys::Virt::Devel' => '0.0.5';
    requires 'Test::Pod' => '1.0';
    requires 'Test::Pod::Coverage' => '1.10';
    requires 'Pod::ProjectDocs';
};

feature 'examples', 'Dependencies for examples' => sub {
    requires 'Feature::Compat::Try';
    requires 'IO::Async::Loop';
};
