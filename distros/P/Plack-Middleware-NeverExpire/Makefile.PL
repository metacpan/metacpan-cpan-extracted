use 5.008001; use strict; use warnings;

my $sc = q<https://github.com/ap/Plack-Middleware-NeverExpire>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-Middleware-NeverExpire>;

our %META = (
	name        => 'Plack-Middleware-NeverExpire',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2015 },
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
				perl 5.008001
				Plack 0.9942
				Plack::Middleware 0
				Plack::Util 0
				Time::Piece 0
				Time::Seconds 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
				Plack::Test 0
				Plack::Builder 0
				HTTP::Request::Common 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
