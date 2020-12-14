#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use utf8;
use open ":encoding(UTF-8)";
use Carp qw(croak);
use HTTP::Tiny;
use Module::Build;
use IO::File;
use Tie::File;
use URI;

my $builder = Module::Build->new(
    dist_name => "Mozilla-PublicSuffix",
    license => "MIT",
    dist_abstract => q(Get a domain name's public suffix via Mozilla's Public Suffix List),
    dist_author => q"Tom Hukins <tom@eborcom.com>",
    dist_version_from => "lib/Mozilla/PublicSuffix.pm",
    # Prerequisites inserted by DistZilla:
      'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.28',
    'Test::More' => '0',
    'perl' => '5.008'
  },
  'configure_requires' => {
    'HTTP::Tiny' => '0',
    'IO::File' => '0',
    'Module::Build' => '0.28',
    'Tie::File' => '0',
    'URI' => '0',
    'perl' => '5.008'
  },
  'requires' => {
    'Exporter' => '0',
    'URI' => '0',
    'perl' => '5.008'
  },
);

my $dat_file = "effective_tld_names.dat";
my $get_new_list = $builder->y_n(
    "Check for a new version of the Public Suffix List?", "N"
);
if ($get_new_list) {
    my $http = HTTP::Tiny->new( timeout => 6 );
    my $list_uri = URI->new(
        "https://publicsuffix.org/list/public_suffix_list.dat"
    );
    $list_uri->query_form({ raw => 1 });
    my %options = (
        headers => {
            "If-Modified-Since" => "Fri, 17 May 2013 00:00:00 UTC"
        }
    );
    my $response = $http->get($list_uri, \%options);
    if ( $response->{status} == 200 ) {
        IO::File->new($dat_file, "w")->print($response->{content});
    }
    elsif ( $response->{status} != 304 ) {
        croak "Unable to download public suffix list.";
    }
}

# Divide rules from list into sets:
my $rules = join " ", map {
    s/\s//g;
    if    ( s/^!// )        { $_ => "e" }  # exception rule
    elsif ( s/^\*\.// )     { $_ => "w" }  # wildcard rule
    elsif ( /^[\p{Word}]/ ) { $_ => "i" }  # identity rule
    else { () }
} IO::File->new($dat_file)->getlines;

tie my @pm, "Tie::File", "lib/Mozilla/PublicSuffix.pm";
for (@pm) { s/(my %rules = qw\()\)/$1$rules)/ and last }
untie @pm;

$builder->create_build_script;
