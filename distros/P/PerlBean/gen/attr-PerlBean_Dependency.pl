use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Dependency (use, require or import) in a Perl bean',
        package => 'PerlBean::Dependency',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Dependency> is an abstract class to express dependencies to classes/modules/files in a C<PerlBean>.
EOF
        short_description => 'Dependency in a Perl bean',
        synopsis => "None, this is an abstract class.\n",
    },
    attr_opt => [
        {
            method_factory_name => 'dependency_name',
            short_description => 'the dependency name',
            allow_rx => [ qw( ^.*[a-zA-Z].*$) ],
        },
        {
            method_factory_name => 'volatile',
            type => 'BOOLEAN',
            short_description => 'the dependency is volatile',
        },
    ],
    meth_opt => [
        {
            method_name => 'write',
            interface => 1,
            parameter_description => 'FILEHANDLE',
            description => <<EOF,
Writes code for the dependency. C<FILEHANDLE> is an C<IO::Handle> object.
EOF
        },
    ],
} );

1;
