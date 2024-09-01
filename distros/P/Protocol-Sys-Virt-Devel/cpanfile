#!perl

requires 'perl' => '5.20.0';
requires 'XDR::Parse' => '0.3.1';

on configure => sub {
    requires 'ExtUtils::MakeMaker' => '7.32'; # correctly deals with toplevel README.pod
};

on test => sub {
    requires 'Test2::V0';
};
