use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Generic described object',
        package => 'PerlBean::Described::ExportTag',
        base => [ qw( PerlBean::Described ) ],
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Described::ExportTag> describes export tags for pod generation in C<PerlBean> objects.
EOF
        short_description => 'Tag description',
        synopsis => "TODO\n",
    },
    attr_opt => [
        {
            method_factory_name => 'export_tag_name',
            short_description => 'tag\'s name',
            type => 'SINGLE',
            mandatory => 1,
            allow_empty => 0,
            allow_rx => [qw(^\w+$)],
        },
    ],
} );

1;
