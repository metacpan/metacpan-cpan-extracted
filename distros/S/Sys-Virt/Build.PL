#!/usr/bin/perl
#
# Copyright (C) 2009-2018 Red Hat, Inc.
# Copyright (C) 2009 Daniel P. Berrange
#
# This program is free software; You can redistribute it and/or modify
# it under the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any
# later version
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions
#

use Module::Build;

use strict;
use warnings;

my $libvirtver = "5.5.0";
my $stat = system "pkg-config --atleast-version=$libvirtver libvirt";
die "cannot run pkg-config to check libvirt version" if $stat == -1;
die "libvirt >= $libvirtver is required\n" unless $stat == 0;

my $LIBVIRT_LIBS = `pkg-config --libs libvirt`;
my $LIBVIRT_CFLAGS = `pkg-config --cflags libvirt`;

my $GCC_CFLAGS = "";
if ($ENV{TEST_MAINTAINER}) {
    $GCC_CFLAGS = qq(
 -W -Waddress -Wall -Warray-bounds -Wattributes
 -Wbad-function-cast -Wbuiltin-macro-redefined -Wcast-align
 -Wchar-subscripts -Wclobbered -Wcomment -Wcomments
 -Wcoverage-mismatch -Wcpp -Wdeprecated-declarations
 -Wdisabled-optimization -Wdiv-by-zero -Wdouble-promotion
 -Wempty-body -Wendif-labels -Wextra -Wformat-contains-nul
 -Wformat-extra-args -Wformat-security -Wformat-y2k
 -Wformat-zero-length -Wformat=2 -Wfree-nonheap-object
 -Wignored-qualifiers -Wimplicit -Wimplicit-function-declaration
 -Wimplicit-int -Winit-self -Wint-to-pointer-cast
 -Winvalid-memory-model -Winvalid-pch -Wjump-misses-init
 -Wlogical-op -Wmain -Wmaybe-uninitialized -Wmissing-braces
 -Wmissing-declarations -Wmissing-field-initializers
 -Wmissing-format-attribute -Wmissing-include-dirs
 -Wmissing-noreturn -Wmissing-parameter-type
 -Wmultichar -Wnarrowing -Wnonnull
 -Wnormalized=nfc -Wold-style-declaration -Wold-style-definition
 -Woverflow -Woverride-init -Wpacked-bitfield-compat -Wparentheses
 -Wpointer-arith -Wpointer-sign -Wpointer-to-int-cast -Wpragmas
 -Wreturn-type -Wsequence-point -Wno-shadow -Wstrict-aliasing
 -Wstrict-prototypes -Wsuggest-attribute=const
 -Wsuggest-attribute=noreturn -Wsuggest-attribute=pure -Wswitch
 -Wsync-nand -Wtrampolines -Wtrigraphs -Wtype-limits -Wuninitialized
 -Wunknown-pragmas -Wunused -Wunused-but-set-parameter
 -Wunused-but-set-variable -Wunused-function -Wunused-label
 -Wunused-local-typedefs -Wno-unused-parameter -Wunused-result
 -Wunused-value -Wunused-variable -Wvariadic-macros
 -Wvector-operation-performance -Wvolatile-register-var
 -Wwrite-strings -Wno-sign-compare -Wjump-misses-init
 -Wno-format-nonliteral -Wframe-larger-than=8192
 -Wno-suggest-attribute=pure -Wno-suggest-attribute=const
 -Wno-cast-function-type
	);
}

my $b = Module::Build->new(
    module_name => "Sys::Virt",
    license => 'gpl',
    configure_requires => {
	'Module::Build' => 0,
    },
    create_makefile_pl => 'small',
    dist_author => 'Daniel Berrange <dan@berrange.com>',
    dist_abstract => 'libvirt Perl API',
    requires => {
        'perl' => '5.8.0',
    },
    extra_compiler_flags => $GCC_CFLAGS . $LIBVIRT_CFLAGS,
    extra_linker_flags => $LIBVIRT_LIBS,
    build_requires => {
	'ExtUtils::CBuilder' => 0,
	'Sys::Hostname' => 0,
	'Test::CPAN::Changes' => 0,
	'Test::More' => 0,
        'Test::Pod' => '0',
	'Test::Pod::Coverage' => '0',
	'Time::HiRes' => 0,
	'XML::XPath' => 0,
	'XML::XPath::XMLParser' => 0,
    },
    script_files => [],
    meta_add => {
        resources => {
            license => "http://www.gnu.org/licenses/gpl.html",
            homepage =>  "http://libvirt.org/",
            repository => "https://libvirt.org/git/?p=libvirt-perl.git;a=summary",
            MailingList => "http://www.redhat.com/mailman/listinfo/libvir-list",
        },
    },
    PL_files => { 'perl-Sys-Virt.spec.PL' => 'perl-Sys-Virt.spec' },
    );
$b->create_build_script;
