#!/usr/bin/perl
use strict;
use utf8;

use Test::More tests => 9;
use Test::Exception;

use lib qw(../lib ..);
use Net::LastFM::Submission;
use LWP::UserAgent;

my $conf = require '.lastfmrc';

# diag "Testing Net::LastFM::Submission $Net::LastFM::Submission::VERSION, Perl $], $^X";

throws_ok { Net::LastFM::Submission->new                          } qr/Need user name/,   'empty new';
throws_ok { Net::LastFM::Submission->new(user => $conf->{'user'}) } qr/Need shared data/, 'shared dara';

my $standard = Net::LastFM::Submission->new(map { $_ => $conf->{$_} } 'user', 'password'); # standard
my $web      = Net::LastFM::Submission->new(map { $_ => $conf->{$_} } 'user', 'api_key', 'api_secret', 'session_key'); # web

ok $standard->{'auth'}->{'type'} eq 'standard', 'standard auth';
ok $web     ->{'auth'}->{'type'} eq 'web',      'web auth';

my $submit   = Net::LastFM::Submission->new(
	(map { $_ => $conf->{$_} } 'user', 'password'),
	
	'client_id'  => 'nls',
	'client_ver' => $Net::LastFM::Submission::VERSION,
	
	'enc'        => 'utf8',
	
	'ua'         => LWP::UserAgent->new(agent => 'nls', timeout => 5),
);

ok $submit->{'user'}->{'password'} eq $conf->{'password'}, 'check user password';

ok $submit->{'client'}->{'id' } eq 'nls', 'check client id';
ok $submit->{'client'}->{'ver'} eq $Net::LastFM::Submission::VERSION, 'check client version';

ok $submit->{'enc'} eq 'utf8', 'check encoding';

ok $submit->{'ua'}->agent eq 'nls', 'check ua';
