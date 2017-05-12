package Net::Social::Service::Twitter;

use strict;

=head1 NAME

Net::Social::Service::Twitter - handle friends from Twitter for Net::Social


=cut

our $VERSION = '0.1';

use base qw(Net::Social::Service);
use Carp qw(cluck);
use Net::Twitter;
use Net::Social qw(:all);

=head1 SYNOPSIS

Net:Social::Service::Twitter returns a list of friends that you have on
the Twitter service.

    use Net::Social;

    my $site  = Net::Social->site("Twitter");
    $site->login(%params}) || die "Need username and password";
    my @friends = $site-friends;

=head1 FUNCTIONS

=head2 params

Describes the required parameters for logging in (for Twitter, 
username and password).

=cut

sub params {(
    'write' => {
        "username" => { required    => 1, 
                        description => "Your Twitter username",
                    },
        "password" => {
                        required => 1,
                        description => "Your Twitter password",
                    },
    },
)}

=head2 friends

Returns your friends. It defines the keys C<username>, C<name> and C<type>.

=cut

sub friends {
    my $self = shift;

    my $twit = $self->_make_twit() || return ();
    my %friends   = ();
    my @constants = (FRIENDED, FRIENDED_BY);
    foreach my $what (qw(following followers)){
        my $type = shift @constants;
		my $people = eval { $twit->$what() };
		if ($@ or !$people) {
			 cluck "There was a problem getting the '$what' list from Twitter";
			 return ();
		}
        foreach my $person (@{$people}) {
            my $user = $person->{screen_name};
            my $name = $person->{name};
            my $info = $friends{$name} || { username => $user, name => $name };
            $info->{type}  |= $type;
            $friends{$name} = $info;
        }
    }
    return values %friends;
}

sub _make_twit {
    my $self = shift;

    return undef unless $self->{_logged_in};
    my $user = $self->{_details}->{username};
    my $pass = $self->{_details}->{password};

    return Net::Twitter->new( username => $user, password => $pass );
}

=head2 add_friend <friend>

Add a friend.

Takes a Twitter friend as returned by the C<friends()> method.

Returns 1 on success or 0 on failure.

=cut

sub add_friend {
    my $self   = shift;
    my $twit   = $self->_make_twit || return 0;
    my $friend = shift             || return 0;
    return 0 unless defined $friend->{username};
    my $res    = $twit->follow($friend->{username});
    return defined $res;
}

=head2 delete_friend <friend>

Delete a friend.

Takes a Twitter friend as returned by the C<friends()> method.

Returns 1 on success 0 on failure.

=cut

sub delete_friend {
    my $self   = shift;
    my $twit   = $self->_make_twit || return 0;
    my $friend = shift             || return 0;
    return 0 unless defined $friend->{username};
    my $res    = $twit->stop_following($friend->{username});
    return defined $res;
}



=head1 PREREQUISITES

This module uses Net::Twitter, so you'll need that (and JSON::Any).
You'll also need Net::Social.

=head1 CAVEATS

The 'friends' API method only returns the last 100 users to have updated.
In the event you're free and easy with friending users, there appears to 
be no way of finding out who all of them are, at least not from the API.

=head1 AUTHORS

  Paul Mison <cpan@husk.org>
  Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2007, Paul Mison and Simon Wistow

Released under the same terms as Perl itself.

=cut

23;
