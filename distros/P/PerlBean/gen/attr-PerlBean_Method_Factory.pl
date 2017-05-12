use strict;

my $pkg = 'PerlBean::Method::Factory';

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Abstract PerlBean method factory information',
        package => $pkg,
        use_perl_version => 5.005,
        description => <<EOF,
C<${pkg}> abstract class for method factory information.
EOF
        short_description => 'contains bean method factory information',
        synopsis => "None. This is an abstract class.\n",
    },
    attr_opt => [
        {
            method_factory_name => 'method_factory_name',
            type => 'SINGLE',
            mandatory => 1,
            allow_empty => 0,
            allow_rx => [qw(^\w+$)],
            short_description => 'method factory\'s name',
        },
        {
            method_factory_name => 'perl_bean',
            type => 'SINGLE',
            allow_isa => [qw(PerlBean)],
            short_description => 'the PerlBean to which this method factory belongs',
        },
    ],
    meth_opt => [
        {
            method_name => 'create_methods',
            description => <<EOF,
Returns a list of C<PerlBean::Attribute::Method> objects.
EOF
            interface => 1,
        },
    ],
    use_opt => [
    ],
} );

1;
