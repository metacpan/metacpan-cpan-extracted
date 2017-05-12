use strict;
use warnings;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';
if( $@ ) {
    warn "Optional ExtUtils::MakeMaker::Coverage not available\n";
}
else {
    my $covconfig = ExtUtils::MakeMaker::Coverage->config();
    # Ignore the Error::Exception module
    $covconfig->ignore( [
        '/Error/Exception.pm',
    ] );
    # Subroutine coverage doesn't work for Class::Std PRIVATE and RESTRICTED
    $covconfig->cover_subroutine( 0 );
    # We don't need POD testing here since we have a separate POD test
    $covconfig->cover_pod( 0 );
}

WriteMakefile(
    NAME                => 'P4::Server',
    AUTHOR              => 'Stephen Vance <steve@vance.com>',
    VERSION_FROM        => 'lib/P4/Server.pm',
    ABSTRACT_FROM       => 'lib/P4/Server.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Error::Exception'  => 0,
        'IO::Select'        => 0,
        'IO::Socket'        => 0,
        'IPC::Open3'        => 0,
        'IPC::Cmd'          => 0,
        'Module::Locate'    => 0,
        'P4'                => 0,
        'Symbol'            => 0,
        'Test::More'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'P4-Server-*' },
);
