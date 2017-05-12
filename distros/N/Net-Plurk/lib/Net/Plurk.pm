package Net::Plurk;
use feature ':5.10';
use Moose;
use URI;
use JSON::Any;
use AnyEvent::HTTP;
use Net::Plurk::UserProfile;
use Net::Plurk::OAuth;
use DateTime;
use Data::Dumper;

use namespace::autoclean;

has consumer_key => ( isa => 'Str', is => 'ro');
has consumer_secret => ( isa => 'Str', is => 'ro');
has cookie => ( isa => 'HashRef', is => 'rw', default => sub{{}});
has oauth => (
    isa => 'Net::Plurk::OAuth',
    is => 'rw',
    lazy_build => 1,
    builder => '_init_oauth');
has own_profile => ( isa => 'Net::Plurk::UserProfile', is => 'rw');
has publicProfiles => ( isa => 'HashRef', is => 'rw', default => sub {{}});
#has plurks => ( isa => 'ArrayRef[Net::Plurk::Plurk]', is => 'rw', default => sub {[]});
#has plurk_users => ( isa => 'HashRef[Net::Plurk::User]', is => 'rw', default => sub {{}});
has plurks => ( isa => 'ArrayRef', is => 'rw', default => sub {[]});
has plurk_users => ( isa => 'HashRef', is => 'rw', default => sub {{}});
has lastPollingTime => (isa => 'DateTime', is => 'rw',
        # default is 5 mins ago
        default => sub {DateTime->from_epoch( epoch => time() - 5 * 60 );}
    );
has events => ( isa => 'HashRef[CodeRef]', is => 'rw', default => sub {{}});
has unreadCount => ( isa => 'Int', is => 'ro' );
has unreadAll => ( isa => 'Int', is => 'ro' );
has unreadMy => ( isa => 'Int', is => 'ro' );
has unreadPrivate => ( isa => 'Int', is => 'ro' );
has unreadResponded => ( isa => 'Int', is => 'ro' );
has raw_output => ( isa => 'Int', is => 'rw', default => 0);

=head1 NAME

Net::Plurk - A perl interface to Plurk API

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Plurk;
    my $key = $CONSUMER_KEY;
    my $secret = $CONSUMER_SECRET;
    my $access_token = $ACCESS_TOKEN
    my $access_secret = $ACCESS_TOKEN_SECRET
    my $p = Net::Plurk->new(consumer_key => $key, consumer_secret => $secret);
    my $p->authorize(access_token => $access_token,
	access_token_secret => $access_secret)
    my $profile = $p->get_own_profile();
    $p->add_events(
        on_new_plurk => sub {
            my $plurk = shift;
            use Data::Dumper; warn Dumper $plurk;
        },
        on_private_plurk => sub {
            my $plurk = shift;
            # blah
        },
        );
    $p->listen;
    my $json = $p->callAPI( '/api');
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 callAPI

Everything from here

=cut

sub _init_oauth {
    my ($self) = @_;
    return Net::Plurk::OAuth->new(
	consumer_key => $self->consumer_key,
	consumer_secret => $self->consumer_secret
    );
}

=head2 errorcode

return errorcode

=cut

sub errorcode {
    my ($self) = @_;
    return $self->oauth->_errorcode;
}

=head2 errormsg

return errormsg

=cut

sub errormsg {
    my ($self) = @_;
    return $self->oauth->_errormsg;
}

=head2 authorize

authorize with access token/secret

=cut

sub authorize {
    my ($self, %args) = @_;
    return $self->oauth->authorize(
	access_token => $args{'token'} || $args{'access_token'},
	access_token_secret => $args{'token_secret'} || $args{'access_token_secret'},
    )
};

=head2 callAPI

Everything from here

=cut

sub callAPI {
    my ($self, $path, %args) = @_;
    my ($data, $header);

    $path = '/APP'.$path unless $path =~ m#/(?:APP|OAuth)#;
    return $self->oauth->request($path, %args);
}

=head2 _get_unique_id

given nick_name, return unique_id

=cut

sub _get_unique_id {
    my ($self, $nick_name) = @_;
    # check if we have it in cache, since we only want to retreive unique id
    $self->get_public_profile($nick_name) unless $self->publicProfiles->{ $nick_name };
    return $self->publicProfiles->{$nick_name}->{user_info}->id;
}

=head2 get_nick_name

given unique_id, return nick_name

=cut

sub get_nick_name {
    my ($self, $id) = @_;

    $self->get_own_profile() unless $self->own_profile;
    return $self->own_profile->nick_name
	if $self->own_profile->{user_info}->{id} eq $id;

    my $profile = $self->get_public_profile($id);
    return $profile->nick_name;
}

