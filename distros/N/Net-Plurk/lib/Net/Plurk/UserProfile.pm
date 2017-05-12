package Net::Plurk::UserProfile;
use Moose;
use Moose::Util::TypeConstraints;
use Net::Plurk::User;

=head1 NAME

Net::Plurk::UserProfile 

=head1 SYNOPSIS

Foobar

=cut

subtype 'My::Net::Plurk::User' => as class_type('Net::Plurk::User');
coerce 'My::Net::Plurk::User'
    => from 'Net::Plurk::User'
        => via { Net::Plurk::User->new( $_ ) }
    => from 'HashRef'
        => via { Net::Plurk::User->new( $_ ) };

has 'friends_count' => (is => 'ro', isa => 'Int');
has 'user_info' => (is => 'ro', isa => 'My::Net::Plurk::User', coerce => 1);
has 'alerts_count' => (is => 'ro', isa => 'Int');
has 'fans_count' => (is => 'ro', isa => 'Int');
has 'unread_count' => (is => 'ro', isa => 'Int');
has 'plurks_users' => (is => 'ro', isa => 'HashRef');
has 'privacy' => (is => 'ro', isa => enum([qw[ world only_friends only_me ]]));
#has 'plurks' => (is => 'ro', isa => 'ArrayRef[Net::Plurk::PlurkContent]');
has 'plurks' => (is => 'ro', isa => 'ArrayRef');
has 'nick_name' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_nick_name {
    my $self = shift;
    return $self->user_info->nick_name;
}

no Moose::Util::TypeConstraints;
package Net::Plurk::PublicUserProfile;
use Moose;

extends 'Net::Plurk::UserProfile';

has 'are_friends' => (is => 'ro', isa => 'Maybe[Object]', default => 'JSON::false');
has 'is_fan' => (is => 'ro', isa => 'Maybe[Object]', default => 'JSON::false');
has 'is_following' => (is => 'ro', isa => 'Maybe[Object]', default => 'JSON::false');

no Moose;
__PACKAGE__->meta->make_immutable;
1;
