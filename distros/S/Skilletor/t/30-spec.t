#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( path );
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Spec qw( resolve_spec decode_uri_component normalize_name );

# t/data/spec-oracle.json: the reference's resolveSpec for every string literal of its own
# test/spec.test.ts and maint/spec-extra.json, with the probe below (maint/oracle-spec.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'spec-oracle.json' )->slurp_utf8 );

for my $case (@$oracle) {
  my $spec = $case->{spec};
  my @probed;
  my $probe = sub {
    my ( $url ) = @_;
    push @probed, $url;
    return { git => scalar( $url =~ /git/ ), tarball => scalar( $url =~ /tar|tgz|pkg/ ) };
  };
  my $result;
  my $err = error_of( sub { $result = resolve_spec( $spec, $probe ) } );
  my $label = js_stringify($spec);
  if ( exists $case->{error} ) {
    is( $err, $case->{error}, 'error for '.$label );
  }
  else {
    is( $err, undef, 'resolves '.$label ) or next;
    is_deeply( $result, { %{ $case->{result} } }, 'result for '.$label );
  }
  is_deeply( \@probed, $case->{probed}, 'probed for '.$label );
}

is( decode_uri_component('a%20b%C3%BC%2F'), "a b\x{fc}/", 'decodeURIComponent' );
ok( !defined decode_uri_component($_), 'URIError for '.$_ ) for qw( % %4 %zz %C3 %C3%28 %ED%A0%80 %C0%AF %F8%80%80%80 );
is( normalize_name('My.Repo.git'), 'my-repo', 'normalize_name' );

done_testing;
