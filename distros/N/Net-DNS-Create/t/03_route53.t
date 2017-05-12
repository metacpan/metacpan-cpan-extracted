# -*- perl -*-

use warnings; use strict;
use Test::More tests => 1;

use File::Temp qw(tempfile tempdir);
use Net::DNS::Create qw(Route53), default_ttl => "1h";

use File::Path qw(remove_tree make_path);

do './t/example.com';
die $@ if $@;

my @test = Net::DNS::Create::Route53::_domain();

use Data::Dumper;

my $good = do './t/good/route53.pl';

sub sort_entries {
    map {
        +{
          name => $_->{name},
          entries => [
                      sort { $a->{type} cmp $b->{type} ||
                             $a->{name} cmp $b->{name} ||
                             ($a->{value} || $a->{records}->[0]) cmp ($b->{value} || $b->{records}->[0])
                           } @{$_->{entries}}
                     ]
         }
    } @_;
}

   @test = sort_entries(@test);
my @good = sort_entries(@$good);

use Test::Deep;
cmp_deeply([@test], [@good], "route53 internal struct is good");

# warn Dumper[$test[0]{entries}->[14]];
# warn Dumper[$good[0]{entries}->[14]];
# warn Dumper \@test; # The easiest way to update the output
