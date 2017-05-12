#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use lib grep { -d $_ } qw(./lib ../lib);
use REST::Consumer;
use Test::Resub qw(resub);

{
	package Mock::UserAgent;

	sub new { return bless {} }

	sub can { 1 }

	sub default_headers { shift->{default_headers} ||= HTTP::Headers->new }

	sub AUTOLOAD {
		my ($self, @args) = @_;
		my ($method) = our $AUTOLOAD =~ m{.*:(.*)};
		return if $method eq 'DESTROY';
		push @{$self->{$method}}, [@args];
	}
}

my $mock_user_agent = Mock::UserAgent->new;
my $rs = resub 'LWP::UserAgent::Paranoid::new', sub { undef }, call => 'forbidden';
my $consumer = REST::Consumer->new(
	ua    => $mock_user_agent,
	host  => '0.0.0.0',
	user_agent => 'retention-single-foot',
	keep_alive => 3864,
);

my $user_agent = $consumer->user_agent;
is( ref($user_agent), ref($mock_user_agent), 'we got back the expected user agent object' );

my $expected_header = HTTP::Headers->new; $expected_header->header(accept => 'application/json');
is_deeply( +{%$mock_user_agent}, +{
	default_headers => $expected_header,
	request_timeout => [[10]],
	agent => [['retention-single-foot']],
	keep_alive => [[3864]],
}, 'we configured our mock user agent as expected' ); # i.e. we didn't configure an LWP::UserAgent
