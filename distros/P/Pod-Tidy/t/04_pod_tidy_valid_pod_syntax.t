#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: 04_pod_tidy_valid_pod_syntax.t,v 1.4 2005/10/03 01:15:56 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib ./t );

use Test::More tests => 4;

use Pod::Tidy;
use File::Temp qw( tempdir );
use Test::Pod::Tidy;

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    ok(Pod::Tidy::valid_pod_syntax($tmp_valid->filename), "check valid pod");
    is(Pod::Tidy::valid_pod_syntax($tmp_invalid->filename), undef, "check invalid pod");

}

is(Pod::Tidy::valid_pod_syntax(undef), undef, "file doesn't exist");

{
    my $dir = tempdir( CLEANUP => 1 );
    is(Pod::Tidy::valid_pod_syntax("$dir/foo"), undef, "file doesn't exist");
}
