#!/usr/bin/perl -w

use strict;
use warnings;

package asd;

sub qwe {

    return 'zxc';
}

package main;

use Test::More tests => 2;

use Salvation::UpdateGvFLAGS ();

no strict 'refs';

my $imported_cv = ( eval { B::GVf_IMPORTED_CV() } || 0x80 );

my $o = B::svref_2object( \*asd::qwe );
my $old_flags = $o -> GvFLAGS();

Salvation::UpdateGvFLAGS::toggle_glob_flag_by_coderef( \&asd::qwe, $imported_cv );

is( $o -> GvFLAGS(), ( $old_flags ^ $imported_cv ), 'flags are changed' );
is( asd::qwe(), 'zxc', 'asd::qwe() call' );


exit 0;

__END__
