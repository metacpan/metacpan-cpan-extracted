#!/usr/bin/perl -w

# $Id$

#Courtesy of Ovid
#Ref: http://use.perl.org/~Ovid/journal/37797

use strict;
use warnings;

use File::Find;
use File::Spec;

use lib 'lib';
use Test::More;

BEGIN {
    my $DIR = 'lib/';

    sub to_module($) {
        my $file = shift;
        $file =~ s{\.pm$}{};
        $file =~ s{\\}{/}g;    # to make win32 happy
        $file =~ s/^$DIR//;
        return join '::' => grep _ => File::Spec->splitdir($file);
    }

    my @modules;

    find({
            no_chdir => 1,
            wanted   => sub {
                push @modules => map { to_module $_ } $File::Find::name
                        if /\.pm$/;
            },
        }, $DIR
    );

    plan tests => scalar @modules;

    for my $module (@modules) {
        use_ok $module or BAIL_OUT("Could not use $module");
    }
}
