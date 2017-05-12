#!/usr/bin/perl
use strict;
use warnings;
use Socialtext::Resting::Getopt qw/get_rester/;
use Socialtext::Resting::RSS;

my @feeds = (
    { workspace => 'stdev' },
    { workspace => 'open' },
    { server => 'http://www.perlfoundation.org', workspace => 'perl5' },
);

for my $f (@feeds) {
    my $r = get_rester();

    for my $method (keys %$f) {
        $r->$method($f->{$method});
    }

    my %opts = (
        output_dir => '/home/lukec/.nlw/root/webplugin/diffrss/static',
        rester => $r,
    );
    Socialtext::Resting::RSS->new( rester => $r, %opts)->generate;
}
