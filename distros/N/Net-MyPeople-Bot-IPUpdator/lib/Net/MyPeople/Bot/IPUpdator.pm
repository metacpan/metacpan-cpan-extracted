package Net::MyPeople::Bot::IPUpdator;
use Moose;
use namespace::autoclean;
use WWW::Mechanize;
use Log::Log4perl qw(:easy);
use LWP::Simple;
Log::Log4perl->easy_init($ERROR);

# ABSTRACT: Update server IP address setting for MyPeople Bot API. 

our $VERSION = '0.002'; # VERSION

has myip_url => (is=>'rw', default=>sub{ [qw(http://mabook.com:8080/myip http://ifconfig.me/ip )]; });
has daum_id => (is=>'rw');
has daum_pw => (is=>'rw');

our $API_SETTING = 'http://dna.daum.net/myapi/authapi/mypeople';

sub BUILD{
	my $self = shift;
	if( ref($self->myip_url) eq '' ){
		$self->myip_url([$self->myip_url]);
	}
}

sub update{
	my $self = shift;
	my $ip = shift;

	my $mech = WWW::Mechanize->new;
	$mech->get($API_SETTING);

	my $res = $mech->submit_form(
		form_name=>'loginform',
		fields => {
			id=>$self->daum_id,
			pw=>$self->daum_pw,
			securityLevel=>1,
		},
	);
	unless( $res->header('x-daumlogin-error') =~ /^200/ ){
		ERROR 'Daum Login Fail';
		return 0;
	}

	$mech->get($API_SETTING);
	my $link = $mech->find_link( url_regex=>qr@/myapi/authapi/mypeople/.+/modify@ );
	unless( $link ){
		ERROR 'No registered bot.';
		return 0;
	}

	DEBUG $link->url_abs;
	$res = $mech->get($link->url_abs);

	unless( $ip ){
		$ip = $self->myip;
	}
	DEBUG "MY IP : $ip";

	$res = $mech->submit_form(
		form_name=>'form_auth_new',
		fields => {
			bot_ip=>$ip,
			chkPurpose=>'on',
		});

	DEBUG $res->decoded_content;
	return $ip;
}

sub myip{
	my $self = shift;
	foreach my $myip_url (@{$self->myip_url}){
		next unless $myip_url;
		DEBUG 'try to get my IP from '.$myip_url;
		my $ip = get($myip_url);
		return $ip if $ip;	
	}
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::MyPeople::Bot::IPUpdator - Update server IP address setting for MyPeople Bot API. 

=head1 VERSION

version 0.002

=head1 SYNOPSIS

	use Net::MyPeople::Bot::IPUpdator;

	use Log::Log4perl qw(:easy);
	Log::Log4perl->easy_init($DEBUG); # You can see all logs.

	my $upd = Net::MyPeople::Bot::IPUpdator->new(daum_id=>$daumid,daum_pw=>$daumpw);
	#my $upd = Net::MyPeople::Bot::IPUpdator->new(daum_id=>$daumid,daum_pw=>$daumpw, myip_url=>['http://GET_MY_IPADDR_URL']);
	my $nowip = $upd->update($ip);
	if( $nowip ){ # OK
		print "IPADDR is updated to $nowip\n";
		print "OK\n";
	}
	else{
		print "FAIL\n";
	}

or

	$ mypeople_bot_ipupdate DAUMID DAUMPW IPADDR

=head1 SEE ALSO

=over

=item * 

L<Net::MyPeople::Bot>

=item *

MyPeople : L<https://mypeople.daum.net/mypeople/web/main.do>

=item *

MyPeople Bot API Home : L<http://dna.daum.net/apis/mypeople>

=item *

MyPeople Bot API Buffer Service : L<http://mabook.com:8080/>

=back

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
