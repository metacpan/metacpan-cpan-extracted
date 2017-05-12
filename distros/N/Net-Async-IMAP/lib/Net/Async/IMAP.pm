package Net::Async::IMAP;
# ABSTRACT: Asynchronous IMAP handling
use strict;
use warnings;

our $VERSION = '0.004';

1;

__END__

=head1 NAME

Net::Async::IMAP::Client - asynchronous IMAP client based on L<Protocol::IMAP::Client> and L<IO::Async::Protocol::Stream>.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::IMAP;
 my $loop = IO::Async::Loop->new;
 my $imap = Net::Async::IMAP::Client->new(
 	loop => $loop,
	host => 'mailserver.com',
	service => 'imap',
	on_authenticated => sub {
		warn "login was successful";
		$loop->loop_stop;
	},
 );
 $imap->login(
	user => 'user@mailserver.com',
	pass => 'password',
 );
 $loop->loop_forever;

=head1 DESCRIPTION

See the L<Net::Async::IMAP::Client> or L<Net::Async::IMAP::Server> subclasses for more details.

=head1 AUTHOR

Tom Molesworth <net-async-imap@entitymodel.com>

with thanks to Paul Evans <leonerd@leonerd.co.uk> for the L<IO::Async> framework and
improvements to the initial implementation of this module.

=head1 LICENSE

Copyright Tom Molesworth 2010-2013. Licensed under the same terms as Perl itself.
