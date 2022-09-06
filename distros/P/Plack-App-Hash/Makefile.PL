use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Plack-App-Hash>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-App-Hash>;

our %META = (
	name        => 'Plack-App-Hash',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2022 },
	license     => 'perl_5',
	resources   => {
		license    => [ 'http://dev.perl.org/licenses/' ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
				Array::RefElem 0
				HTTP::Status 0
				JSON::MaybeXS 0
				Plack::Component 0
				Plack::MIME 0
				Plack::Util 0
				Plack::Util::Accessor 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
				Plack::Test 0
				HTTP::Request::Common 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
