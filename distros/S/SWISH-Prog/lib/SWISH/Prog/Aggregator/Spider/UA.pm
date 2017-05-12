package SWISH::Prog::Aggregator::Spider::UA;
use strict;
use warnings;
use base qw( LWP::RobotUA );
use HTTP::Message;
use URI;
use Carp;
use Data::Dump qw( dump );
use Search::Tools::UTF8;
use SWISH::Prog::Aggregator::Spider::Response;

our $VERSION = '0.75';

# if Compress::Zlib is installed, this should handle gzip transparently.
# thanks to
# http://stackoverflow.com/questions/1285305/how-can-i-accept-gzip-compressed-content-using-lwpuseragent
my $can_accept = HTTP::Message::decodable();

# TODO handle when Zlib is *not* installed, via Content-Encoding header

#warn "Accept-Encoding: $can_accept\n";

our $Debug = $ENV{SPIDER_DEBUG} || 0;

our $Response_Class = 'SWISH::Prog::Aggregator::Spider::Response';

=pod

=head1 NAME

SWISH::Prog::Aggregator::Spider::UA - spider user agent

=head1 SYNOPSIS

 use SWISH::Prog::Aggregator::Spider::UA;
 my $ua = SWISH::Prog::Aggregator::Spider::UA->new;
 
 # $ua is a LWP::RobotUA object

=head1 DESCRIPTION

SWISH::Prog::Aggregator::Spider::UA is a subclass of 
LWP::RobotUA.

=head1 METHODS

=cut

=head2 get( I<args> )

I<args> is an array of key/value pairs. I<uri> is required.

I<delay> will sleep() I<delay> seconds before fetching I<uri>.

Also supported: I<user> and I<pass> for authorization.

=cut

sub get {
    my $self  = shift;
    my %args  = @_;
    my $uri   = delete $args{uri} or croak "URI required";
    my $delay = delete $args{delay} || 0;

    sleep($delay) if $delay;

    my $request = HTTP::Request->new( 'GET' => $uri );
    $request->header( 'Accept-Encoding' => $can_accept, );
    if ( $args{user} && $args{pass} ) {
        $request->authorization_basic( delete $args{user},
            delete $args{pass} );
    }
    else {
        # if either one was set, but not the other, delete them both
        # to prevent response_class from dying
        delete $args{pass};
        delete $args{user};
    }

    ( $Debug & 2 ) and dump $request;
    ( $Debug & 3 ) and dump \%args;

    my $resp = $self->get_response_class->new(
        http_response => $self->request($request),
        link_tags     => $self->{_swish_link_tags},
        %args,
    );
    $self->{_swish_last_uri}  = URI->new($uri);
    $self->{_swish_last_resp} = $resp;

    ( $Debug & 2 ) and dump $resp;

    return $resp;
}

=head2 head( I<args> )

Like get(), I<args> is an array of key/value pairs. I<uri> is required.

I<delay> will sleep() I<delay> seconds before fetching I<uri>.

Also supported: I<user> and I<pass> for authorization.

=cut

sub head {
    my $self  = shift;
    my %args  = @_;
    my $uri   = delete $args{uri} or croak "URI required";
    my $delay = delete $args{delay} || 0;

    sleep($delay) if $delay;

    my $request = HTTP::Request->new( 'HEAD' => $uri );
    $request->header( 'Accept-Encoding' => $can_accept, );
    if ( $args{user} && $args{pass} ) {
        $request->authorization_basic( delete $args{user},
            delete $args{pass} );
    }
    else {
        # if either one was set, but not the other, delete them both
        # to prevent response_class from dying
        delete $args{pass};
        delete $args{user};
    }

    ( $Debug & 2 ) and dump $request;

    my $resp = $self->get_response_class->new(
        http_response => $self->request($request),
        link_tags     => $self->{_swish_link_tags},
        %args,
    );

    ( $Debug & 2 ) and dump $resp;

    return $resp;
}

=head2 redirect_ok

Returns 0 (false) to override parent class behavior.

=cut

sub redirect_ok {
    return 0;    # do not follow any redirects
}

=head2 response

Returns most recent Response object.

=cut

sub response {
    my $self = shift;
    return $self->{_swish_last_resp};
}

=head2 uri

Returns most recently requested URI object.

=cut

sub uri {
    return shift->{_swish_last_uri};
}

=head2 set_link_tags( I<hashref> )

Set hashref of tags considered valid "links". Passed into every
Response object in the link_tags() accessor.

=cut

sub set_link_tags {
    my $self = shift;
    $self->{_swish_link_tags} = shift;
}

=head2 set_response_class( I<class> )

Set the Response class. Default is B<SWISH::Prog::Aggregator::Spider::Response>.

=cut

sub set_response_class {
    my $self = shift;
    $self->{_swish_response_class} = shift;
}

=head2 get_response_class

Returns the class name of objects returned from get() and head().

=cut

sub get_response_class {
    return shift->{_swish_response_class} || $Response_Class;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
