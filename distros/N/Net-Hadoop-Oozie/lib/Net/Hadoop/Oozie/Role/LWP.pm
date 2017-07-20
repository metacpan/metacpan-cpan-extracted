package Net::Hadoop::Oozie::Role::LWP;
$Net::Hadoop::Oozie::Role::LWP::VERSION = '0.110';
use 5.010;
use strict;
use warnings;

use Carp qw( confess );
use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };
use JSON::XS;
use LWP::UserAgent;
use Moo::Role;
use Scalar::Util qw( blessed );

with 'Net::Hadoop::YARN::Roles::Common';

my $json = JSON::XS->new->pretty(1)->canonical(1);

# TODO: use the one from YARN or migrate there
sub agent_request {
    my $self = shift;
    my ($uri, $method, $payload) = @_;

    print "OOZIE URI: $uri\n" if DEBUG;

    my $response; 
    if (!$method || $method eq 'get') {
        $response = $self->ua->get($uri);
    }
    elsif ($method eq 'post') {
        $response = $self->ua->post(
            $uri,
            'Content-Type' => "application/xml;charset=UTF-8",
            Content        => $payload
        );
    }
    elsif ($method eq 'put') {
        $response = $self->ua->put( $uri,
            'Content-Type' => "application/xml;charset=UTF-8",
        );
    }
    else {
        die "Unknown method";
    }

    my $content = $response->decoded_content || '';

    if ( $response->is_success ) {

        return {} if !$content;

        my $type = $response->header('content-type') || q{};

        return { response => $content } if index( lc $type, 'json' ) == -1;

        my $res;

        eval {
            $res = $json->decode($content);
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            confess q{server response wasn't valid JSON: } . $eval_error;
        };

        return $res;
    }

    my $headers = $response->headers;
    my $code    = $response->code;
    my $info    = $content =~ m{\Q<b>description</b>\E\s+<u>(.+?)</u>}xmsi
                    ? "$1 "
                    : ''
                    ;
    my $extramsg;
    if ( $code == 401 ) {
        $extramsg = ( $headers->{'www-authenticate'} || '' ) eq 'Negotiate'
                    ? eval { require LWP::Authen::Negotiate; 1; }
                        ? q{ (Did you forget to run kinit?) }
                        : q{ (LWP::Authen::Negotiate doesn't seem available) }
                    : '';
    }

    confess sprintf '%s%s -> %s', $info . $extramsg, $response->status_line, $uri;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::Oozie::Role::LWP

=head1 VERSION

version 0.110

=head1 SYNOPSIS

    with 'Net::Hadoop::Oozie::Role::LWP';
    # TODO

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 NAME

Net::Hadoop::Oozie::Role::LWP - User agent for Oozie requests

=head1 METHODS

=head2 agent_request

TODO.

=head1 SEE ALSO

L<Net::Hadoop::Oozie>.

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
