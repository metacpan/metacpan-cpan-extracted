use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Plack-Middleware-SignedCookies>;
my $bt = q<https://github.com/ap/Plack-Middleware-SignedCookies/issues>;

our %META = (
	name        => 'Plack-Middleware-SignedCookies',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2020 },
	license     => 'perl_5',
	resources   => {
		license    => [ q<https://dev.perl.org/licenses/> ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
				Digest::SHA 0
				Plack::Middleware 0
				Plack::Util 0
				Plack::Util::Accessor 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
				Plack::Test 0
				HTTP::CookieJar::LWP 0
				HTTP::Request::Common 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
