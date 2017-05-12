use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Sys::Ptrace',
    VERSION_FROM   => 'Ptrace.pm',     # finds $VERSION
    PREREQ_PM      => {},              # e.g., Module::Name => 1.1
    BUILD_REQUIRES => {
        'Test::NoWarnings' => 0,
    },
    LIBS   => [''],                    # e.g., '-lm'
    DEFINE => '',                      # e.g., '-DHAVE_SOMETHING'
    INC    => '',                      # e.g., '-I/usr/include/other'
    clean  => {
        FILES => q[*.bak *~],
    }
);

package MY;

sub libscan {
    my $self = shift;
    my $path = shift;
    ( $path =~ / \bCVS\b | \~$ /x ) ? undef : $path;
}

sub postamble {
    return qq^

pm_to_blib: README

README: Ptrace.pm
\tpod2text Ptrace.pm >README

^;
}

1;
