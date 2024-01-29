package Protocol::Database::PostgreSQL::Backend::AuthenticationRequest;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::AuthenticationRequest - an authentication request message

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub type { 'authentication_request' }

sub auth_type { shift->{auth_type} }
sub password_type { shift->{password_type} }
sub password_salt { shift->{password_salt} }
sub password_rounds { shift->{password_rounds} }
sub password_nonce { shift->{password_nonce} }
sub server_first_message { shift->{server_first_message} }
sub server_signature { shift->{server_signature} }

sub new_from_message {
    my ($class, $msg) = @_;

    my (undef, undef, $auth_code, $data) = unpack('C1N1N1a*', $msg);
    my $auth_type = $Protocol::Database::PostgreSQL::AUTH_TYPE{$auth_code} or die "Invalid auth code $auth_code received";
    $log->tracef("Auth message [%s]", $auth_type);
    my %info = (
        auth_type => $auth_type,
    );
    if($auth_type eq 'AuthenticationMD5Password') {
        my ($salt) = unpack('a4', $data);
        $info{password_type} = 'md5';
        $info{password_salt} = $salt;
    } elsif($auth_type eq 'AuthenticationCleartextPassword') {
        $info{password_type} = 'plain';
    } elsif($auth_type eq 'AuthenticationOk') {
        # No action required
    } elsif($auth_type eq 'AuthenticationSASL') {
        my @methods = split /\0/, $data;
        $log->tracef('Have auth methods %s', \@methods);
        $info{password_mechanisms} = \@methods;
    } elsif($auth_type eq 'AuthenticationSASLContinue') {
        $log->tracef('Auth continue: %s', $data);
        my %data = map { /([rsi])=(.*)$/ } split /,/, $data;
        $log->tracef('Have parameters: %s', \%data);
        $info{password_rounds} = $data{i};
        $info{password_salt} = $data{s};
        $info{password_nonce} = $data{r};
        $info{server_first_message} = $data;
    } elsif($auth_type eq 'AuthenticationSASLFinal') {
        $log->tracef('Auth final %s', $data);
        my %data = map { /([v])=(.*)$/ } split /,/, $data;
        $log->tracef('Have parameters: %s', \%data);
        $info{server_signature} = $data{v};
    } else {
        die 'unknown auth thing here';
    }
    return $class->new(
        %info,
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

