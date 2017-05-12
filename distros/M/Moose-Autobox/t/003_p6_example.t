use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

require Moose::Autobox;

=pod

This comes from one of the examples in the Pugs distro.

=cut

{
    package Units::Bytes;
    use Moose::Role;
    use Moose::Autobox;

    sub bytes     { $_[0]                   }
    sub kilobytes { $_[0] * 1024            }
    sub megabytes { $_[0] * 1024->kilobytes }
    sub gigabytes { $_[0] * 1024->megabytes }
    sub terabytes { $_[0] * 1024->gigabytes }

    {
        no warnings 'once'; # << squelch the stupid "used only once, maybe typo" warnings
        *byte     = \&bytes;
        *kilobyte = \&kilobytes;
        *megabyte = \&megabytes;
        *gigabyte = \&gigabytes;
        *terabyte = \&terabytes;
    }
}

Moose::Autobox->mixin_additional_role(SCALAR => 'Units::Bytes');

sub testing_bytes {
    ::dies_ok { 10->bytes } '... cannot do the autoboxing lexically';
}

{
    use Moose::Autobox;

    is(5->bytes,     5,             '... got 5 bytes');
    is(5->kilobytes, 5120,          '... got 5 kilobytes');
    is(2->megabytes, 2097152,       '... got 2 megabytes');
    is(1->gigabyte,  1073741824,    '... got 1 gigabyte');
    is(2->terabytes, 2199023255552, '... got 2 terabyte');
    testing_bytes;
}

dies_ok { 5->bytes } '... no longer got 5 bytes';
