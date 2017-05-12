package Purple::Server::REST;

use warnings;
use strict;
our $VERSION = '0.9';

use base qw(HTTP::Server::Simple::CGI);
use Purple;
use URI::Escape;

sub _New {
    my $class = shift;
    my %p     = @_;

    $p{port} ||= 9999;
    my $self  = $class->SUPER::new( $p{port} );
    $self->{purple} = Purple->new( store => $p{store} );
    return $self;
}

sub handle_request {
    my $self = shift;
    my $cgi  = shift;    # throwaway?

    my $method = $cgi->request_method;

    my $output;
    my $status;
    if ( $self->can($method) ) {
        eval {
            # XXX trap empty output when no match
            $output = $self->$method($cgi);
            $status = '200';
        };
        if ($@) {
            $status = '500';
            $output = $@;
        }
    }
    else {
        $status = '500';                              # XXX not right
        $output = "Method $method not supported\n";

    }

    # empty response still means success
    # XXX need to make this a real HTTP response
    $output = "HTTP/1.0 $status OK\n\n" . $output;
    print $output;
}

sub _get_info {
    my $self = shift;
    my $path = shift;
    $path =~ s{^/}{};
    return uri_unescape($path);
}

sub GET {
    my $self = shift;
    my $cgi  = shift;
    my $info = $self->_get_info( $cgi->path_info );

    if ( $info =~ m{^/?\w+:} ) {
        return $self->_handle_get_nid($info);
    }
    return $self->_handle_get_uri($info);
}

# XXX not currently used
sub PUT {
    my $self = shift;
    my $cgi  = shift;
    my $nid  = $self->_get_info( $cgi->path_info );

    my $uri = $self->_get_content($cgi);

    return $self->{purple}->updateURL( $nid, $uri );
}

sub DELETE {
    my $self = shift;
    my $cgi  = shift;
    my $nid  = $self->_get_info( $cgi->path_info );
    return $self->{purple}->deleteNIDs($nid);
}

sub POST {
    my $self = shift;
    my $cgi  = shift;
    my $uri  = $self->_get_content($cgi);
    my $nid;

    ( $uri, $nid ) = split( '#', $uri );

    if ($nid) {
        return $self->{purple}->updateURL( $uri, $nid );
    }

    return $self->{purple}->getNext($uri);
}

sub _handle_get_nid {
    my $self = shift;
    my $uri  = shift;
    return $self->{purple}->getNIDs($uri);
}

sub _handle_get_uri {
    my $self = shift;
    my $nid  = shift;
    return $self->{purple}->getURL($nid);
}

sub _get_content {
    my $self = shift;
    my $cgi  = shift;

    return $cgi->param('keywords');
}

=head1 NAME

Purple::Server - Server for Purple Numbers

=head1 VERSION

Version 0.9

=head1 SYNOPSIS

Server up some purple numbers of HTTP, in a RESTful way.

=head1 METHODS

=head2 handle_request

Handles the request.

=head2 GET

Handles HTTP GET.

=head2 POST

Handles HTTP POST.

=head2 PUT

Handles HTTP POST.

=head1 AUTHORS

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Purple
