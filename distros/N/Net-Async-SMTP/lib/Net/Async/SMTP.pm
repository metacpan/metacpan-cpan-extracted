package Net::Async::SMTP;
# ABSTRACT: SMTP support for IO::Async
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Net::Async::SMTP - email sending with IO::Async

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use IO::Async::Loop;
 use Net::Async::SMTP::Client;
 use Email::Simple;
 my $email = Email::Simple->create(
 	header => [
 		From    => 'someone@example.com',
 		To      => 'other@example.com',
 		Subject => 'NaSMTP test',
 	],
 	attributes => {
 		encoding => "8bitmime",
 		charset  => "UTF-8",
 	},
 	body_str => '... text ...',
 );
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $smtp = Net::Async::SMTP::Client->new(
 		domain => 'example.com',
 	)
 );
 $smtp->connected->then(sub {
 	$smtp->login(
 		user => '...',
 		pass => '...',
 	)
 })->then(sub {
 	$smtp->send(
 		to   => 'someone@example.com',
 		from => 'other@example.com',
 		data => $email->as_string,
 	)
 })->get;

=head1 DESCRIPTION

Provides basic email sending capability for L<IO::Async>, using
the L<Protocol::SMTP> implementation.

See L<Protocol::SMTP/DESCRIPTION> for a list of supported features
and usage instructions.

This class does nothing - use L<Net::Async::SMTP::Client> for
sending email.

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
