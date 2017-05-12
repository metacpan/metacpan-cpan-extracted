#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;
use Module::Build::Convert;

my $make = Module::Build::Convert->new;

my %makeargs = (NAME           => 'SCALAR',
                DISTNAME       => 'SCALAR',
                ABSTRACT       => 'SCALAR',
                AUTHOR         => 'SCALAR',
                VERSION        => 'SCALAR',
                VERSION_FROM   => 'SCALAR',
                PREREQ_PM      => 'HASH',
                PL_FILES       => 'HASH',
                PM             => 'HASH',
                MAN1PODS       => 'HASH',
                XS             => 'HASH',
                INC            => 'SCALAR',
                INSTALLDIRS    => 'SCALAR',
                DESTDIR        => 'SCALAR',
                CCFLAGS        => 'SCALAR',
                EXTRA_META     => 'SCALAR',
                SIGN           => 'SCALAR',
                LICENSE        => 'SCALAR',
                'clean.FILES'  => 'ARRAY');

my %resolve = (SCALAR => '',
               ARRAY  => [],
               HASH   => {});

while (my ($arg, $type) = each %makeargs) {
    $make->{make_args}{args}{$arg} = $resolve{$type};
}

$make->_get_data;
$make->_convert;

my %table = (module_name          => 'NAME',
             dist_name            => 'DISTNAME',
             dist_abstract        => 'ABSTRACT',
             dist_author          => 'AUTHOR',
             dist_version         => 'VERSION',
             dist_version_from    => 'VERSION_FROM',
             requires             => 'PREREQ_PM',
             PL_files             => 'PL_FILES',
             pm_files             => 'PM',
             pod_files            => 'MAN1PODS',
             xs_files             => 'XS',
             include_dirs         => 'INC',
             installdirs          => 'INSTALLDIRS',
             destdir              => 'DESTDIR',
             extra_compiler_flags => 'CCFLAGS',
             meta_add             => 'EXTRA_META',
             sign                 => 'SIGN',
             license              => 'LICENSE',
             create_readme        => '',
             create_makefile_pl   => '',
             '@add_to_cleanup'    => 'clean.FILES');

foreach (@{$make->{build_args}}) {
    my ($buildarg, $type) = each %$_;
    my $makearg = $table{$buildarg};

    my $testmsg = $table{$buildarg} 
      ? "$table{$buildarg} => $buildarg" 
      : "$buildarg is a default argument";

    is (exists $table{$buildarg}, 1, $testmsg);

    if (ref $type eq 'ARRAY' || ref $type eq 'HASH') {
        is (ref $type, $makeargs{$makearg}, "$buildarg is of type " . ref $type);
    } else {
        is (ref $type, '', "$buildarg is of type SCALAR");
    }
}
