#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: 03_pod_tidy_backup_file.t,v 1.3 2005/10/02 22:22:06 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib );

use Test::More tests => 3;

use Pod::Tidy;
use File::Temp qw( tempdir );

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp = File::Temp->new( DIR => $dir );

    Pod::Tidy::backup_file($tmp->filename);

    ok(-e $tmp->filename . $Pod::Tidy::BACKUP_POSTFIX, "backup file exists");
}

{
    is(Pod::Tidy::backup_file(undef), undef, "file doesn't exist");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    is(Pod::Tidy::backup_file("$dir/foo"), undef, "file doesn't exist");
}
