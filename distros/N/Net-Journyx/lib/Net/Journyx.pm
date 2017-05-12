package Net::Journyx;
use Moose;

our $VERSION = '0.12';

use Net::Journyx::SOAP;

has site => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => "The jxApi URL for your Journyx installation",
);

has username => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "User name",
    trigger       => sub {
        my $self = shift;
        $self->clear_session;
    },
);

has password => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "Password",
);

has session => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Session Key, retrieved from login() sent on all other calls',

    clearer       => 'clear_session',
    predicate     => 'has_session',
    lazy          => 1,
    default       => sub {
        my $self = shift;
        return $self->login;
    },
);

has wsdl => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => 'WSDL file to load',
);

has soap => (
    is            => 'rw',
    isa           => 'Net::Journyx::SOAP',
    documentation => 'Journyx SOAP API helper functions',
    lazy          => 1,
    default       => sub {
        my $self = shift;
        return new Net::Journyx::SOAP jx => $self;
    },
);

# This probably wants to be !ua but
# the soap object which is hopefully making the LWP requests
# for us
has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub {
        my $args = shift;

        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new( keep_alive => 30 );

        $ua->cookie_jar({});
        push @{ $ua->requests_redirectable }, qw( POST PUT DELETE );

        # Load the user's proxy settings from %ENV
        $ua->env_proxy;

        return $ua;
    },
);

has allows_utf8 => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has auto_logout => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 login

You don't need to call. Just provide username and password.
When some Journyx need a session key you'll be logged in.

=cut

sub login {
    my $self = shift;
    my %args = (
        keep_old_sessions => 1,
        @_
    );

    my $user = $self->username;
    my $pass = $self->password;

    confess "Unable to log in without a username and password."
        unless $user && $pass;

    return $self->soap->basic_call( login => %args, username => $user, pwd => $pass );
}

sub logout {
    my $self = shift;
    return 1 unless $self->has_session;
    my $response = $self->soap->basic_call( logout => @_ );
    $self->clear_session;
    return 1;
}

Net::Journyx::SOAP->install_basic('Net::Journyx' => qw(
    adminEmail
    adminName
    adminTelephone

    companyName
    customerNumber

    whoami

    uname
    hostname

    licensedHost
    licensedUsers

    installDate
    expirationDate

    apiVersion
    version
    versionCheck

    getCodeList
    getSubcodeList
    getSubsubcodeList
));

foreach my $type (qw(
    Project
    User
    Group
    Code
    Subcode
    Subsubcode
    Time
)) {
    my $class = 'Net::Journyx::'. $type;
    my $method = Net::Journyx::SOAP->nocapitals( $type );

    my $sub = eval <<END or die $@;
sub {
    my \$self = shift;
    require $class;
    return $class->new( jx => \$self );
}
END

    __PACKAGE__->meta->add_method($method => $sub);
}

sub DEMOLISH {
    my $self = shift;
    $self->logout if $self->auto_logout;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

Net::Journyx - interface to Journyx

=head1 SYNOPSIS

=head1 DESCRIPTION

Please see L<Net::Journyx::Tutorial> for now.

=head1 AUTHORS

Ruslan Zakirov, C<ruz@cpan.org>

=head1 CONTRIBUTORS

Shawn M Moore, C<sartak@bestpractical.com>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Best Practical Solutions.

This module is distributed under the same terms as Perl itself.

=cut
