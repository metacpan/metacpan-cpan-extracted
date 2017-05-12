use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MooseX::AttributeShortcuts ();

{ package TestClass; }

my $dies = exception { MooseX::AttributeShortcuts->init_meta(for_class => 'foo') };

like
    $dies,
    qr/Class foo has no metaclass!/,
    'init_meta() dies on no-metaclass',
    ;

done_testing;
