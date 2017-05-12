=head1 NAME

Net::TacacsPlus::Constants - Tacacs+ packet constants

=head1 SYNOPSIS

	use Net::TacacsPlus::Constants;

=head1 DESCRIPTION

This module will import tacacs+ packet constants defined in tac-rfc.1.78.txt + TAC_PLUS_HEADER_SIZE.

	TAC_PLUS_MAJOR_VER => 0xc,
	TAC_PLUS_MINOR_VER_DEFAULT => 0x0,
	TAC_PLUS_MINOR_VER_ONE => 0x1,

	TAC_PLUS_AUTHEN => 0x01, #(Authentication)
	TAC_PLUS_AUTHOR => 0x02, #(Authorization)
	TAC_PLUS_ACCT   => 0x03, #(Accounting)

	TAC_PLUS_UNENCRYPTED_FLAG => 0x01,
	TAC_PLUS_SINGLE_CONNECT_FLAG => 0x04,

	TAC_PLUS_AUTHEN_LOGIN    => 0x01,
	TAC_PLUS_AUTHEN_CHPASS   => 0x02,
	TAC_PLUS_AUTHEN_SENDPASS => 0x03, #(deprecated)
	TAC_PLUS_AUTHEN_SENDAUTH => 0x04,

	TAC_PLUS_PRIV_LVL_MAX   => 0x0f,
	TAC_PLUS_PRIV_LVL_ROOT  => 0x0f,
	TAC_PLUS_PRIV_LVL_USER  => 0x01,
	TAC_PLUS_PRIV_LVL_MIN   => 0x00,

	TAC_PLUS_AUTHEN_TYPE_ASCII      => 0x01,
	TAC_PLUS_AUTHEN_TYPE_PAP        => 0x02,
	TAC_PLUS_AUTHEN_TYPE_CHAP       => 0x03,
	TAC_PLUS_AUTHEN_TYPE_ARAP       => 0x04,
	TAC_PLUS_AUTHEN_TYPE_MSCHAP     => 0x05,

	TAC_PLUS_AUTHEN_SVC_NONE        => 0x00,
	TAC_PLUS_AUTHEN_SVC_LOGIN       => 0x01,
	TAC_PLUS_AUTHEN_SVC_ENABLE      => 0x02,
	TAC_PLUS_AUTHEN_SVC_PPP         => 0x03,
	TAC_PLUS_AUTHEN_SVC_ARAP        => 0x04,
	TAC_PLUS_AUTHEN_SVC_PT          => 0x05,
	TAC_PLUS_AUTHEN_SVC_RCMD        => 0x06,
	TAC_PLUS_AUTHEN_SVC_X25         => 0x07,
	TAC_PLUS_AUTHEN_SVC_NASI        => 0x08,
	TAC_PLUS_AUTHEN_SVC_FWPROXY     => 0x09,

	TAC_PLUS_AUTHEN_STATUS_PASS     => 0x01,
	TAC_PLUS_AUTHEN_STATUS_FAIL     => 0x02,
	TAC_PLUS_AUTHEN_STATUS_GETDATA  => 0x03,
	TAC_PLUS_AUTHEN_STATUS_GETUSER  => 0x04,
	TAC_PLUS_AUTHEN_STATUS_GETPASS  => 0x05,
	TAC_PLUS_AUTHEN_STATUS_RESTART  => 0x06,
	TAC_PLUS_AUTHEN_STATUS_ERROR    => 0x07,
	TAC_PLUS_AUTHEN_STATUS_FOLLOW   => 0x21,

	TAC_PLUS_AUTHEN_METH_NOT_SET    => 0x00,
	TAC_PLUS_AUTHEN_METH_NONE       => 0x01,
	TAC_PLUS_AUTHEN_METH_KRB5       => 0x02,
	TAC_PLUS_AUTHEN_METH_LINE       => 0x03,
	TAC_PLUS_AUTHEN_METH_ENABLE     => 0x04,
	TAC_PLUS_AUTHEN_METH_LOCAL      => 0x05,
	TAC_PLUS_AUTHEN_METH_TACACSPLUS => 0x06,

	TAC_PLUS_AUTHEN_METH_GUEST      => 0x08,
	TAC_PLUS_AUTHEN_METH_RADIUS     => 0x10,
	TAC_PLUS_AUTHEN_METH_KRB4       => 0x11,
	TAC_PLUS_AUTHEN_METH_RCMD       => 0x20,

	TAC_PLUS_AUTHOR_STATUS_PASS_ADD  => 0x01,
	TAC_PLUS_AUTHOR_STATUS_PASS_REPL => 0x02,
	TAC_PLUS_AUTHOR_STATUS_FAIL      => 0x10,
	TAC_PLUS_AUTHOR_STATUS_ERROR     => 0x11,
	TAC_PLUS_AUTHOR_STATUS_FOLLOW    => 0x21,

	TAC_PLUS_ACCT_FLAG_MORE          => 0x01, # deprecated
	TAC_PLUS_ACCT_FLAG_START         => 0x02,
	TAC_PLUS_ACCT_FLAG_STOP          => 0x04,
	TAC_PLUS_ACCT_FLAG_WATCHDOG      => 0x08,

	TAC_PLUS_ACCT_STATUS_SUCCESS     => 0x01,
	TAC_PLUS_ACCT_STATUS_ERROR       => 0x02,
	TAC_PLUS_ACCT_STATUS_FOLLOW      => 0x21,

	TAC_PLUS_HEADER_SIZE             => 12,


