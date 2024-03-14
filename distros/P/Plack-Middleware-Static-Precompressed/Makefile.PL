use 5.008001; use strict; use warnings;

my $sc = q<https://github.com/ap/Plack-Middleware-Static-Precompressed>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-Middleware-Static-Precompressed>;

our %META = (
	name        => 'Plack-Middleware-Static-Precompressed',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2024 },
	license     => 'perl_5',
	resources   => {
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.008001
				parent 0
				Plack::Middleware 0
				Plack::Util::Accessor 0
				Plack::Middleware::NeverExpire 1.201
				Plack::Util 0
				Cache::LRU 0
				File::Find 0
				Plack::MIME 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
				Plack::Test 0
				HTTP::Request::Common 0
				Plack::MIME 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
