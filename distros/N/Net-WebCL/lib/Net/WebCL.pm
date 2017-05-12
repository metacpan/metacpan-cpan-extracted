package Net::WebCL;
use strict;
use warnings;
use HTTP::Request::Common qw/GET POST/;
use HTTP::Cookies;
use base qw/LWP::UserAgent/;

our $VERSION = '0.03';

sub new{
	my $this = shift;
	my $self = new LWP::UserAgent;
	$self->cookie_jar({});
	$self->ssl_opts(verify_hostname => 0);
	return bless($self,$this);
}

sub req{
	my ($self,$m,$u,$d,$p) = @_;
	my $req;
	if($m =~ /GET/i){
		$req = GET($u . '?' . join('&',map{$_ = $_ . '=' . $d->{$_};$_} keys %{$d}));
	}
	elsif($m =~ /POST/i){
		$req = POST($u,$d);
	}
	else{
		return;
	}

	if($p){
		my $proxy = '';
		if($p->{proxy_user}){
			$proxy = $p->{proxy_user} . ':' . $p->{proxy_password} . '@';
		}
		$proxy = 'http://' . $proxy . $p->{proxy_host} . ':' . $p->{proxy_port} . '/';
		$self->proxy($p->{proxy_type},$proxy);
	}
	return $self->request($req);
}
1;
__END__

=head1 NAME

Net::WebCL - LWP::UserAgent base easy web access module.

=head1 SYNOPSIS

 use Net::WebCL;
 my $ua = new Net::WebCL;
 my $res = $ua->req(
   method,
   url,
   send_data,
   proxy_info
 );
 print $res->content;

=head1 DESCRIPTION

This module is LWP::UserAgent base easy web access module.
Support Protocol is HTTP and HTTPS.
Support Method is GET and POST.
Cookie is supoorted.
Proxy is supported.

=head1 Usage

 use Net::WebCL;
 my $ua = new Net::WebCL;
 my $res = $ua->req(
   method,
   url,
   send_data,
   proxy_info
 );
 print $res->content;

 method: GET/POST
 url: Example is 'http://search.cpan.org'
 send_data: This parameter is Hash Ref.
   my $proxy_data = {
     proxy_type => [qw/http https/],
     proxy_host => 'proxy.hogehoge.localdomain',
     proxy_port => 8080,
     proxy_user => 'foo',
     proxy_password => 'bar'
   );

=head1 Copyright

Kazunori Minoda (c)2012

=cut
