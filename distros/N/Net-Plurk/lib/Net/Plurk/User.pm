package Net::Plurk::User;
use Moose;

=head1 NAME

Net::Plurk::User 

=head1 SYNOPSIS

Foobar

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'has_profile_image' => (is => 'rw', isa => 'Int');
has 'avatar' => (is => 'rw', isa => 'Maybe[Int]');
# not_saying, single, married, divorced, engaged, in_relationship, complicated, widowed, open_relationship
has 'relationship' => (is => 'rw', isa => 'Str');
has 'full_name' => (is => 'rw', isa => 'Str');
has 'nick_name' => (is => 'rw', isa => 'Str');
has 'display_name' => (is => 'rw', isa => 'Str', lazy_build => 1);
has 'location' => (is => 'rw', isa => 'Str');
has 'timezone' => (is => 'rw', isa => 'Any');
has 'date_of_birth' => (is => 'rw', isa => 'Maybe[Str]');
has 'karma' => (is => 'rw', isa => 'Num', default => 0);
has 'gender' => (is => 'rw', isa => 'Int');
has 'recruited' => (is => 'rw', isa => 'Int');
has 'is_premium' => (is => 'ro', isa => 'Maybe[Object]', default => 'JSON::false');
has 'email_confirmed' => (is => 'ro', isa => 'Maybe[Object]', default => 'JSON::false');

sub _build_display_name {
    my $self = shift;
    $self->display_name($self->nick_name) unless $self->display_name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
