use v5.20.0;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

sub get_version() {
    open my $fh, 'VERSION';
    chomp(my $v = <$fh>);
    close $fh;
    return $v;
}

my $version = get_version();

WriteMakefile(
    NAME           => 'Mojolicious::Command::coverage',
    VERSION        => $version,
    ABSTRACT       => 'Start you mojo app in coverage mode',
    AUTHOR         => 'Tobias Bossert <tobib at cpan.org>',
    LICENSE        => 'mit',
    PREREQ_PM      => {
        'Mojolicious'        => '>=8.0',
        'Devel::Cover'       => '>=1.35',
        'Devel::Deanonymize' => '>=0.1.2'
    },,
    BUILD_REQUIRES => {},
    MAKE           => 'gmake',
    META_MERGE     => {
        requires  => { perl => '5.020000' },
        resources => {
            license    => 'https://opensource.org/licenses/mit',
            repository => 'https://github.com/oposs/mojolicious_coverage',
            bugtracker => 'https://github.com/oposs/mojolicious_coverage/issues'
        },
        no_index  => { directory => [ 't' ] },
        homepage   => 'https://www.oetiker.ch',
    },
    test           => { TESTS => 't/*.t' }
);

sub MY::postamble {
    my $self = shift;
    return <<"EOF";

VERSION_FILES := \$(shell grep -Rl 'our \$\$VERSION = ' .)
\$(VERSION_FILES): VERSION
	\$(PERL) -i -p -e 's/\$VERSION\\s*=\\s*"[\\d|\.]*[A-z]*"/\$VERSION = "\$(VERSION)"/;' \$\@

# # Unfortunately, this is (gnu-)make specific...
# ifeq (\$(EDITOR),)
# EDITOR=/usr/bin/vi
# endif

CHANGES: VERSION
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\$(EDITOR) CHANGES

EOF
}
