#
# File: Stomp.pm
# Date: 30-Aug-2007
# By  : Kevin Esteb
#
# This module will parse the input stream and create Net::Stomp::Frame 
# objects from that input stream. A STOMP frame looks like this:
#
#    command<newline>
#    headers<newline>
#    <newline>
#    body
#    \000
#
# notes for v0.04
#
# The protocol spec calls for "newline" as the EOL. All implementatons
# are translating this into "\n". This is fine, except that "\n" has 
# differing meanings depending on OS and/or language you are using. 
# This complicated matters when parsing packets. 
#
# More information is located at http://stomp.codehaus.org/Protocol
#

package POE::Filter::Stomp;

use 5.008;
use strict;
use warnings;

use Net::Stomp::Frame;

our $VERSION = '0.04';

# Be strick in what you send...

use constant EOL => "\n";
use constant EOF => "\000";

# But lenient in what you recieve...

my $eof = "\000";
my $eol = qr((\015\012?|\012\015?|\015|\012));
#my $eol = qr((\012|\015|\015\012?|\012\015?));
my $cntrl = qr((?:[[:cntrl:]])+);

# ---------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------

sub new {
    my $proto = shift;

    my $self = {};
    my $class = ref($proto) || $proto;

    $self->{buffer} = "";

    bless($self, $class);

    return $self;

}

sub get_one_start {
    my ($self, $buffers) = @_;

    $buffers = [$buffers] unless (ref($buffers));
    $self->{buffer} .=  join('', @$buffers);

}

sub get_one {
    my ($self) = shift;

    my $frame;
    my $buffer;
    my @ret;

    $frame = $self->_parse_frame();
    push(@ret, $frame) if ($frame);

    return \@ret;

}

sub get_pending {
    my ($self) = shift;

    return($self->{buffer});

}

sub put {
    my ($self, $frames) = @_;

    my $string;
    my $ret = [];

    foreach my $frame (@$frames) {

        # protocol spec is unclear about the case of the command,
        # so uppercase the command, Why, just because I can.

        my $command = uc($frame->command);
        my $headers = $frame->headers;
        my $body = $frame->body;

        $string = $command . EOL;

        if ($headers->{bytes_message}) {

            delete $headers->{bytes_message};
            $headers->{'content-length'} = length($body);

        }

        # protocol spec is unclear about spaces between headers and values
        # nor the case of the header, so add a space and lowercase the 
        # header. Why, just because I can.

        while (my ($key, $value) = each %{$headers || {} }) {

            $string .= lc($key) . ': ' . $value . EOL;

        }

        $string .= EOL;
        $string .= $body || '';
        $string .= EOF;

        push (@$ret, $string);

    }

    return $ret;

}

# ---------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------

sub _read_line {
    my ($self) = @_;

    my $buffer;

    if ($self->{buffer} =~ s/^(.+?)$eol//) {

        $buffer = $1;

    }

    return $buffer;

}

sub _parse_frame {
    my ($self) = @_;

    my $frame;
    my $length;
    my $clength;

    # check for a valid buffer, must have a EOL someplace

    return () if ($self->{buffer} !~ /$eol/);

    # read the command

    if (! $self->{command}) {

        if (my $command = $self->_read_line()) {

            $self->{command} = $command;

        } else { return (); }

    }

    # read the headers, parse until a double new line, 
    # punt if they are not found.

    if (! $self->{headers}) { 

        $self->{buffer} =~ m/$eol$eol/g;
        $clength = pos($self->{buffer}) || -1;

        if ($clength == -1) {

            pos($self->{buffer}) = 0;
            $self->{buffer} =~ m/$eol$eof/g;
            $clength = pos($self->{buffer}) || -1;

        }

        $length = length($self->{buffer});

        return () if ($clength == -1);

        if ($clength <= $length) {

            my %headers = ();

            while (my $line = $self->_read_line()) {

                if ($line =~ /^([\w\-~]+)\s*:\s*(.*)/) {

                    $headers{lc($1)} = $2;

                }

            }

            $self->{headers} = \%headers;
            $self->{buffer} =~ s/^$eol//;

        } else { return (); }

    }

    # read the body
    #
    # if "content-length" is defined then the body is binary, 
    # otherwise search the buffer until an EOF is found.

    $clength = 0;
    $length = length($self->{buffer});

    if ($self->{headers}->{'content-length'}) {

        $self->{headers}->{bytes_message} = 1;
        $clength = $self->{headers}->{'content-length'};

        if ($clength <= $length) {

            $self->{body} = substr($self->{buffer}, 0, $clength);
            substr($self->{buffer}, 0, $clength) = "";

        } else { return (); }

    } else { 

        $clength = index($self->{buffer}, $eof);

        return () if ($clength == -1);

        if ($clength == 0) {

            $self->{body} = " ";

        } else {

            $self->{body} = substr($self->{buffer}, 0, $clength);
            substr($self->{buffer}, 0, $clength) = "";

        }

    }

    # remove the crap from between the frames

    $self->{buffer} =~ s/$cntrl//;

    # create the frame

    if ($self->{command} && $self->{headers} && $self->{body}) {

        $frame = Net::Stomp::Frame->new(
            {
                command => $self->{command},
                headers => $self->{headers},
                body    => $self->{body}
            }
        );

        delete $self->{command};
        delete $self->{headers};
        delete $self->{body};

    }

    return $frame;

}

1;

__END__

=head1 NAME

POE::Filter::Stomp - Perl extension for the POE Environment

=head1 SYNOPSIS

  use POE::Filter::Stomp;

  For a server

  POE::Component::Server::TCP->new(
      ...
      Filter => 'POE::Filter::Stomp',
      ...
  );

  For a client

  POE::Component::Client::TCP->new(
      ...
      Filter => 'POE::Filter::Stomp',
      ...
  );

=head1 DESCRIPTION

This module is a filter for the POE environment. It will translate the input
buffer into Net::Stomp::Frame objects and serialize the output buffer from 
said objects. For more information an the STOMP protocol, please refer to: 
http://stomp.codehaus.org/Protocol .

=head1 EXPORT

None by default.

=head1 SEE ALSO

See the documentation for POE::Filter for usage.

=head1 BUGS

Quite possibly. It works for me, maybe it will work for you.

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
