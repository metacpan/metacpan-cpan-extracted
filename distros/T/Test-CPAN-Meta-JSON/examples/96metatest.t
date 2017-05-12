#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing META.json files" if $@;

plan 'no_plan';

my $meta = meta_spec_ok(undef,undef,@_);

use MyDistro;                           # enter your module name here
my $version = $MyDistro::VERSION;       # enter your module name here

is($meta->{version},$version,
    'META.json distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version},$version,
            "META.json entry [$mod] version matches distribution version");

        eval "require $mod";
        my $VERSION = '$' . $mod . '::VERSION';
        my $v = eval "$VERSION";
        is($meta->{provides}{$mod}{version},$v,
            "META.json entry [$mod] version matches module version");

        isnt($meta->{provides}{$mod}{version},0);
    }
}
