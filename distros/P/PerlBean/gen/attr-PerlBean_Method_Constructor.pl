use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Abstract PerlBean method information',
        package => 'PerlBean::Method::Constructor',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Method) ],
        description => <<EOF,
C<PerlBean::Method> class for bean constructor method information. This is a subclass from C<PerlBean::Method> with the purpose to differentiate between plain methods and constructors.
EOF
        short_description => 'contains bean constructor method information',
#        synopsis => '',
    },
    attr_opt => [
    ],
    meth_opt => [
    ],
} );

1;
