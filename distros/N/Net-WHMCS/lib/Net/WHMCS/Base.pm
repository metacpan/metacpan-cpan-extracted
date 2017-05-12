package Net::WHMCS::Base;
$Net::WHMCS::Base::VERSION = '0.08';

# ABSTRACT: WHMCS API Role

use Moo::Role;
use Carp 'croak';
use LWP::UserAgent;
use JSON;

has 'WHMCS_URL'      => ( is => 'rw', required => 1 );
has 'WHMCS_USERNAME' => ( is => 'rw', required => 1 );
has 'WHMCS_PASSWORD' => ( is => 'rw', required => 1 );
has 'WHMCS_API_ACCESSKEY' => ( is => 'rw' );

has 'ua' => ( is => 'lazy' );

sub _build_ua {
    return LWP::UserAgent->new;
}

sub build_request {
    my ( $self, $params ) = @_;

    if ( not exists $params->{action} ) {
        croak "No API action set\n";
    }

    $params->{username}  = $self->WHMCS_USERNAME;
    $params->{password}  = $self->WHMCS_PASSWORD;
    $params->{accesskey} = $self->WHMCS_API_ACCESSKEY
      if $self->WHMCS_API_ACCESSKEY;

    $params->{responsetype} = 'json';

    my $resp = $self->ua->post( $self->WHMCS_URL, $params );
    return { result => 'error', message => $resp->status_line }
      unless $resp->is_success;

    # print Dumper(\$resp); use Data::Dumper;

    return decode_json( $resp->content );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS::Base - WHMCS API Role

=head1 VERSION

version 0.08

=head3 build_request

	with 'Net::WHMCS::Base';

	$self->build_request({
		action => 'getclientsdetails',
		clientid => 1,
		stats => 'true',
	})

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
