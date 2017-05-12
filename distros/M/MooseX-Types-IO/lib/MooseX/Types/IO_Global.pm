package MooseX::Types::IO_Global;

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:FAYLAND';

use Moose::Util::TypeConstraints;
use MooseX::Types::IO 'IO';

my $global = subtype 'IO' => as IO;

$global->coercion(IO->coercion);

1;
