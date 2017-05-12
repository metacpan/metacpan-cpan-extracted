use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => '<%PackageName%>',
    VERSION_FROM  => '<%ModulePath%>',
    EXE_FILES     => [],
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
