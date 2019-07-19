package Net::Stomp::Frame;
use strict;
use warnings;

our $VERSION='0.60';

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(command headers body));

BEGIN {
    for my $header (
        qw(destination exchange content-type content-length message-id reply-to))
    {
        my $method = $header;
        $method =~ s/-/_/g;
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            $self->headers->{$header} = shift if @_;
            $self->headers->{$header};
        };
    }
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->headers({}) unless defined $self->headers;
    return $self;
}

sub as_string {
    my $self    = shift;
    my $command = $self->command;
    my $headers = $self->headers;
    my $body    = $self->body;
    my $frame   = $command . "\n";

    # insert a content-length header
    my $bytes_message = 0;
    if ( $headers->{bytes_message} ) {
        $bytes_message = 1;
        delete $headers->{bytes_message};
        $headers->{"content-length"} = length( $self->body );
    }

    while ( my ( $key, $value ) = each %{ $headers || {} } ) {
        $frame .= $key . ':' . (defined $value ? $value : '') . "\n";
    }
    $frame .= "\n";
    $frame .= $body || '';
    $frame .= "\0";
}

sub parse {
    my ($class,$string) = @_;

    $string =~ s{
      \A\s*
      ([A-Z]+)\n #command
      ((?:[^\n]+\n)*)\n # header block
    }{}smx;
    my ($command,$headers_block) = ($1,$2);

    return unless $command;

    my ($headers,$body);
    if ($headers_block) {
        foreach my $line (split(/\n/, $headers_block)) {
            my ($key, $value) = split(/\s*:\s*/, $line, 2);
            $headers->{$key} = $value;
        }
    }

    if ($headers && $headers->{'content-length'}) {
        if (length($string) >= $headers->{'content-length'}) {
            $body = substr($string,
                           0,
                           $headers->{'content-length'},
                           '' );
        }
        else { return } # not enough body
    } elsif ($string =~ s/\A(.*?)\0//s) {
        # No content-length header.
        $body = $1 if length($1);
    }
    else { return } # no body

    return $class->new({
        command => $command,
        headers => $headers,
        body => $body,
    });
}

1;

__END__

=head1 NAME

Net::Stomp::Frame - A STOMP Frame

=head1 SYNOPSIS

  use Net::Stomp::Frame;
  my $frame = Net::Stomp::Frame->new( {
    command => $command,
    headers => $headers,
    body    => $body,
  } );
  my $frame  = Net::Stomp::Frame->parse($string);
  my $string = $frame->as_string;

=head1 DESCRIPTION

This module encapulates a Stomp frame.

A Stomp frame consists of a command, a series of headers and a body.

For details on the protocol see L<https://stomp.github.io/>.

=head1 METHODS

=head2 new

Create a new L<Net::Stomp::Frame> object:

  my $frame = Net::Stomp::Frame->new( {
    command => $command,
    headers => $headers,
    body    => $body,
  } );

=head2 parse

Create a new L<Net::Somp::Frame> given a string containing the serialised frame:

  my $frame  = Net::Stomp::Frame->parse($string);

=head2 as_string

Create a string containing the serialised frame representing the frame:

  my $string = $frame->as_string;

=head2 command

Get or set the frame command.

=head2 body

Get or set the frame body.

=head2 headers

Get or set the frame headers, as a hashref. All following methods are
just shortcuts into this hashref.

=head2 destination

Get or set the C<destination> header.

=head2 content_type

Get or set the C<content-type> header.

=head2 content_length

Get or set the C<content-length> header.

=head2 exchange

Get or set the C<exchange> header.

=head2 message_id

Get or set the C<message-id> header.

=head2 reply_to

Get or set the C<reply-to> header.

=head1 SEE ALSO

L<Net::Stomp>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 CONTRIBUTORS

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT

Copyright (C) 2006, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

