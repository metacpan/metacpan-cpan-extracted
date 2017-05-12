package Prosody::Mod::Data::Access;
BEGIN {
  $Prosody::Mod::Data::Access::AUTHORITY = 'cpan:GETTY';
}
{
  $Prosody::Mod::Data::Access::VERSION = '0.007';
}

use Moose;
use LWP::UserAgent;
use JSON;
use Encode;
use HTTP::Request;

our $VERSION ||= '0.0development';

has hostname => (
	is => 'ro',
	isa => 'Str',
	lazy_build => 1,
);

sub _build_hostname { 'localhost' }

has port => (
	is => 'ro',
	isa => 'Int',
	lazy_build => 1,
);

sub _build_port { '5280' }

sub first_path_part { 'data' }

has jid => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has password => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

sub http_agent { __PACKAGE__.'/'.$VERSION }

has _useragent => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy_build => 1,
);

sub _build__useragent {
	my ( $self ) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->agent($self->http_agent);
	return $ua;
}

has base_path => (
	is => 'ro',
	isa => 'Str',
	lazy_build => 1,
);

sub _build_base_path {
	my ( $self ) = @_;
	my @jid_parts = split('@',$self->jid);
	return 'http://'.$self->hostname.':'.$self->port.'/'.$self->first_path_part.'/'.$jid_parts[1].'/';
}

sub get {
	my ( $self, $user, $store ) = @_;
	$store = 'accounts' if !$store;
	my $url = $self->base_path.$user.'/'.$store.'/json';
	my $req = HTTP::Request->new('GET',$url);
	$req->authorization_basic($self->jid,$self->password);
	my $res = $self->_useragent->request($req);
	if ($res->is_success) {
		return decode_json(encode('utf8', $res->content));
	} else {
		die __PACKAGE__." error on HTTP request: ".$res->status_line;
	}
}

sub put {
	my ( $self, $user, $store, $data ) = @_;
	$store = 'accounts' if !$store;
	my @jid_parts = split('@',$self->jid);
	my $url = $self->base_path.$user.'/'.$store.'/lua';
	my $req = HTTP::Request->new('PUT',$url);
	$req->content(encode_json($data));
	$req->header('Content-Type' => 'application/json');
	$req->authorization_basic($self->jid,$self->password);
	my $res = $self->_useragent->request($req);
	if ($res->is_success) {
		return 1;
	} else {
		die __PACKAGE__." error on HTTP request: ".$res->status_line;
	}
}

1;
__END__
=pod

=head1 NAME

Prosody::Mod::Data::Access

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

