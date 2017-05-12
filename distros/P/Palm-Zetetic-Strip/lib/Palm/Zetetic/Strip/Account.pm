package Palm::Zetetic::Strip::Account;

use strict;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Palm::Raw);
$VERSION = "1.02";

=head1 NAME

Palm::Zetetic::Strip::Account - An immutable account object

=head1 SYNOPSIS

  use Palm::Zetetic::Strip;

  # Create and load a new Palm::Zetetic::Strip object

  @accounts = $strip->get_accounts();
  $system = $accounts[0]->get_system();
  $username = $accounts[0]->get_username();
  $password = $accounts[0]->get_password();
  $system_id = $accouns[0]->get_system_id();
  $comment = $accounts[0]->get_comment();

=head1 DESCRIPTION

This is an immutable data object that represents an account.  A
Palm::Zetetic::Strip(3) object is a factory for account objects.

=head1 METHODS

=cut

sub new
{
    my $class = shift;
    my (%args) = @_;
    my $self = {};

    bless $self, $class;
    $self->{system}     = "";
    $self->{username}   = "";
    $self->{password}   = "";
    $self->{system_id}  = "";
    $self->{comment}    = "";

    $self->{system}     = $args{system} if defined($args{system});
    $self->{username}   = $args{username} if defined($args{username});
    $self->{password}   = $args{password} if defined($args{password});
    $self->{system_id}  = $args{system_id} if defined($args{system_id});
    $self->{comment}    = $args{comment} if defined($args{comment});
    return $self;
}

=head2 get_system

  $system = $account->get_system();

Returns the system name.  B<Note:> this has nothing to do with the
name of a Palm::Zetetic::Strip::System(3) object.  This is what the
user enters as a system name.

=cut

sub get_system
{
    my ($self) = @_;
    return $self->{system};
}

=head2 get_username

  $username = $account->get_username();

Returns the username.

=cut

sub get_username
{
    my ($self) = @_;
    return $self->{username};
}

=head2 get_password

  $password = $account->get_password();

Returns the password.

=cut

sub get_password
{
    my ($self) = @_;
    return $self->{password};
}

=head2 get_system_id

  $system_id = $account->get_system_id();

Returns the system ID.  This can be used to lookup a
Palm::Zetetic::Strip::System(3) object.

=cut

sub get_system_id
{
    my ($self) = @_;
    return $self->{system_id};
}

=head2 get_comment

  $comment = $account->get_comment();

Returns the comment.

=cut

sub get_comment
{
    my ($self) = @_;
    return $self->{comment};
}

1;

__END__

=head1 SEE ALSO

Palm::Zetetic::Strip(3), Palm::Zetetic::Strip::System(3)

=head1 AUTHOR

Dave Dribin
