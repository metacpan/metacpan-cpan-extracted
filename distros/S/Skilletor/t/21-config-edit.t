#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( path tempdir );
use Scalar::Util qw( reftype );
use Skilletor::Config;
use Skilletor::JSON qw( js_parse js_stringify );

# t/data/config-edit-oracle.json: the reference's edit operations, one after another on one
# file, with each return value and the file's bytes after it (maint/oracle-config-edit.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'config-edit-oracle.json' )->slurp_utf8 );

my %METHOD = (
  addSource            => 'add_source',
  removeSource         => 'remove_source',
  sourceEntry          => 'source_entry',
  addInstallEntry      => 'add_install_entry',
  findInstallEntries   => 'find_install_entries',
  removeInstallEntries => 'remove_install_entries',
  findWildcardEntries  => 'find_wildcard_entries',
  bundleEntries        => 'bundle_entries',
  addBundleEntry       => 'add_bundle_entry',
  removeBundleEntries  => 'remove_bundle_entries',
);

for my $run ( @$oracle ) {
  subtest $run->{name} => sub {
    my $dir  = tempdir;
    my $file = $dir->child('skilletor.json');
    $file->spew_utf8( $run->{start} ) if defined $run->{start};
    my @steps = @{ $run->{steps} };
    for my $i ( 0 .. $#steps ) {
      my $step = $steps[$i];
      my ( $op, @args ) = @{ $run->{steps}[$i]{op} };
      my $method = $METHOD{$op} or die 'no method for '.$op;
      my $result;
      my $err = error_of( sub { $result = Skilletor::Config->$method( "$file", @args ) } );
      my $label = $op.' '.js_stringify( \@args );
      if ( exists $step->{error} ) {
        ( my $want = $step->{error} ) =~ s/<FILE>/$file/g;
        is( $err, $want, $label.': same error' );
      }
      else {
        is( $err, undef, $label.': no error' );
        # Return values: undef for the void operations, compared as the reference's JSON.
        $result = undef if $op =~ /\A(?:add|removeSource)/;
        is_deeply( js_parse( js_stringify($result) ), js_parse( js_stringify( $step->{result} ) ), $label.': same result' );
      }
      is( -e $file ? $file->slurp_utf8 : undef, $step->{file}, $label.': same bytes' );
    }
  };
}

done_testing;