=head2 get_public_profile

call /Profile/getPublicProfile

=cut

sub get_public_profile {
    my ($self, $user) = @_;
    my $json_data = $self->callAPI(
        '/Profile/getPublicProfile',
        user_id => $user,
    );
    return $json_data if $self->raw_output;
    $self->publicProfiles->{ $user } = Net::Plurk::PublicUserProfile->new($json_data);
    return $self->publicProfiles->{ $user };
}

=head2 get_own_profile

call /Profile/getOwnProfile

=cut

sub get_own_profile {
    my ($self, $user) = @_;
    my $json_data = $self->callAPI(
        '/Profile/getOwnProfile',
    );
    return $json_data if $self->raw_output;
    $self->own_profile(Net::Plurk::UserProfile->new($json_data));
    return $self->own_profile;
}

=head2 get_new_plurks

call /Polling/getPlurks
arguments =>
    offset: Return plurks newer than offset, formatted as 2009-6-20T21:55:34.

=cut

sub get_new_plurks {
    my ($self, %args) = @_;
    $args{offset} //= $self->lastPollingTime;
    $args{limit} //= 50; # default is 50
    $args{offset} = $args{offset}->strftime("%Y-%m-%dT%H:%M:%S");
    my $json_data = $self->callAPI(
        '/Polling/getPlurks',
        offset => $args{offset},
        limit => $args{limit},
    );
    return $json_data if $self->raw_output;
    $self->plurk_users($json_data->{plurk_users});
    $self->plurks($json_data->{plurks});
    $self->lastPollingTime(DateTime->now);
    return $self->plurks;
}

=head2 karma

    return user's karma, or specify user => 'who'

=cut

sub karma {
    my ($self, %args) = @_;
    return $self->get_public_profile($args{user})->user_info->karma if $args{user};
    return 0;
    # TODO: if authorized, return own karma, otherwise fail?
    #return $self->own_profile->user_info->karma;
}

=head2 follow

    return 1 if followed someone, 0 otherwise (see errormsg)

=cut

sub follow {
    my ($self, $user_id) = @_;

    # if input user nick_name instead of unique id
    $user_id = $self->_get_unique_id($user_id) if $user_id !~ m/^\d+$/;

    my $json_data = $self->callAPI(
        '/FriendsFans/setFollowing',
        user_id => $user_id,
        follow => 'true',
    );
    return $json_data if $self->raw_output;
    return 0 if $self->errormsg;
    return 1;
}

=head2 unfollow

    return 1 if unfollowed someone, 0 otherwise (see errormsg)

=cut

sub unfollow {
    my ($self, $user_id) = @_;

    # if input user nick_name instead of unique id
    $user_id = $self->_get_unique_id($user_id) if $user_id !~ m/^\d+$/;

    my $json_data = $self->callAPI(
        '/FriendsFans/setFollowing',
        user_id => $user_id,
        follow => 'false',
    );
    return $json_data if $self->raw_output;
    return 0 if $self->errormsg;
    return 1;
}

=head2 add_plurk

    add_plurk ($content, $qualifier %opt)
    %opt: limited_to, no_comment, lang

=cut

sub add_plurk {
    my ($self, $content, $qualifier, %opt) = @_;
    $qualifier //= 'says';
    my $json_data = $self->callAPI(
        '/Timeline/plurkAdd',
        qualifier => $qualifier,
        content => $content,
        %opt,
    );
    return $json_data if $self->raw_output;
    return Net::Plurk::Plurk->new($json_data) if !$self->errormsg;
    return ;
}

=head2 get_plurk

    get_plurk ($plurk_id)
    $plurk_id can be base 36 encoded, or not

=cut

sub get_plurk {
    my ($self, $plurk_id) = @_;
    use Math::Base36 ':all';
    $plurk_id = decode_base36($plurk_id) unless $plurk_id =~ m/^\d+$/m;
    my $json_data = $self->callAPI(
        '/Timeline/getPlurk',
        plurk_id => $plurk_id,
    );
    return $json_data if $self->raw_output;
    # XXX: didn't handle $json_data->{user}
    return Net::Plurk::Plurk->new($json_data->{plurk}) if !$self->errormsg;
    return ;
}

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-plurk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Plurk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Plurk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Plurk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Plurk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Plurk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Plurk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009~2011 Cheng-Lung Sung, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

no Moose;
__PACKAGE__->meta->make_immutable;
1; # End of Net::Plurk
