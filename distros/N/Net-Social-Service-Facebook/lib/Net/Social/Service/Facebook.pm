package Net::Social::Service::Facebook;

use strict;
use warnings;
use base qw(Net::Social::Service);
use WWW::Facebook::API;
use Net::Social qw(:all);
use vars qw($VERSION);


$VERSION = "0.1";

=head1 NAME

Net::Social::Service::Facebook - a Facebook plugin for Net::Social

=head1 PARAMS

For reading Net::Social::Service::Facebook needs

=over4

=item api_key

You need an API key from Facebook. You can read how to
get one from here

    http://developers.facebook.com/get_started.php

=item session_secret

See below.

=item session_key

See below.

=back

=cut

sub params {(
    read => {
        "api_key" => { required    => 1, 
                       description => "Your Facebook API key",
                    },
        "session_secret" => { required    => 1, 
                       description => "Your Facebpook API secret",
                    },
        "session_key" => { required    => 1, 
                       description => "Your Facebpook API secret",
                    },
    },
)}

=head1 GETTING A PERMANENT FACEBOOK SESSION

I use this script

    #!perl -w

    use strict;
    use WWW::Facebook::API;

    my $api_key        = shift || die "You must pass an api key\n"; # get these when you sign up
    my $secret         = shift || die "You must pass an api secret"; # as a facebook developer
    my $client         = make_client($api_key, $secret);

    # Now get the auth token
    print "1) Go to ".$client->get_infinite_session_url."\n";
    print "2) Press 'Generate' and get token\n";
    print "3) Enter the token now\n";
    chomp(my $token = <>);

    # Get a session
    $client->auth->get_session($token);
    $session_key    = $client->session_key;
    $session_secret = $client->secret;

    # And note the session key
    print "4) Your infinite session key is $session_key\n";
    print "5) Your infinite session secret is $session_secret\n";

    # Now make a new client and set the session key again to see that it works
    my $new_client = make_client($api_key, $session_secret);
    $new_client->session_key($session_key);

    # And get my friends
    my $friends = $new_client->users->get_info( uids => $new_client->friends->get, fields => 'name');
    print join("\n", map { $_->{name} } @$friends)."\n";

    sub make_client {
        my ($api_key, $secret) = @_;

        my $client = WWW::Facebook::API->new(
                parse        => 1,
                throw_errors => 1,
        );
        $client->api_key($api_key);
        $client->secret($secret);
        $client->desktop(1);
        return $client;
    }

=head1 METHODS

=head2 friends

Returns your friends. It defines the keys C<uid>, C<name> and C<type>.

=cut

sub friends {
    my $self = shift;
    return () unless $self->{_logged_in};
    my $user        = $self->{_details}->{username};
    my $key         = $self->{_details}->{api_key};
    my $sess_key    = $self->{_details}->{session_key}; 
    my $sess_secret = $self->{_details}->{session_secret};
    my $client = WWW::Facebook::API->new(
        desktop      => 1,
        parse        => 1,
        throw_errors => 1,        
#        debug => 1,
    );
    #$secret = $sess_secret if defined $sess_secret.
    $client->api_key($key);
    $client->session_key($sess_key);
    $client->secret($sess_secret);
    $client->desktop(1);

    my %friends;
    my $uids = $client->friends->get;
    # First get their details
    foreach my $friend (@{$client->users->get_info(uids=>$uids, 
                                                   fields=>[qw(name uid )])
                        })
    {
        $friends{$friend->{uid}} = { id => $friend->{uid}, name => $friend->{name}, type => MUTUAL };

    }
    return values %friends;
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Distributed under the same terms as Perl itself

=cut


1;
