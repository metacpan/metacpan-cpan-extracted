#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;

use File::Spec;

use Module::PluginFinder;

sub write_module
{
   my ( $filename, $code ) = @_;

   open( my $modh, ">", $filename ) or die "Cannot write $filename - $!";

   print $modh $code;
}

my $f = Module::PluginFinder->new(
   search_path => 't::lib',
   typevar     => 'SHAPE',
);

is_deeply( [ sort $f->modules ],
           [qw( t::lib::Black t::lib::Blue t::lib::Green t::lib::Red t::lib::Yellow )],
           '$f->modules' );

my $module = File::Spec->catfile( qw( t lib Purple.pm ) );

END { defined $module and -f $module and unlink $module; }

SKIP: { # Don't indent because this will be the entire rest of the file

eval { write_module $module, <<'EOF';
package t::lib::Purple;

our $SHAPE = "triangle";

1;
EOF
} or do { my $reason = "$@"; chomp $reason; skip $reason, 6 };

is_deeply( [ sort $f->modules ],
           [qw( t::lib::Black t::lib::Blue t::lib::Green t::lib::Red t::lib::Yellow )],
           '$f->modules after write file' );

is( $f->find_module( "triangle" ),
    undef,
    '$f->find_module' );

$f->rescan;

is_deeply( [ sort $f->modules ],
           [qw( t::lib::Black t::lib::Blue t::lib::Green t::lib::Purple t::lib::Red t::lib::Yellow )],
           '$f->modules after rescan' );

is( $f->find_module( "triangle" ),
    "t::lib::Purple",
    '$f->find_module after rescan' );

unlink $module;

$f->rescan;

is_deeply( [ sort $f->modules ],
           [qw( t::lib::Black t::lib::Blue t::lib::Green t::lib::Red t::lib::Yellow )],
           '$f->modules after unlink' );

is( $f->find_module( "triangle" ),
    undef,
    '$f->find_module after unlink' );

} # End of SKIP block
