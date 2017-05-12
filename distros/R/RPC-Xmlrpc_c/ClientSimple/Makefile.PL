use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'RPC::Xmlrpc_c::ClientSimple',
    'VERSION_FROM' => 'ClientSimple.pm',
    'dist'         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
