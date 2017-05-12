use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
    NAME                => 'Template::Timer',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Timer.pm',
    ABSTRACT_FROM       => 'Timer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Template'      => 0,
        'Test::More'    => 0,
        'Time::HiRes'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Timer-*' },
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.36' ) {
    $parms{EXTRA_META} = <<EOF;
resources:
    license: http://dev.perl.org/licenses/
    Repository: http://github.com/petdance/template-timer/
EOF
}


WriteMakefile( %parms );

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -1 -q -profile perlcriticrc Timer.pm t/*.t

MAKE_FRAG

    return $postamble;
}
