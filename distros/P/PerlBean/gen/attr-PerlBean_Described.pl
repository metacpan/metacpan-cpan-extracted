use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Generic described object',
        package => 'PerlBean::Described',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Described> is a generic abstract class to be inherited by objects that need to be described.
EOF
        short_description => 'Generic described',
        synopsis => "None, this is an abstract class.\n",
    },
    attr_opt => [
        {
            method_factory_name => 'description',
            short_description => 'the description',
        },
    ],
} );

1;
