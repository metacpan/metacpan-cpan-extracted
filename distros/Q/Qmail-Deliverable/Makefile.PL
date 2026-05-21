use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @authors = (
    'Juerd Waalboer <#####@juerd.nl>',
    'Matt Simerson <msimerson@cpan.org>',
    'Martin Sluka',
);

my %dist = ();
if ( $^O eq 'darwin' ) {
    $dist{TAR} = 'COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar';
}

WriteMakefile(
    NAME              => 'Qmail::Deliverable',
    VERSION_FROM      => 'lib/Qmail/Deliverable.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Qmail/Deliverable.pm', # retrieve abstract from module
    AUTHOR            => 'Matt Simerson <msimerson@cpan.org>',
    MIN_PERL_VERSION  => '5.006',
    EXE_FILES         => [ 'bin/qmail-deliverabled', 'qpsmtpd-plugin/qmail_deliverable' ],
    PREREQ_PM         => {},
    TEST_REQUIRES     => {
        'Test::More'       => 0,
    },
    META_ADD => {
        'meta-spec' => { version => 2 },
        author      => \@authors,
        license     => [ 'perl_5' ],
    },
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/msimerson/Qmail-Deliverable.git',
                web  => 'https://github.com/msimerson/Qmail-Deliverable',
            },
            bugtracker => {
                web => 'https://github.com/msimerson/Qmail-Deliverable/issues',
            },
        },
        x_contributors => [ 'Martin Sluka' ],
    },
    dist => \%dist,
);

package MY;
sub realclean {
    my ($self, %attribs) = @_;
    push @{ $attribs{FILES} ||= [] }, 'cover_db';
    return $self->SUPER::realclean(%attribs);
}

sub postamble {
    return <<'MAKE_FRAG';
PERLTIDY_FILES = bin/qmail-deliverabled qpsmtpd-plugin/qmail_deliverable \
    $(wildcard lib/Qmail/*.pm lib/Qmail/*/*.pm) \
    $(wildcard t/*.t t/lib/*.pm t/lib/*/*.pm)

tidy:
	perltidy $(PERLTIDY_FILES)
	$(RM_F) $(addsuffix .bak, $(PERLTIDY_FILES))
MAKE_FRAG
}
