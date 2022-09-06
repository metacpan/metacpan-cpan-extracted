use 5.008001; use strict; use warnings;

my $sc = q<https://github.com/ap/Router-Resource>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Router-Resource>;

our %META = (
	name        => 'Router-Resource',
	author      => 'David E. Wheeler <david@kineticode.com>',
	x_copyright => { holder => 'David E. Wheeler', year => 2011 },
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
				Router::Simple 0.07
				Sub::Exporter 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0.70
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
