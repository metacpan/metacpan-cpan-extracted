#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Most;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing META.json files" if $@;

plan 'no_plan';

my $meta = meta_spec_ok(undef,undef,@_);

use MooseX::PDF;
my $version = $MooseX::PDF::VERSION;

is($meta->{version},$version,
    'META.json distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version},$version,
            "META.json entry [$mod] version matches");
    }
}
