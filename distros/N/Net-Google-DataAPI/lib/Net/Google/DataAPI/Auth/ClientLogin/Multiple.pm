package Net::Google::DataAPI::Auth::ClientLogin::Multiple;
use Any::Moose;
use Net::Google::AuthSub;
use Text::Glob;
with 'Net::Google::DataAPI::Role::Auth';

our $VERSION = '0.05';

has account_type => ( is => 'ro', isa => 'Str', required => 1, default => 'HOSTED_OR_GOOGLE' );
has source   => ( is => 'ro', isa => 'Str', required => 1, default => __PACKAGE__ );
has username => ( is => 'ro', isa => 'Str', required => 1 );
has password => ( is => 'ro', isa => 'Str', required => 1 );
has services => ( is => 'ro', isa => 'HashRef', required => 1 );
has tokens => ( is => 'rw', isa => 'HashRef', default => sub { +{} });

sub sign_request {
    my ($self, $req, $host) = @_;
    $host ||= $req->uri->host;
    $self->tokens->{$host} ||= $self->_get_auth_params($host);
    $req->header(@{$self->tokens->{$host}});
    return $req;
}

sub _get_auth_params {
    my ($self, $host) = @_;
    my $service = $self->services->{$host};
    unless ($service) {
        for my $s (grep {$_ =~ m/\*/} keys %{$self->services}) {
            Text::Glob::match_glob($s, $host)
                and $service = $self->services->{$s} and last;
        }
    }
    $service or confess "service for $host not defined";
    my $authsub = Net::Google::AuthSub->new(
        source      => $self->source,
        service     => $service,
        accountType => $self->account_type,
        _compat     => {uncuddled_auth => 1}, #to export docs
    );
    my $res = $authsub->login(
        $self->username,
        $self->password,
    );
    $res->is_success or confess "login for $host failed";
    return [ $authsub->auth_params ];
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DataAPI::Auth::ClientLogin::Multiple - keeps and sings auth_params for multiple Google Data API domains

=head1 SYNOPSIS

  use Net::Google::DataAPI::Auth::ClientLogin::Multiple;

  my $auth = Net::Google::DataAPI::Auth::ClientLogin::Multiple->new(
    username => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
    services => {
        'docs.google.com' => 'writely',
        'spreadsheets.google.com' => 'wise',
    }
  );
  my $req = HTTP::Request->new(
    'GET' => 'https://docs.google.com/feeds/default/private/full'
  );
  $auth->sign_request($req);
  # sets $req Authorization header

  $auth->sign_request($req, 'spreadsheets.google.com');
  # set authorization header for 'spreadsheets.google.com', not for 'docs.google.com'.

=head1 DESCRIPTION

This module keeps and sings auth_params for multiple google Data API domains.

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::AuthSub>

L<Net::Google::DataAPI>

L<http://code.google.com/intl/en/apis/accounts/docs/AuthForInstalledApps.html>

L<http://code.google.com/intl/en/apis/gdata/faq.html#clientlogin>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
