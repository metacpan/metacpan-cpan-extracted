#! /usr/bin/env perl

use strict;
use warnings;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use Test::More;
use Test::Deep;
use Data::Dumper;
use Tapper::Reports::API;

my @cmdlines = (
                # trailing spaces matter!
                '#! upload 552 /tmp/foo.bar application/octet-stream',
                '#! upload 552 /tmp/foo.bar application/octet-stream   ',
                '#!     upload      552      /tmp/foo.bar   application/octet-stream',
                '#!     upload      552      /tmp/foo.bar   application/octet-stream    ',
                '  #! upload 552 /tmp/foo.bar application/octet-stream',
                '  #! upload 552 /tmp/foo.bar application/octet-stream   ',
                '  #!     upload      552      /tmp/foo.bar   application/octet-stream',
                '  #!     upload      552      /tmp/foo.bar   application/octet-stream    ',
               );

my @cmdlines2 = (
                 # trailing spaces matter!
                 '#! upload 552 /tmp/foo.bar',
                 '#! upload 552 /tmp/foo.bar   ',
                 '#!     upload      552      /tmp/foo.bar',
                 '#!     upload      552      /tmp/foo.bar    ',
                 '  #! upload 552 /tmp/foo.bar',
                 '  #! upload 552 /tmp/foo.bar   ',
                 '  #!     upload      552      /tmp/foo.bar',
                 '  #!     upload      552      /tmp/foo.bar    ',
                );

plan tests => 4*@cmdlines + 4*@cmdlines2 + 1;

my $i = 0;
foreach my $cmdline (@cmdlines) {
        my ($cmd, $id, $file, $contenttype) = Tapper::Reports::API::_split_cmdline( $cmdline );

        is($cmd,         "upload",                   "cmd $i");
        is($id,          "552",                      "id $i");
        is($file,        "/tmp/foo.bar",             "file $i");
        is($contenttype, "application/octet-stream", "contenttype $i");

        $i++;
}

# -- same but without optional content type --

foreach my $cmdline (@cmdlines2) {
        my ($cmd, $id, $file, $contenttype) = Tapper::Reports::API::_split_cmdline( $cmdline );

        is($cmd,         "upload",                   "cmd $i");
        is($id,          "552",                      "id $i");
        is($file,        "/tmp/foo.bar",             "file $i");
        is($contenttype, undef,                      "contenttype $i");

        $i++;
}

my %args = Tapper::Reports::API::_parse_args( qw( debug=1 -affe=zomtec --foo=bar ) );
cmp_deeply(\%args, {
                    debug => 1,
                    affe  => "zomtec",
                    foo   => "bar",
                   }, "_parse_args" );


