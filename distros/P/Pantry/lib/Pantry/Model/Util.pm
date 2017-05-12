use v5.14;
use warnings;

package Pantry::Model::Util;
# ABSTRACT: Pantry data model utility subroutines
our $VERSION = '0.012'; # VERSION

use Exporter qw/import/;
use Hash::Merge ();
our @EXPORT_OK = qw/dot_to_hash hash_to_dot merge_hash/;

sub dot_to_hash {
  my ($hash, $key, $value) = @_;

  my ($top_key, $rest) = split qr{(?<!\\)\.}, $key, 2;
  if ( $rest ) {
    my $new_hash = $hash->{$top_key} || {};
    dot_to_hash($new_hash, $rest, $value);
    $hash->{$top_key} = $new_hash;
  }
  else {
    # un-escape '\.'
    $key =~ s{\\\.}{.}g;
    $hash->{$key} = $value;
    return;
  }
}

sub hash_to_dot {
  my ($key, $value) = @_;
  if ( ref $value eq 'HASH' ) {
    my @pairs;
    for my $k ( keys %$value ) {
      my $v = $value->{$k};
      $k =~ s{\.}{\\.}g; # escape existing dots in key
      for my $item ( hash_to_dot($k, $v) ) {
        $item->[0] = "$key\.$item->[0]";
        push @pairs, $item;
      }
    }
    return @pairs;
  }
  else {
    return [$key, $value];
  }
}

sub merge_hash {
  my ($base, $override) = @_;
  my $merger = Hash::Merge->new( 'STORAGE_PRECEDENT' );
  return $merger->merge( $override, $base );
}

1;

__END__

=pod

=head1 NAME

Pantry::Model::Util - Pantry data model utility subroutines

=head1 VERSION

version 0.012

=head1 DESCRIPTION

Internal functions.  No user-serviceable parts

=for Pod::Coverage hash_to_dot dot_to_hash merge_hash

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
