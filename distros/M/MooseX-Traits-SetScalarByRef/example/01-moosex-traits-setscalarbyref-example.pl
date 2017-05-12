#!perl

use 5.010;
use strict;
use warnings;
use lib '../lib'; # omit if MooseX::Traits::SetScalarByRef is installed
use MooseX::Traits::SetScalarByRef;
use Scalar::Util qw(refaddr);

{
    package Local::Example;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'TkRef', as 'ScalarRef';
    coerce 'TkRef', from 'Str', via { my $r = $_; return \$r };

    has _some_val => (
        traits   => [ 'MooseX::Traits::SetScalarByRef' ],
        isa      => 'TkRef',
        init_arg => 'some_val',
        default  => 'default value',
        handles  => 1,
    );
}

my $eg = Local::Example->new;
say refaddr($eg->some_val);

$eg->some_val("new string");
say refaddr($eg->some_val), " - should not have changed";

say ${ $eg->some_val };
exit(0);