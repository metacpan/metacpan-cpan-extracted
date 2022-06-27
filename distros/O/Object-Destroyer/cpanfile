use strict;
use warnings;

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'runtime' => sub {
    requires 'perl' => '5.006';
    requires 'strict';
    requires 'warnings';
    requires 'Carp';
    suggests 'Scalar::Util';
};

on 'test' => sub {
    requires 'Test::More' => '0.88';
};