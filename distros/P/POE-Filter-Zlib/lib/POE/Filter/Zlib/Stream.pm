package POE::Filter::Zlib::Stream;
$POE::Filter::Zlib::Stream::VERSION = '2.04';
use strict;
use warnings;
use Carp;
use Compress::Raw::Zlib qw(Z_OK Z_STREAM_END Z_FINISH Z_SYNC_FLUSH);
use vars qw($VERSION);
use base qw(POE::Filter);

$VERSION = '2.02';

sub new {
  my $type = shift;
  croak "$type requires an even number of parameters" if @_ % 2;
  my $buffer = { @_ };
  $buffer->{ lc $_ } = delete $buffer->{ $_ } for keys %{ $buffer };
  $buffer->{BUFFER} = '';
  delete $buffer->{deflateopts} unless ref ( $buffer->{deflateopts} ) eq 'HASH';
  $buffer->{d} = Compress::Raw::Zlib::Deflate->new( %{ $buffer->{deflateopts} } );
  unless ( $buffer->{d} ) {
	warn "Failed to create deflate stream\n";
	return;
  }
  delete $buffer->{inflateopts} unless ref ( $buffer->{inflateopts} ) eq 'HASH';
  $buffer->{i} = Compress::Raw::Zlib::Inflate->new ( %{ $buffer->{inflateopts} } );
  unless ( $buffer->{i} ) {
	warn "Failed to create inflate stream\n";
	return;
  }
  if (not defined $buffer->{flushtype}) {
  	$buffer->{flushtype} = Z_SYNC_FLUSH;
  }
  return bless $buffer, $type;
}

# use inherited get() from POE::Filter

sub get_one_start {
  my ($self, $raw_lines) = @_;
  $self->{BUFFER} .= join '', @{ $raw_lines };
}

sub get_one {
  my $self = shift;

  return [ ] unless length $self->{BUFFER};
  my ($status, $out);
  $status = $self->{i}->inflate( \$self->{BUFFER}, $out );

  unless ( $status == Z_OK or $status == Z_STREAM_END ) {
    warn "Couldn\'t inflate buffer\n";
    return [ ];
  }
  if ($status == Z_STREAM_END) {
    $self->{i} = Compress::Raw::Zlib::Inflate->new ( %{ $self->{inflateopts} } );
  }
  return [ $out ];
}

sub get_pending {
  my $self = shift;
  return $self->{BUFFER} ? [ $self->{BUFFER} ] : undef;
}

sub put {
  my ($self, $events) = @_;
  my $raw_lines = [];

  foreach my $event (@$events) {
	my ($dstat, $dout);
	$dstat = $self->{d}->deflate( $event, $dout );
	unless ( $dstat == Z_OK ) {
	  warn "(data) Couldn\'t deflate: $event\n($dstat)";
	  next;
	}
	my ($fout,$fstat);
	$fstat = $self->{d}->flush( $fout, $self->{flushtype} );
	unless ( $fstat == Z_OK ) {
	  warn "(flush) Couldn\'t flush/deflate: $event\n";
	  next;
	}
	if ($self->{flushtype} == Z_FINISH) {
  	  $self->{d} = Compress::Raw::Zlib::Deflate->new ( %{ $self->{deflateopts} } );
	}
	push @$raw_lines, $dout . $fout;
  }
  return $raw_lines;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{d} = Compress::Raw::Zlib::Deflate->new( %{ $nself->{deflateopts} } );
  $nself->{i} = Compress::Raw::Zlib::Inflate->new( %{ $nself->{inflateopts} } );
  $nself->{BUFFER} = '';
  return bless $nself, ref $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::Zlib::Stream

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    use POE::Filter::Zlib::Stream;

    my $filter = POE::Filter::Zlib::Stream->new( deflateopts => { -Level => 9 } );
    my $scalar = 'Blah Blah Blah';
    my $compressed_array   = $filter->put( [ $scalar ] );
    my $uncompressed_array = $filter->get( $compressed_array );

    use POE qw(Filter::Stackable Filter::Line Filter::Zlib::Stream);

    my ($filter) = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Zlib::Stream->new(),
		   POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),

=head1 DESCRIPTION

POE::Filter::Zlib::Stream provides a POE filter for performing compression/uncompression using L<Compress::Zlib>. It is
suitable for use with L<POE::Filter::Stackable>.

Unlike L<POE::Filter::Zlib> this filter uses deflate and inflate, not the higher level compress and uncompress.

Ideal for streaming compressed data over sockets.

=head1 NAME

POE::Filter::Zlib::Stream - A POE filter wrapped around Compress::Zlib deflate and inflate.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::Zlib::Stream object. Takes some optional arguments:

=over 4

=item "deflateopts"

a hashref of options to be passed to deflateInit();

=item "inflateopts"

a hashref of options to be passed to inflateInit();

=item "flushtype"

The type of flush to use when flushing the compressed data. Defaults to
Z_SYNC_FLUSH so you get a single stream, but if there is a
L<POE::Filter::Zlib> on the other end, you want to set this to Z_FINISH.

=back

Consult L<Compress::Zlib> for more detail regarding these options.

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which is contains streams of compressed input. Returns an arrayref of uncompressed streams.

=item C<get_pending>

Returns any data in a filter's input buffer. The filter's input buffer is not cleared, however.

=item C<put>

Takes an arrayref containing streams of uncompressed output, returns an arrayref of compressed streams.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

Martijn van Beers <martijn@cpan.org>

=head1 LICENSE

Copyright E<copy> Chris Williams and Martijn van Beers.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Filter>

L<Compress::Zlib>

L<POE::Filter::Stackable>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Martijn van Beers

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams and Martijn van Beers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
