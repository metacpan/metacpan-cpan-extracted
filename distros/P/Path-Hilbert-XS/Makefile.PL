use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Path::Hilbert::XS',
    VERSION_FROM   => 'lib/Path/Hilbert/XS.pm',
    PREREQ_PM      => { 'Test::More' => 0 },
    ABSTRACT_FROM  => 'lib/Path/Hilbert/XS.pm',
    AUTHOR         => [
        'Gonzalo Diethelm <gonzus@cpan.org>',
        'Sawyer X <xsawyerx@cpan.org>',
    ],
    LICENSE        => 'mit',
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/p5pclub/path-hilbert-xs.git',
                web  => 'https://github.com/p5pclub/path-hilbert-xs',
            },
        },
    },
);

# Add -Wall to CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    $self->{CCFLAGS} .= ' -Wall ';
    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
