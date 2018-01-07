use strict;
use warnings;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    no warnings 'once';
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    NAME                => 'Slay::Makefile',
    AUTHOR              => 'Slaven Rezic <srezic@cpan.org>',
    VERSION_FROM        => 'lib/Slay/Makefile.pm',
    ABSTRACT            => 'Wrapper to Slay::Maker that reads the rules from a file',
    EXE_FILES           => [qw(slaymake)],
    PL_FILES            => {},
    PREREQ_PM => {
	'Slay::Maker' => 0.04,
	'File::Path'  => 0,
	'File::Copy::Recursive' => 0,
    },

    ($eumm_recent_enough
     ? (META_MERGE => { resources  => { repository => 'git://github.com/eserte/Slay-Makefile.git' },
			author     => ['Mark Nodine <mnodine@alum.mit.edu>'],
		      },
       )
     : ()
    ),
);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
