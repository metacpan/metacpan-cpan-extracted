#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;

my @lines = split /\n/, <<__lines__;
              a_sis site ABCDEFG expired (29 May 2008)
               cifs site HIJKLMN
            cluster OPQRSTU
__lines__

my $license	= NetApp::Filer->_parse_license( $lines[0] );

ok( $license->{service} eq 'a_sis',
    "Parsed 1st service correctly" );
ok( $license->{type} eq 'site',
    "Parsed 1st type correctly" );
ok( $license->{code} eq 'ABCDEFG',
    "Parsed 1st code correctly" );
ok( $license->{expired} eq '29 May 2008',
    "Parsed 1st expiration data correctly" );

$license	= NetApp::Filer->_parse_license( $lines[1] );

ok( $license->{service} eq 'cifs',
    "Parsed 2nd service correctly" );
ok( $license->{type} eq 'site',
    "Parsed 2nd type correctly" );
ok( $license->{code} eq 'HIJKLMN',
    "Parsed 2nd code correctly" );
ok( ! $license->{expired},
    "Parsed 2nd expiration data correctly" );

$license	= NetApp::Filer->_parse_license( $lines[2] );

ok( $license->{service} eq 'cluster',
    "Parsed 3rd service correctly" );
ok( $license->{type} eq 'node',
    "Parsed 3rd type correctly" );
ok( $license->{code} eq 'OPQRSTU',
    "Parsed 3rd code correctly" );
ok( ! $license->{expired},
    "Parsed 3rd expiration data correctly" );

@lines = split /\n/, <<__lines__;
admin.etc.refresh.rate       0          
auditlog.enable              on         (value might be overwritten in takeover)
__lines__

my $option	= NetApp::Filer->_parse_option( $lines[0] );

ok( $option->{name} eq 'admin.etc.refresh.rate',
    "Parsed 1st name correctly" );
ok( $option->{value} eq '0',
    "Parsed 1st value correctly" );

$option		= NetApp::Filer->_parse_option( $lines[1] );

ok( $option->{name} eq 'auditlog.enable',
    "Parsed 1st name correctly" );
ok( $option->{value} eq 'on',
    "Parsed 1st value correctly" );

my $version	= NetApp::Filer::Version->new({
    string	=> "NetApp Release 7.2.2: Sat Mar 24 20:38:59 PDT 2007",
});
isa_ok( $version,			'NetApp::Filer::Version' );
ok( $version->get_major == 7,		'version->get_major' );
ok( $version->get_minor == 2,		'version->get_minor' );
ok( $version->get_subminor == 2,	'version->get_subminor' );
ok( ! $version->get_patchlevel,		'version->get_patchlevel' );
ok( $version->get_date eq 'Sat Mar 24 20:38:59 PDT 2007',
    					'version->get_date' );

$version	= NetApp::Filer::Version->new({
    string	=> "NetApp Release 7.2.4L1: Wed Nov 21 00:49:33 PST 2007",
});
isa_ok( $version,			'NetApp::Filer::Version' );
ok( $version->get_major == 7,		'version->get_major' );
ok( $version->get_minor == 2,		'version->get_minor' );
ok( $version->get_subminor == 4,	'version->get_subminor' );
ok( $version->get_patchlevel == 1,	'version->get_patchlevel' );
ok( $version->get_date eq 'Wed Nov 21 00:49:33 PST 2007',
    					'version->get_date' );

$version	= NetApp::Filer::Version->new({
    string	=> "NetApp Release 7.2.5.1: Wed Jun 25 08:55:16 PDT 2008",
});
isa_ok( $version,			'NetApp::Filer::Version' );
ok( $version->get_major == 7,		'version->get_major' );
ok( $version->get_minor == 2,		'version->get_minor' );
ok( $version->get_subminor == 5,	'version->get_subminor' );
ok( $version->get_patchlevel == 1,	'version->get_patchlevel' );
ok( $version->get_date eq 'Wed Jun 25 08:55:16 PDT 2008',
    					'version->get_date' );

