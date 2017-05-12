package Plack::Middleware::GepokX::ModSSL;

use 5.010;
use strict 0 qw(vars subs refs);

use base 0 qw(Plack::Middleware);
use Plack::Util::Accessor qw(vars);

use Crypt::X509 0 qw(); # ridiculous exports
use DateTime 0 qw();
use MIME::Base64 0 qw(decode_base64);
use Net::SSLeay 0 qw();

my $__use_these_too = q(
use Gepok 0.20 qw();
use Plack 0 qw();
);

BEGIN {
	$Plack::Middleware::GepokX::ModSSL::AUTHORITY = 'cpan:TOBYINK';
	$Plack::Middleware::GepokX::ModSSL::VERSION   = '0.002';
}

my %PROTO = (
	0x0002 => 'SSLv2',
	0x0300 => 'SSLv3',
	0x0301 => 'TLSv1',
	0xFEFF => 'DTLSv1',
);

our %KNOWN = (
	SSL_CLIENT_VERIFY     => sub {
		my $r = Net::SSLeay::get_verify_result($_->_get_ssl_object);
		$_->peer_certificate ? ($r==0?'SUCCESS':'FAILED') : 'NONE'
	},
	SSL_CLIENT_CERT       => sub {
		$_->peer_certificate ? Net::SSLeay::PEM_get_string_X509($_->peer_certificate) : ''
	},
	SSL_CLIENT_V_START    => sub { DateTime->from_epoch(epoch => _CX(@_)->not_before)->strftime('%b %d %T %Y %Z') },
	SSL_CLIENT_V_END      => sub { DateTime->from_epoch(epoch => _CX(@_)->not_after)->strftime('%b %d %T %Y %Z') },
	SSL_CLIENT_S_DN_CN    => sub { _CX(@_)->subject_cn },
	SSL_CLIENT_S_DN_Email => sub { _CX(@_)->subject_email },
	SSL_CLIENT_S_DN_O     => sub { _CX(@_)->subject_org },
	SSL_CLIENT_S_DN_L     => sub { _CX(@_)->subject_locality },
	SSL_CLIENT_S_DN_ST    => sub { _CX(@_)->subject_state },
	SSL_CLIENT_S_DN_C     => sub { _CX(@_)->subject_country },
	SSL_CLIENT_I_DN_CN    => sub { _CX(@_)->issuer_cn },
	SSL_CLIENT_I_DN_Email => sub { _CX(@_)->issuer_email },
	SSL_CLIENT_I_DN_O     => sub { _CX(@_)->issuer_org },
	SSL_CLIENT_I_DN_L     => sub { _CX(@_)->issuer_locality },
	SSL_CLIENT_I_DN_ST    => sub { _CX(@_)->issuer_state },
	SSL_CLIENT_I_DN_C     => sub { _CX(@_)->issuer_country },
	SSL_CLIENT_M_SERIAL   => sub { _CX(@_)->serial },
	SSL_CLIENT_M_VERSION  => sub { _CX(@_)->version },
	SSL_CIPHER            => sub { $_->get_cipher },
	SSL_CIPHER_USEKEYSIZE => sub { Net::SSLeay::get_cipher_bits($_->_get_ssl_object) },
	SSL_PROTOCOL          => sub { my $p = Net::SSLeay::version($_->_get_ssl_object); $PROTO{$p} // $p },
	SSL_CLIENT_I_DN       => sub {
		my $cx = _CX(@_);
		sprintf(
			'/C=%s/ST=%s/L=%s/O=%s/CN=%s/emailAddress=%s',
			$cx->issuer_country,
			$cx->issuer_state,
			$cx->issuer_locality,
			$cx->issuer_org,
			$cx->issuer_cn,
			$cx->issuer_email,
		);
	},
	SSL_CLIENT_S_DN       => sub {
		my $cx = _CX(@_);
		sprintf(
			'/C=%s/ST=%s/L=%s/O=%s/CN=%s/emailAddress=%s',
			$cx->subject_country,
			$cx->subject_state,
			$cx->subject_locality,
			$cx->subject_org,
			$cx->subject_cn,
			$cx->subject_email,
		);
	},
);

sub all
{
	return keys %KNOWN;
}

sub _CX
{
	my ($self, $env) = @_;
	$env->{_CRYPTX509_} //= 
		Crypt::X509->new(
			cert => decode_base64(do {
				local $_ = $env->{'gepok.socket'};
				my $pem = $KNOWN{SSL_CLIENT_CERT}->($self, $env);
				$pem =~ s/-----([^-]+?)-----//g;
				$pem;
			})
		);
	return $env->{_CRYPTX509_};
}

sub call
{
	my ($self, $env) = @_;
	
	if ($env->{HTTPS} and exists $env->{'gepok.socket'})
	{
		for my $var (@{ $self->vars // [] })
		{
			die "unknown var: $var" unless $KNOWN{$var};
			local $_ = $env->{'gepok.socket'};
			$env->{$var} //= $KNOWN{$var}->($self, $env);
		}
	}
	
	delete $env->{_CRYPTX509_};
	$self->app->($env);
}

__PACKAGE__
__END__

=head1 NAME

Plack::Middleware::GepokX::ModSSL - roughly compatible with Plack::Middleware::Apache2::ModSSL

=head1 SYNOPSIS

 builder
 {
     enable "GepokX::ModSSL",
         vars => [ Plack::Middleware::GepokX::ModSSL->all ];
     $app;
 };

=head1 DESCRIPTION

This middleware attempts to recreate for Gepok, some
of the SSL information which Apache's mod_ssl would
put into the Plack C<< $env >> hashref.

It supports the following variables, as defined by
L<http://httpd.apache.org/docs/2.0/mod/mod_ssl.html>.

=over

=item * C<< SSL_CIPHER >>

=item * C<< SSL_CIPHER_USEKEYSIZE >>

=item * C<< SSL_CLIENT_CERT >>

=item * C<< SSL_CLIENT_I_DN >>

=item * C<< SSL_CLIENT_I_DN_C >>

=item * C<< SSL_CLIENT_I_DN_CN >>

=item * C<< SSL_CLIENT_I_DN_Email >>

=item * C<< SSL_CLIENT_I_DN_L >>

=item * C<< SSL_CLIENT_I_DN_O >>

=item * C<< SSL_CLIENT_I_DN_ST >>

=item * C<< SSL_CLIENT_M_SERIAL >>

=item * C<< SSL_CLIENT_M_VERSION >>

=item * C<< SSL_CLIENT_S_DN >>

=item * C<< SSL_CLIENT_S_DN_C >>

=item * C<< SSL_CLIENT_S_DN_CN >>

=item * C<< SSL_CLIENT_S_DN_Email >>

=item * C<< SSL_CLIENT_S_DN_L >>

=item * C<< SSL_CLIENT_S_DN_O >>

=item * C<< SSL_CLIENT_S_DN_ST >>

=item * C<< SSL_CLIENT_VERIFY >>

=item * C<< SSL_CLIENT_V_END >>

=item * C<< SSL_CLIENT_V_START >>

=item * C<< SSL_PROTOCOL >>

=back

Nothing is done by default. You need to tell the module which
variables you want:

 builder
 {
     enable "GepokX::ModSSL",
         vars => [qw( SSL_CIPHER SSL_CIPHER_USEKEYSIZE )];
     $app;
 };

If you want it all, then:

 builder
 {
     enable "GepokX::ModSSL",
         vars => [ Plack::Middleware::GepokX::ModSSL->all ];
     $app;
 };

Though bear in mind that some variables are more computationally
expensive than others. Cheap ones are: C<SSL_PROTOCOL>, C<SSL_CIPHER>,
C<SSL_CIPHER_USEKEYSIZE>, C<SSL_CLIENT_CERT>, C<SSL_CLIENT_VERIFY>.

=begin private

=item call

=item all

=end private

=head1 BUGS

Please report bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Plack-Middleware-GepokX-ModSSL>.

=head1 SEE ALSO

L<Plack>,
L<Gepok> (version 0.20 required),
L<Plack::Middleware::Apache2::ModSSL>.

L<http://httpd.apache.org/docs/2.0/mod/mod_ssl.html>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
