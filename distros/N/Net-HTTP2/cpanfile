#!/usr/bin/perl

configure_requires 'ExtUtils::MakeMaker::CPANfile';

requires 'Net::SSLeay' => '1.90';
requires 'X::Tiny' => 0.22;
requires 'Protocol::HTTP2';
requires 'Scalar::Util';
requires 'URI::Split';
requires 'Promise::ES6' => 0.25;

on test => sub {
    requires 'Test::More';
    requires 'Test::FailWarnings';

    recommends 'AnyEvent';
};
