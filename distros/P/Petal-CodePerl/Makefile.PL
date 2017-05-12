# $Header: /home/fergal/my/cvs/teng/Makefile.PL,v 1.4 2003/01/19 20:39:20 fergal Exp $

use ExtUtils::MakeMaker;

my $module = "Petal::CodePerl";
my $file_base = $module;
$file_base =~ s/::/\//g;
$file_base = "./lib/$file_base";
my $file = "$file_base.pm";
my $pod_file = "$file_base.pm";
(my $dir = $module) =~ s/::/-/g;

WriteMakefile(
	AUTHOR => 'Fergal Daly <fergal@esatclear.ie>',
	NAME => 'Petal::CodePerl',
	VERSION_FROM => './lib/Petal/CodePerl.pm',
	INSTALLDIRS => 'perl',
	PREREQ_PM => {
		'Scalar::Util' => 1.09,
		'Code::Perl' => '0.01',
		'Test::Deep' => '0.02',
		'Test::NoWarnings' => '0.03',
		'Parse::RecDescent' => '1.80',
		'Petal' => '0.95',
	},
	dist => {
		PREOP=> "rm -f README; pod2text -80 < $pod_file > README; cp -f README $dir-\$(VERSION)"
	}
);

sub MY::postamble
{
	return <<EOM;
lib/Petal/CodePerl/Parser.pm: grammar
	bin/buildparser
EOM
}
