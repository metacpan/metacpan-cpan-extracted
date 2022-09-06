use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/SQL-Interpol>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Interpol>;

our %META = (
	name        => 'SQL-Interpol',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2014 },
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
				Exporter::Tidy 0
				Object::Tiny::Lvalue 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
				Test::Differences 0
				Data::Dumper 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
