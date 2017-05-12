package Test::BDD::Infrastructure::Socket;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for tcp/udp/unix-socket tests
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval
	lookup_config );

use IO::Socket::INET;
use IO::Socket::UNIX;
use IO::Select;


Given qr/a (tcp|udp) connection to (\S+) on port (\d+) is made/, sub {
	my $proto = $1;
	my $host = $2;
	my $port = $3;

	S->{'socket'} = IO::Socket::INET->new(
		PeerAddr => $host,
		PeerPort => int $port,
		Proto    => $proto,
		timeout => 5,
	);
	if( ! defined S->{'socket'} ) {
		S->{'error'} = $@;
	}
};

Given qr/a connection on socket (\S+) is opened/, sub {
	my $path = $1;
	S->{'socket'} = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $path,
		timeout => 5,
	);
	if( ! defined S->{'socket'} ) {
		S->{'error'} = $@;
	}
};

Then qr/the (?:connection|socket) must be (?:successfully? )?enstablished/, sub {
	ok( defined S->{'socket'}, 'connection handle must be defined' );
	isa_ok( S->{'socket'}, 'IO::Socket');
};

Then qr/the (?:connection|socket) must fail(?: with (?:an error like )?(.*))?$/, sub {
	my $regex = $1;
	ok( ! defined S->{'socket'}, 'connection handle must be undefined' );
	if( defined $regex ) {
		like( S->{'error'}, qr/$regex/i, "error must match regex $regex");
	}
};

When qr/the (?:connection|socket) sends the line (.*)$/, sub {
	my $str = $1;
	S->{'socket'}->print( $str."\n" );
};
When qr/the (?:connection|socket) sends an empty line$/, sub {
	S->{'socket'}->print( "\n" );
};

Then qr/the (?:connection|socket) must recieve an line like (.*)$/, sub {
	my $regex = $1;
	my $timeout = 5;
	my $select = IO::Select->new;
	$select->add( S->{'socket'});
	if( $select->can_read( $timeout ) ) {
		my $line = S->{'socket'}->getline;
		like( $line, qr/$regex/i, "recieved line must be like $regex");
	} else {
		fail("did not recieve a response within $timeout seconds.");
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Socket - cucumber step definitions for tcp/udp/unix-socket tests

=head1 VERSION

version 1.005

=head1 Synopsis

  Scenario: check openssh server
    Given a tcp connection to localhost on port 22 is made
    Then the connection must be successfully enstablished
    And the connection must recieve an line like ^SSH-2.0

  Scenario: Check connection to www.perl.org
    Given a tcp connection to www.perl.org on port 80 is made
    Then the connection must be successfully enstablished
    When the connection sends the line GET / HTTP/1.0
    And the connection sends the line Host: www.perl.org
    And the connection sends an empty line
    Then the connection must recieve an line like HTTP/1.1 301 Moved Permanently

=head1 Step definitions

First create a connection:

  Given a (tcp|udp) connection to <host> on port <port> is made
  Given a connection on socket <path> is opened

Check connection state:

  Then the (connection|socket) must be (successfully) enstablished/, sub {
  Then the (connection|socket) must fail ((with) an error like) <msg>

Send/recieve commands:

  When the (connection|socket) sends the line <text>
  When the (connection|socket) sends an empty line
  Then the (connection|socket) must recieve an line like <regex>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
