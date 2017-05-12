package Net::DNS::ValueDomain::DDNS;

use strict;
use base qw/Class::Accessor::Fast Class::ErrorHandler/;

use Carp;
use Readonly;

use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION = '0.02';

Readonly::Scalar my $URL        => 'dyn.value-domain.com/cgi-bin/dyn.fcg';
Readonly::Scalar my $SSL_PREFIX => 'ss1.xrea.com';

__PACKAGE__->mk_accessors(qw/ua/);

=head1 NAME

Net::DNS::ValueDomain::DDNS - Update your Value-Domain (https://www.value-domain.com/) DynamicDNS records.

=head1 SYNOPSIS

    use Net::DNS::ValueDomain::DDNS;
    
    # Normal usage
    my $ddns = Net::DNS::ValueDomain::DDNS->new;
    
    $ddns->update(
        domain   => 'example.com',
        password => '1234',
        host     => 'www',
        ip       => '127.0.0.1',
    );
    
    # Update multiple hosts on same IP
    my $ddns = Net::DNS::ValueDomain::DDNS->new(
        domain   => 'example.com',
        password => '1234',
        ip       => '127.0.0.1',
    );
    
    for my $host (qw/www mail */) {
        $ddns->update( host => $host ) or die $ddns->errstr;
    }

=head1 DESCRIPTION

This module help you to update your Value-Domain (https://www.value-domain.com/) DynamicDNS record(s).

=head1 METHODS

=head2 new( %config | \%config )

Create a new Object. All %config keys and values (except 'host' and 'domain') is kept and reused by update() function.

=cut

sub new {
    my $class  = shift;
    my $config = @_ > 1 ? {@_} : $_[0];

    my $self = bless {}, $class;

    $self->config($config) if $config;

    if ( !$self->config->{use_https} ) {
        eval { require Crypt::SSLeay; };
        if ($@) {
            carp
                "Require Crypt::SSLeay for ssl connection. If you don't want to do that, try new( use_https => 0 ).";
            $self->config->{use_https} = 0;
        }
    }

    $self->ua( LWP::UserAgent->new );

    $self;
}

=head2 config( %config | \%config )

set config veriables

=cut

sub config {
    my $self   = shift;
    my $config = @_ > 1 ? {@_} : $_[0];

    $self->{_config} ||= {};

    if ($config) {
        map { $self->{_config}->{$_} = $config->{$_} } keys %$config;
    }

    $self->{_config};
}

=head2 protocol

return used protocol name. 'http' or 'https'

=cut

sub protocol {
    shift->config->{use_https} ? 'https' : 'http';
}

=head2 update( %config | \%config )

Update your DynamicDNS record. %config parameters are:

=over 4

C<domain> - Domain name being updated. (Required)

C<password> - Value-Domain Dynamic DNS Password. (Required)

C<host> - Sub-domain name being updated. For example if your hostname is "www.example.com" you should set "www" here. (Optional)

C<ip> - The IP address to be updated. if empty, your current ip is used. (Optional)

=back

If something error has be occurred, return undef. Use errstr() method to get error message.

=cut

sub update {
    my $self = shift;
    my $args = @_ > 1 ? {@_} : $_[0];

    my $config = $self->config($args);

    croak 'domain is required'   unless $config->{domain};
    croak 'password is required' unless $config->{password};

    my $url =
        ( $config->{use_https} )
        ? "https://$SSL_PREFIX/$URL"
        : "http://$URL";

    my $parameters = {
        d => $config->{domain},
        p => $config->{password},
        h => $config->{host} || q{},
        i => $config->{ip} || q{},
    };
    my $query = '?';
    while ( my ( $k, $v ) = each %$parameters ) {
        $query .= "$k=$v&",;
    }

    my $res = $self->ua->get( $url . $query );

    unless ( $res->is_success ) {
        $self->error( $res->status_line );
        return;
    }

    unless ( $res->content =~ /status=0/ ) {
        my $error = $res->content;
        chomp $error;
        $self->error($error);
        return;
    }

    1;
}

=head2 errstr()

return last error.

=head1 ACCESSORS

=head2 ua

L<LWP::UserAgent> object.

=head1 AUTHOR

Daisuke Murase, E<lt>typester@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
