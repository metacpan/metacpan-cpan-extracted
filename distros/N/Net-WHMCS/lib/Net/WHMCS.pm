package Net::WHMCS;
$Net::WHMCS::VERSION = '0.08';

# ABSTRACT: interface to the WHMCS billing and support system

use Moo;
use Carp 'croak';

has 'WHMCS_URL'      => ( is => 'rw', required => 1 );
has 'WHMCS_USERNAME' => ( is => 'rw', required => 1 );
has 'WHMCS_PASSWORD' => ( is => 'rw', required => 1 );
has 'WHMCS_API_ACCESSKEY' => ( is => 'rw' );

sub _build_args {
    my ($self) = @_;

    my $args = { WHMCS_URL => $self->WHMCS_URL };
    $args->{WHMCS_USERNAME}      = $self->WHMCS_USERNAME;
    $args->{WHMCS_PASSWORD}      = $self->WHMCS_PASSWORD;
    $args->{WHMCS_API_ACCESSKEY} = $self->WHMCS_API_ACCESSKEY
      if $self->WHMCS_API_ACCESSKEY;

    return $args;
}

use Net::WHMCS::Client;
use Net::WHMCS::Order;
use Net::WHMCS::Support;
use Net::WHMCS::Miscellaneous;

has 'client' => ( is => 'lazy' );

sub _build_client {
    Net::WHMCS::Client->new( (shift)->_build_args() );
}

has 'order' => ( is => 'lazy' );

sub _build_order {
    Net::WHMCS::Order->new( (shift)->_build_args() );
}

has 'support' => ( is => 'lazy' );

sub _build_support {
    Net::WHMCS::Support->new( (shift)->_build_args() );
}

has 'misc' => ( is => 'lazy' );

sub _build_misc {
    Net::WHMCS::Miscellaneous->new( (shift)->_build_args() );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS - interface to the WHMCS billing and support system

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	use Net::WHMCS;
	use Digest::MD5 'md5_hex';

	my $whmcs = Net::WHMCS->new(
		WHMCS_URL => 'http://example.com/whmcs/includes/api.php',
		WHMCS_USERNAME => 'admin_user',
		WHMCS_PASSWORD => md5_hex('admin_pass'),
		# WHMCS_API_ACCESSKEY => 'faylandtest', # optional, to pass the IP, http://docs.whmcs.com/API:Access_Keys
	);

	my $user = $whmcs->client->getclientsdetails({
		clientid => 1,
		stats => 'true',
	});

=head1 DESCRIPTION

L<http://docs.whmcs.com/API#Internal_API>

NOTE: the modules are incomplete. please feel free to fork on github L<https://github.com/fayland/perl-Net-WHMCS> and send me pull requests.

=head1 PARTS

=head2 client

	my $user = $whmcs->client->getclientsdetails({
		clientid => 1,
		stats => 'true',
	});

L<Net::WHMCS::Client>

=head2 support

	$whmcs->support->openticket({
		clientid => 1,
		deptid => 1,
		subject => 'subject',
		message => 'message'
	});

L<Net::WHMCS::Support>

=head2 order

	$whmcs->order->addorder({
		clientid => 1,
		pid => 1,
		...
	});

L<Net::WHMCS::Order>

=head2 misc

	$whmcs->misc->addproduct({
		type => 'other',
		gid => 1,
		name => 'Sample Product',
		paytype => 'recurring',
		'pricing[1][monthly]' => '5.00',
		'pricing[1][annually]' => '50.00',
		...
	});

L<Net::WHMCS::Miscellaneous>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
