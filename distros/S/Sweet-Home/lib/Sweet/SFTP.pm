package Sweet::SFTP;
use Moose;

use MooseX::AttributeShortcuts;
use Carp;
use Net::SFTP::Foreign;
use Try::Tiny;

use namespace::autoclean;

has hostname => (
    is      => 'lazy',
    isa     => 'Str',
);

has username => (
    is      => 'lazy',
    isa     => 'Str',
);

has password => (
    is      => 'lazy',
    isa     => 'Str',
);

has session => (
    is      => 'lazy',
    isa     => 'Net::SFTP::Foreign',
);

sub _build_session {
    my $self = shift;

    my $hostname = $self->hostname;
    my $username = $self->username;
    my $password = $self->password;

    my $session = try {
        Net::SFTP::Foreign->new(
            $hostname,
            user     => $username,
            password => $password,
            autodie  => 1,
        );
    }
    catch {
        croak "Couldn't open SFTP session: $_";
    };

    return $session;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Sweet::SFTP

=head1 SYNOPSIS

    use Sweet::SFTP;

    my $sftp = Sweet::SFTP->new(
        hostname => 'sftp.example.org',
        username => 'foo',
        password => 'secr3t',
    );

    my $session = $sftp->session;

=head1 ATTRIBUTES

=head2 session

Instance of L<Net::SFTP::Foreign>.

=head2 hostname

Has builder C<_build_hostname>.

=head2 username

Has builder C<_build_username>.

=head2 password

Has builder C<_build_password>.

=head1 PRIVATE METHODS

=head2 _build_session

The L</session> builder. To be overridden in subclasses, if needed.

=cut

