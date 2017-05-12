#!/usr/bin/perl -w
use strict;

use IO::File;
use LWP::UserAgent;
use Parse::CPAN::Distributions;
use Test::More  tests => 8;

use Parse::CPAN::Distributions;
my $version = $Parse::CPAN::Distributions::VERSION;

my $fh = IO::File->new('Changes','r')   or plan skip_all => "Cannot open Changes file";
while(<$fh>) {
    next    unless(m!^\d!);
    next    if(m!^$version!);
    ($version) = $_ =~ /^([\d.]+)/;
    last;
}
$fh->close;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
 
my $response = $ua->get('http://www.cpan.org');

SKIP: {
    skip "No connection", 8 unless($response->is_success);
    {
        my $obj = Parse::CPAN::Distributions->new(file => '');
        SKIP: {
            skip "Unable to retrieve file: $Parse::CPAN::Distributions::ERROR", 2 unless($obj);
            isa_ok($obj,'Parse::CPAN::Distributions');
            is($obj->author_of('Parse-CPAN-Distributions',$version),'BARBIE');
        }
    }
    {
        my $obj = Parse::CPAN::Distributions->new();
        SKIP: {
            skip "Unable to retrieve file: $Parse::CPAN::Distributions::ERROR", 2 unless($obj);
            isa_ok($obj,'Parse::CPAN::Distributions');
            is($obj->author_of('Parse-CPAN-Distributions',$version),'BARBIE');
        }
    }
    {
        my $obj = Parse::CPAN::Distributions->new(file => 't/samples/nofile');
        SKIP: {
            skip "Unable to retrieve file: $Parse::CPAN::Distributions::ERROR", 2 unless($obj);
            isa_ok($obj,'Parse::CPAN::Distributions');
            is($obj->author_of('Parse-CPAN-Distributions',$version),'BARBIE');
        }
    }

    {
        my $obj = Parse::CPAN::Distributions->new();
        SKIP: {
            skip "Unable to retrieve file: $Parse::CPAN::Distributions::ERROR", 2 unless($obj);
            isa_ok($obj,'Parse::CPAN::Distributions');
            is($obj->author_of('Parse-CPAN-Distributions','0.01'),undef,'no longer on CPAN');
        }
    }
}
