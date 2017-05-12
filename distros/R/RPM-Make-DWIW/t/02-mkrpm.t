#!/usr/bin/perl -w

# $Header: /usr/local/cvsroot/apb/lib/RPM-Make-DWIW/t/02-mkrpm.t,v 1.1 2010-02-22 07:04:22 asher Exp $

use strict;

use Test::More tests => 4;

BEGIN { use_ok("RPM::Make::DWIW") }

{

my $spec = {
    tags => {
        Summary     => 'ACME DB client',
        Name        => 'unit_test02',
        Version     => '1.1',
        Release     => '9',
        License     => 'GPL',
        Group       => 'Applications/Database',
        #Source     => 'ftp://ftp.acme.com/acmedb_client-1.3.tar.gz',
        #URL        => 'http://www.acme.com/acmedb_client/',
        #Distribution => 'ACME',
        #Vendor     => 'ACME Software, Inc.',
        #Packager   => 'Adam Acme <aa@acme.com>',
    },
    description => 'Client libraries and binary for ACME DB',
    items => [
        # first set defaults for following items:
        {
            defaults => 1,
            type => 'file',
            mode => '0755',
            owner => 'root',
            group => 'wheel',
        },
        {
            src  => 't/data/x',
            dest => '/usr/bin/acme-client',
        },
        {
            src  => 't/data/y',
            dest => '/etc/acme-client.conf',
            mode => '0644',
        },
        {
            type => 'dir',
            dest => '/var/log/acme-client/transcripts',
            mode => '0777',
        },
    ],
    requirements => [
        {
            name        => 'libxml2',
            min_version => '2.6.0',
        },
    ],
    post    => 'echo post',
    postun  => 'echo postun',
    cleanup => 1,
};
    ok(RPM::Make::DWIW::write_rpm($spec), "write rpm");
    my $fn;
    ok($fn = RPM::Make::DWIW::get_rpm_filename(), "get filename");
    ok(-e $fn, "RPM exists");
    unlink($fn);
}

