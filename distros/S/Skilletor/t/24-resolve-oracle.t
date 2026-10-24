#!/usr/bin/env perl
# The YAML subset, bundle files, patterns and catalog scans against the reference: every case of
# t/data/resolve-oracle.json (maint/oracle-resolve.mjs) – values, error messages, item errors.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest ();

use Path::Tiny qw( path tempdir );
use Scalar::Util qw( blessed );
use Skilletor::Bundles qw( expand_bundle matches_pattern parse_bundle same_identity );
use Skilletor::Catalog;
use Skilletor::FSUtil qw( encode_text read_text );
use Skilletor::Frontmatter qw( is_yaml_float parse_yaml_document split_frontmatter );
use Skilletor::JSON qw( js_parse js_stringify js_type );

my $oracle = js_parse( read_text("$FindBin::Bin/data/resolve-oracle.json") );

# YAML values as the oracle writes them: a float as { "$float": value }.
sub plain {
  my ( $v ) = @_;
  return { '$float' => $v->value } if is_yaml_float($v);
  return [ map { plain($_) } @$v ] if ref $v eq 'ARRAY';
  return Skilletor::JSON::js_ordered( map { ( $_ => plain( $v->{$_} ) ) } keys %$v ) if ref $v eq 'HASH' && !blessed $v;
  return $v;
}

# Every object's keys sorted, arrays kept: JSON text to compare (key order is no claim here).
sub canon {
  my ( $v ) = @_;
  my $t = js_type($v);
  return [ map { canon($_) } @$v ] if $t eq 'array';
  return { map { ( $_ => canon( $v->{$_} ) ) } keys %$v } if $t eq 'object' && !is_yaml_float($v);
  return $v;
}

sub same {
  my ( $got, $want, $name ) = @_;
  is( js_stringify( canon($got) ), js_stringify( canon($want) ), $name );
}

# { result } or { error, class } as the oracle records an attempt; class: the reference's name.
sub attempt {
  my ( $code, %class_of ) = @_;
  my $r;
  return { result => $r } if eval { $r = $code->(); 1 };
  my $err = $@;
  my ($class) = grep { blessed $err && $err->isa( $class_of{$_} ) } sort keys %class_of;
  return { error => ( blessed $err && $err->can('message') ? $err->message : "$err" ), class => $class // 'Error' };
}

sub label { my $t = js_stringify( $_[0] ); return length $t > 60 ? substr( $t, 0, 57 ).'...' : $t }

subtest 'parse_yaml_document' => sub {
  for my $case ( @{ $oracle->{yaml} } ) {
    my $got = attempt( sub { plain( parse_yaml_document( $case->{text} ) ) }, FrontmatterError => 'Skilletor::Error::Frontmatter' );
    my %want = map { ( $_ => $case->{$_} ) } grep { $_ ne 'text' } keys %$case;
    same( $got, \%want, label( $case->{text} ) );
  }
};

subtest 'split_frontmatter' => sub {
  for my $case ( @{ $oracle->{frontmatter} } ) {
    my $got = attempt( sub { split_frontmatter( $case->{text} ) }, FrontmatterError => 'Skilletor::Error::Frontmatter' );
    $got = $got->{result} ? { data => plain( $got->{result}{data} ), body => $got->{result}{body} } : $got;
    my %want = map { ( $_ => $case->{$_} ) } grep { $_ ne 'text' } keys %$case;
    same( $got, \%want, label( $case->{text} ) );
  }
};

subtest 'parse_bundle' => sub {
  for my $case ( @{ $oracle->{bundles} } ) {
    my $got = attempt( sub { parse_bundle( $case->{text} ) }, BundleError => 'Skilletor::Error::Bundle' );
    my %want = map { ( $_ => $case->{$_} ) } grep { $_ ne 'text' } keys %$case;
    same( $got, \%want, label( $case->{text} ) );
  }
};

subtest 'matches_pattern and same_identity' => sub {
  for my $c ( @{ $oracle->{patterns} } ) {
    is( matches_pattern( $c->{pattern}, $c->{name} ) ? 1 : 0, $c->{match} ? 1 : 0, label( [ $c->{pattern}, $c->{name} ] ) );
  }
  for my $c ( @{ $oracle->{identities} } ) {
    is( same_identity( $c->{a}, $c->{b} ) ? 1 : 0, $c->{same} ? 1 : 0, label( [ $c->{a}, $c->{b} ] ) );
  }
};

# A tree of t/data/catalog-trees.json under $root.
sub build {
  my ( $root, $tree ) = @_;
  my $files = $tree->{files} // {};
  for my $rel ( keys %$files ) {
    my $p = path( encode_text("$root/$rel") );
    $p->parent->mkpath;
    $p->spew_raw( encode_text( $files->{$rel} ) );
  }
  my $modes = $tree->{modes} // {};
  chmod $modes->{$_}, encode_text("$root/$_") for keys %$modes;
  my $links = $tree->{symlinks} // {};
  for my $rel ( keys %$links ) {
    path("$root/$rel")->parent->mkpath;
    symlink $links->{$rel}, "$root/$rel" or die "symlink $rel: $!";
  }
}

subtest 'catalog scans and bundle expansion' => sub {
  my $base = tempdir;
  my $root = $base->realpath;
  my %tree = map { ( $_->{name} => $_ ) } @{ js_parse( read_text("$FindBin::Bin/data/catalog-trees.json") ) };
  for my $case ( @{ $oracle->{catalogs} } ) {
    my $dir = "$root/$case->{name}";
    path($dir)->mkpath;
    build( $dir, $tree{ $case->{name} } );
    for my $s ( @{ $case->{scans} } ) {
      my $what = $case->{name}.( defined $s->{paths} ? ' path '.js_stringify( $s->{paths} ) : '' );
      my $got = attempt( sub { Skilletor::Catalog->scan( $dir, $s->{paths} ) }, CatalogError => 'Skilletor::Error::Catalog' );
      if ( $got->{class} && $got->{class} eq 'CatalogError' && ( $s->{class} // '' ) eq 'Error' ) {
        $got->{class} = 'Error';    # a Node fs error: a Skilletor::Error::Catalog here, the same message
      }
      my $cat = $got->{result};
      my $text = js_stringify( { %$got, ( $cat ? ( result => { %$cat, bundles => [ map { +{ %$_ } } @{ $cat->{bundles} } ] } ) : () ) } );
      $text =~ s/\Q$dir\E/\${DIR}/g;
      my %want = map { ( $_ => $s->{$_} ) } grep { $_ ne 'paths' && $_ ne 'expand' } keys %$s;
      same( js_parse($text), \%want, $what );
      next unless $s->{expand};
      for my $name ( sort keys %{ $s->{expand} } ) {
        my $x = attempt( sub { expand_bundle( $cat, $name ) }, BundleError => 'Skilletor::Error::Bundle' );
        ( my $t = js_stringify($x) ) =~ s/\Q$dir\E/\${DIR}/g;
        same( js_parse($t), $s->{expand}{$name}, "$what: expand $name" );
      }
    }
  }
};

done_testing;
