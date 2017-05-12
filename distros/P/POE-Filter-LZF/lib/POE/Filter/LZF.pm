package POE::Filter::LZF;
$POE::Filter::LZF::VERSION = '1.72';
#ABSTRACT: A POE filter wrapped around Compress::LZF

use strict;
use warnings;
use Carp;
use Compress::LZF qw(compress decompress);
use base qw(POE::Filter);

sub new {
  my $type = shift;
  croak "$type requires an even number of parameters" if @_ % 2;
  my $buffer = { @_ };
  $buffer->{ lc $_ } = delete $buffer->{ $_ } for keys %{ $buffer };
  $buffer->{BUFFER} = [];
  return bless $buffer, $type;
}

sub get {
  my ($self, $raw_lines) = @_;
  my $events = [];

  foreach my $raw_line (@$raw_lines) {
	if ( my $line = decompress( $raw_line ) ) {
		push @$events, $line;
	}
	else {
		warn "Couldn\'t decompress input\n";
	}
  }
  return $events;
}

sub get_one_start {
  my ($self, $raw_lines) = @_;
  push @{ $self->{BUFFER} }, $_ for @{ $raw_lines };
}

sub get_one {
  my $self = shift;
  my $events = [];

  if ( my $raw_line = shift ( @{ $self->{BUFFER} } ) ) {
	if ( my $line = decompress( $raw_line ) ) {
		push @$events, $line;
	}
	else {
		warn "Couldn\'t decompress input\n";
	}
  }
  return $events;
}

sub put {
  my ($self, $events) = @_;
  my $raw_lines = [];

  foreach my $event (@$events) {
	if ( my $line = compress( $event ) ) {
		push @$raw_lines, $line;
	}
	else {
		warn "Couldn\'t compress output\n";
	}
  }
  return $raw_lines;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  return bless $nself, ref $self;
}

qq[Compress Distress];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::LZF - A POE filter wrapped around Compress::LZF

=head1 VERSION

version 1.72

=head1 SYNOPSIS

    use POE::Filter::LZF;

    my $filter = POE::Filter::LZF->new();
    my $scalar = 'Blah Blah Blah';
    my $compressed_array   = $filter->put( [ $scalar ] );
    my $uncompressed_array = $filter->get( $compressed_array );

    use POE qw(Filter::Stackable Filter::Line Filter::LZF);

    my ($filter) = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::LZF->new(),
		   POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),

=head1 DESCRIPTION

POE::Filter::LZF provides a POE filter for performing compression/decompression using L<Compress::LZF>. It is
suitable for use with L<POE::Filter::Stackable>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::LZF object.

=back

=head1 METHODS

=over

=item C<get_one_start>

=item C<get_one>

=item C<get>

Takes an arrayref which is contains lines of compressed input. Returns an arrayref of decompressed lines.

=item C<put>

Takes an arrayref containing lines of uncompressed output, returns an arrayref of compressed lines.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 SEE ALSO

L<POE>

L<Compress::LZF>

L<POE::Filter::Stackable>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams <chris@bingosnet.co.uk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
