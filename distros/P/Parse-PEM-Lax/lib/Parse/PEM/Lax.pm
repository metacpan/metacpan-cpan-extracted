package Parse::PEM::Lax;

use 5.010000;
use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.01';

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub from_string {
  my ($class, $data) = @_;
  my $self = bless { sections => [] }, $class;

  my $pem_section = qr#(
    (-{5}BEGIN\s+([^\n]*?)-{5})
    ([^-]*)
    (-{5}END\s+([^\n]*?)-{5})
  )#x;

  while ($data =~ /$pem_section/g) {
    my ($block, $head, $label1, $body, $tail, $label2) =
      ($1, $2, $3, $4, $5, $6);
    $body =~ s/\s+//g;
    $body =~ s/(.{0,76})/$1\n/g;
    $body =~ s/\s+$//;
    push @{ $self->{sections} },
      sprintf "%s\n%s\n%s\n", $head, $body, $tail;
  }

  return $self;
}

sub extract_sections {
  my ($self) = @_;
  return @{ $self->{sections} };
}

1;

__END__

=head1 NAME

Parse::PEM::Lax - Extract normalised sections from PEM files

=head1 SYNOPSIS

  use Parse::PEM::Lax;
  my $pem = Parse::PEM::Lax->from_string($string);
  my @sections = $pem->extract_sections;
  
=head1 DESCRIPTION

This module provides a lax parser for PEM files containing one or
more X.509 certificates or other data.

=head1 METHODS

=over

=item from_string($data)

Creates a 

=item extract_sections

Returns a list of normlised PEM-encoded blocks found in the input.

=back

=head1 EXPORTS

Nothing by default.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2016 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
