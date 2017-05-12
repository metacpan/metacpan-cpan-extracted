package SVN::Dump::Headers;

use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype );

my $NL = "\012";

sub new {
    my ( $class, $headers ) = @_;
    croak 'First parameter must be a HASH reference'
        if defined $headers
        && !( ref $headers && reftype $headers eq 'HASH' );
    my $self = bless {}, $class;
    $self->set( $_ => $headers->{$_} ) for keys %{ $headers || {} };
    return $self;
}

my %headers = (
    revision => [
        qw(
            Revision-number
            Prop-content-length
            Content-length
            )

    ],
    node => [
        qw(
            Node-path
            Node-kind
            Node-action
            Node-copyfrom-rev
            Node-copyfrom-path
            Prop-delta
            Prop-content-length
            Text-copy-source-md5
            Text-copy-source-sha1
            Text-delta
            Text-content-length
            Text-content-md5
            Text-content-sha1
            Content-length
            )
    ],
    uuid   => ['UUID'],
    format => ['SVN-fs-dump-format-version'],
);

# FIXME Prop-delta and Text-delta in version 3

sub as_string {
    my ($self) = @_;
    my $string = '';

    for my $k ( @{ $headers{ $self->type() } } ) {
        $string .= "$k: $self->{$k}$NL"
            if exists $self->{$k};
    }

    return $string . $NL;
}

sub type {
    my ($self) = @_;

    my $type =
          exists $self->{'Node-path'}                  ? 'node'
        : exists $self->{'Revision-number'}            ? 'revision'
        : exists $self->{'UUID'}                       ? 'uuid'
        : exists $self->{'SVN-fs-dump-format-version'} ? 'format'
        :   croak 'Unable to determine the record type';

    return $type;
}

sub set {
    my ($self, $h, $v) = @_;

    # FIXME shall we check that the header value is valid?
    $h =~ tr/_/-/; # allow _ for - simplification
    return $self->{$h} = $v;
}

sub get {
    my ($self, $h) = @_;
    $h =~ tr/_/-/; # allow _ for - simplification
    return $self->{$h};
}

sub keys {
    my ($self) = @_;
    return grep { exists $self->{$_} } @{ $headers{$self->type()} };
}

1;

__END__

=head1 NAME

SVN::Dump::Headers - Headers of a SVN dump record

=head1 SYNOPSIS

    # SVN::Dump::Headers objects are returned by the read_header_block()
    # method of SVN::Dump::Reader

=head1 DESCRIPTION

A SVN::Dump::Headers object represents the headers of a
SVN dump record.

=head1 METHODS

SVN::Dump::Headers provides the following methods:

=over 4

=item new( [$hashref] )

Create and return a new empty L<SVN::Dump::Headers> object.

If C<$hashref> is given (it can be a blessed hash reference), the
keys from the hash are used to initialise the headers.

=item set($h, $v)

Set the C<$h> header to the value C<$v>.

C<_> can be used as a replacement for C<-> in the header name.

=item get($h)

Get the value of header C<$h>.

C<_> can be used as a replacement for C<-> in the header name.

=item keys()

Return the list of headers, in canonical order.

=item as_string()

Return a string that represents the record headers.

=item type()

It is possible to guess the record type from its headers.

This method returns a string that represents the record type.
The string is one of C<revision>, C<node>, C<uuid> or C<format>.

The method dies if it can't determine the record type.

=back

=head1 ENCAPSULATION

When using L<SVN::Dump> to manipulate a SVN dump, one should not directly
access the L<SVN::Dump::Headers> component of a L<SVN::Dump::Record>, but
use the C<set_header()> and C<get_header()> methods of the record object.

=head1 SEE ALSO

L<SVN::Dump>,
L<SVN::Dump::Reader>,
L<SVN::Dump::Record>.

=head1 COPYRIGHT

Copyright 2006-2011 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
