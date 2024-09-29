#!perl

requires 'perl' => '5.14.1';
requires 'Log::Any';
requires 'URI::Encode';

on configure => sub {
    requires 'ExtUtils::MakeMaker' => '7.32'; # correctly deals with toplevel README.pod
};

on test => sub {
    requires 'Test2::V0';
};

on develop => sub {
    requires 'Carp::Always';
    requires 'Protocol::Sys::Virt::Devel' => '0.0.4';
    requires 'XDR::Gen' => '0.0.5';
};

feature 'examples', 'Dependencies for examples in eg/' => sub {
    requires 'Carp::Always';
    requires 'IO::Async::Loop';
    requires 'IO::Async::Stream';
    requires 'Future::AsyncAwait';
};