=head1 AUTHOR

Jozef Kutej E<lt>jkutej@cpan.orgE<gt>

Authorization and Accounting contributed by Rubio Vaughan E<lt>rubio@passim.netE<gt>

=head1 VERSION

1.03

=head1 SEE ALSO

tac-rfc.1.78.txt, Net::TacacsPlus::Client

=cut

package Net::TacacsPlus::Constants;

use strict;
use warnings;

our $VERSION = '1.10';

# constants from tac-rfc-1.78.txt + TAC_PLUS_HEADER_SIZE
my %tac_plus_const = (
	TAC_PLUS_MAJOR_VER => 0xc,
	TAC_PLUS_MINOR_VER_DEFAULT => 0x0,
	TAC_PLUS_MINOR_VER_ONE => 0x1,

	TAC_PLUS_AUTHEN => 0x01, #(Authentication)
	TAC_PLUS_AUTHOR => 0x02, #(Authorization)
	TAC_PLUS_ACCT   => 0x03, #(Accounting)

	TAC_PLUS_UNENCRYPTED_FLAG => 0x01,
	TAC_PLUS_SINGLE_CONNECT_FLAG => 0x04,

	TAC_PLUS_AUTHEN_LOGIN    => 0x01,
	TAC_PLUS_AUTHEN_CHPASS   => 0x02,
	TAC_PLUS_AUTHEN_SENDPASS => 0x03, #(deprecated)
	TAC_PLUS_AUTHEN_SENDAUTH => 0x04,

	TAC_PLUS_PRIV_LVL_MAX   => 0x0f,
	TAC_PLUS_PRIV_LVL_ROOT  => 0x0f,
	TAC_PLUS_PRIV_LVL_USER  => 0x01,
	TAC_PLUS_PRIV_LVL_MIN   => 0x00,

	TAC_PLUS_AUTHEN_TYPE_ASCII      => 0x01,
	TAC_PLUS_AUTHEN_TYPE_PAP        => 0x02,
	TAC_PLUS_AUTHEN_TYPE_CHAP       => 0x03,
	TAC_PLUS_AUTHEN_TYPE_ARAP       => 0x04,
	TAC_PLUS_AUTHEN_TYPE_MSCHAP     => 0x05,

	TAC_PLUS_AUTHEN_SVC_NONE        => 0x00,
	TAC_PLUS_AUTHEN_SVC_LOGIN       => 0x01,
	TAC_PLUS_AUTHEN_SVC_ENABLE      => 0x02,
	TAC_PLUS_AUTHEN_SVC_PPP         => 0x03,
	TAC_PLUS_AUTHEN_SVC_ARAP        => 0x04,
	TAC_PLUS_AUTHEN_SVC_PT          => 0x05,
	TAC_PLUS_AUTHEN_SVC_RCMD        => 0x06,
	TAC_PLUS_AUTHEN_SVC_X25         => 0x07,
	TAC_PLUS_AUTHEN_SVC_NASI        => 0x08,
	TAC_PLUS_AUTHEN_SVC_FWPROXY     => 0x09,

	TAC_PLUS_AUTHEN_STATUS_PASS     => 0x01,
	TAC_PLUS_AUTHEN_STATUS_FAIL     => 0x02,
	TAC_PLUS_AUTHEN_STATUS_GETDATA  => 0x03,
	TAC_PLUS_AUTHEN_STATUS_GETUSER  => 0x04,
	TAC_PLUS_AUTHEN_STATUS_GETPASS  => 0x05,
	TAC_PLUS_AUTHEN_STATUS_RESTART  => 0x06,
	TAC_PLUS_AUTHEN_STATUS_ERROR    => 0x07,
	TAC_PLUS_AUTHEN_STATUS_FOLLOW   => 0x21,

	TAC_PLUS_AUTHEN_METH_NOT_SET    => 0x00,
	TAC_PLUS_AUTHEN_METH_NONE       => 0x01,
	TAC_PLUS_AUTHEN_METH_KRB5       => 0x02,
	TAC_PLUS_AUTHEN_METH_LINE       => 0x03,
	TAC_PLUS_AUTHEN_METH_ENABLE     => 0x04,
	TAC_PLUS_AUTHEN_METH_LOCAL      => 0x05,
	TAC_PLUS_AUTHEN_METH_TACACSPLUS => 0x06,

	TAC_PLUS_AUTHEN_METH_GUEST      => 0x08,
	TAC_PLUS_AUTHEN_METH_RADIUS     => 0x10,
	TAC_PLUS_AUTHEN_METH_KRB4       => 0x11,
	TAC_PLUS_AUTHEN_METH_RCMD       => 0x20,

	TAC_PLUS_AUTHOR_STATUS_PASS_ADD  => 0x01,
	TAC_PLUS_AUTHOR_STATUS_PASS_REPL => 0x02,
	TAC_PLUS_AUTHOR_STATUS_FAIL      => 0x10,
	TAC_PLUS_AUTHOR_STATUS_ERROR     => 0x11,
	TAC_PLUS_AUTHOR_STATUS_FOLLOW    => 0x21,

	TAC_PLUS_ACCT_FLAG_MORE          => 0x01, # deprecated
	TAC_PLUS_ACCT_FLAG_START         => 0x02,
	TAC_PLUS_ACCT_FLAG_STOP          => 0x04,
	TAC_PLUS_ACCT_FLAG_WATCHDOG      => 0x08,

	TAC_PLUS_ACCT_STATUS_SUCCESS     => 0x01,
	TAC_PLUS_ACCT_STATUS_ERROR       => 0x02,
	TAC_PLUS_ACCT_STATUS_FOLLOW      => 0x21,

	TAC_PLUS_HEADER_SIZE             => 12,
);

for my $name (keys %tac_plus_const)
{
	my $scalar = $tac_plus_const{$name};
	$tac_plus_const{$name} = sub () { $scalar };
}

=head1 METHODS

=over 4

=item import()

This sub is called automaticaly. I loads the constants to caller namespace. I took idea for it from "use constant".

=cut

sub import {
	my $pkg = caller;

	foreach my $name (keys %tac_plus_const)
	{
		my $fullname="${pkg}::$name";

		do {
			no strict 'refs';
			*$fullname = $tac_plus_const{$name};
		}
	}
}

1;

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

