use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Module::Husbandry',
    VERSION_FROM  => 'lib/Module/Husbandry.pm',
    EXE_FILES     => [qw(
        bin/cppm bin/newpm bin/newpmbin bin/newpmdist bin/mvpm bin/rmpm
    )],
    PREREQ_PM => {
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
