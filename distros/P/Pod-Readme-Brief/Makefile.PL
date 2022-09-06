use 5.008; use strict; use warnings;

my $sc = q<https://github.com/ap/Pod-Readme-Brief>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Readme-Brief>;

our %META = (
	name        => 'Pod-Readme-Brief',
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
				perl 5.008
				Pod::Text 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
