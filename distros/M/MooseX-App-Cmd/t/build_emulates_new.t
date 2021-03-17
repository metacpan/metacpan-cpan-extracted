use strict;
use warnings;

use Test::More tests => 1;
{

    package Foo;
    use base 'App::Cmd';

    package Bar;
    use Moose;
    extends 'MooseX::App::Cmd';

}

my @attrs = qw(arg0 command full_arg0 show_version);
my $foo; @{$foo}{@attrs} = @{ Foo->new }{@attrs};
my $bar; @{$bar}{@attrs} = @{ Bar->new }{@attrs};

is_deeply( $bar, $foo, 'Internal hashes match' );
