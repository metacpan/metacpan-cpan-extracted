package Net::OpenAMD;

# $AFresh1: OpenAMD.pm,v 1.20 2010/07/17 11:48:28 andrew Exp $

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1.1');
my $BASE_URI = 'https://api.hope.net/api/';

use Scalar::Util qw( refaddr );
*_ident = \&refaddr;

use LWP::UserAgent;
use URI;
use Net::OAuth;
use JSON;

{

    my @attr_refs = \(
        my %base_uri_of,
        my %ua_of, my %auth_of, my %actions_of,
        my %json_of,
    );

    sub new {
        my ( $class, $options ) = @_;
        my $self = bless do { \my $x }, $class;
        my $ident = _ident($self);

        $options ||= {};

        croak 'Options should be a hashref' if ref $options ne 'HASH';

        $base_uri_of{$ident} = $options->{base_uri} || $BASE_URI;
        $ua_of{$ident}       = $options->{ua}       || LWP::UserAgent->new();
        $json_of{$ident}     = $options->{json}     || JSON->new();
        $actions_of{$ident}  = $options->{actions}
            || [qw( location speakers talks interests users )];

        foreach my $action ( @{ $actions_of{$ident} } ) {
            ## no critic
            no strict 'refs';
            *{$action} = sub { shift->get( $action, @_ ) };
        }

        # XXX Authenticate

        return $self;
    }

    sub get {
        my ( $self, $action, $query ) = @_;
        my $ident = _ident($self);

        my $uri = URI->new_abs( $action . '/', $base_uri_of{$ident} );
        $uri->query_form($query);

        my $response = $ua_of{$ident}->get($uri);
        croak $response->status_line if !$response->is_success;

        my $data;
        eval {
            $data = $json_of{$ident}->decode( $response->decoded_content );
        };
        croak "Invalid JSON from [$uri]" if $@;

        return $data;
    }

    sub stats { croak 'Unused feature' }

    sub DESTROY {
        my ($self) = @_;
        my $ident = _ident $self;

        foreach my $attr_ref (@attr_refs) {
            delete $attr_ref->{$ident};
        }

        return;
    }

}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::OpenAMD - Perl interface to the OpenAMD API


=head1 VERSION

This document describes Net::OpenAMD version 0.0.3


=head1 SYNOPSIS

    use Net::OpenAMD;

    my $amd = Net::OpenAMD->new();

    my $location = $amd->location({ area => 'Engressia' });

  
=head1 DESCRIPTION

This module is to make it easy to grab information from the OpenAMD project at
The Next Hope.

http://wiki.hope.net/Attendee_Meta-Data

http://amd.hope.net/

http://amd.hope.net/2010/05/openamd-api-released-v1-1-1/

http://travisgoodspeed.blogspot.com/2010/06/hacking-next-hope-badge.html

=head1 INTERFACE 

=head2 new

Create a new object for accessing the OpenAMD API.

    my $amd = Net::OpenAMD->new( $options );

$options is a hashref with configuration options.

Current options are 

=over

=item base_uri

A URL to the API, currently defaults to https://api.hope.net/api/

Most likely it should end with a / to make URI happy, so notice that if you
are having 404 errors you don't expect.

=item ua

Should be a pre-configured LWP::UserAgent or similar that returns a
HTTP::Response object when its get method is called with a URI.

=back

=head2 get

This is the main method, although probably never used.  It has better/easier
ways to access the different actions of the API.

    my $data = $amd->get( $action, $params );

$params are anything that are supported by URI->query, they will get passed
on the request.

Here $data is a the JSON returned by the API converted to Perl reference.

Helper methods you can call as $amd->method($params) are:

=over

=item interests

=item location

=item new

=item speakers

=item stats

=item talks

=item users

=back

Unless specified, there is nothing different about any of the action methods
than just calling get($action) instead.  Depending on API changes, this may
not always be the case.

=head1 DIAGNOSTICS

All methods should croak when an error occurs.  
If the remote API returns a successful response that contains valid JSON, that
will be decoded and returned.

=head1 CONFIGURATION AND ENVIRONMENT

Net::OpenAMD requires no configuration files or environment variables.

Net::OpenAMD uses LWP::UserAgent for requests and environment for that is
not cleared.

=head1 DEPENDENCIES

=head3 L<LWP::UserAgent>

=head3 L<URI>

=head3 L<Net::OAuth>

=head3 L<JSON::Any>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=over 

=item Currently it does not support the OAuth that is required to log into the
API and get information.  

=back

Please report any bugs or feature requests to
C<bug-net-openamd@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
