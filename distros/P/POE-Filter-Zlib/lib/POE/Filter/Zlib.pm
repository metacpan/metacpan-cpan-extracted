package POE::Filter::Zlib;
$POE::Filter::Zlib::VERSION = '2.04';
#ABSTRACT: A POE filter wrapped around Compress::Zlib

use strict;
use warnings;

use POE::Filter::Zlib::Stream;
use Compress::Raw::Zlib qw(Z_FINISH);

sub new {
  return POE::Filter::Zlib::Stream->new(flushtype => Z_FINISH);
}

qq[Zee Lib];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::Zlib - A POE filter wrapped around Compress::Zlib

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    use POE::Filter::Zlib;

    my $filter = POE::Filter::Zlib->new();
    my $scalar = 'Blah Blah Blah';
    my $compressed_array   = $filter->put( [ $scalar ] );
    my $uncompressed_array = $filter->get( $compressed_array );

    use POE qw(Filter::Stackable Filter::Line Filter::Zlib);

    my ($filter) = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Zlib->new(),
		   POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),

=head1 DESCRIPTION

POE::Filter::Zlib provides a POE filter for performing compression/uncompression using L<Compress::Zlib>. It is
suitable for use with L<POE::Filter::Stackable>.

This filter is not ideal for streaming compressed data over sockets etc. as it employs compress and uncompress zlib functions.

L<POE::Filter::Zlib::Stream> is recommended for that type of activity.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::Zlib object. Takes one optional argument,

  'level': the level of compression to employ.

Consult L<Compress::Zlib> for details.

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which is contains lines of compressed input. Returns an arrayref of uncompressed lines.

=item C<get_pending>

Returns any data in a filter's input buffer. The filter's input buffer is not cleared, however.

=item C<put>

Takes an arrayref containing lines of uncompressed output, returns an arrayref of compressed lines.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=item C<level>

Sets the level of compression employed to the given value. If no value is supplied, returns the current level setting.

=back

=head1 SEE ALSO

L<POE>

L<POE::Filter>

L<POE::Filter::Zlib::Stream>

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
