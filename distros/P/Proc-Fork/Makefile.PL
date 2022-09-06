use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Proc-Fork>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Proc-Fork>;

our %META = (
	name        => 'Proc-Fork',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2018 },
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
				Carp 0
				Exporter::Tidy 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
