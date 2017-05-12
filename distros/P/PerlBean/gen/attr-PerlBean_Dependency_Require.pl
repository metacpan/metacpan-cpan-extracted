use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Require dependency in a Perl bean',
        package => 'PerlBean::Dependency::Require',
        use_perl_version => 5.005,
        base => [ qw( PerlBean::Dependency ) ],
        description => <<EOF,
C<PerlBean::Dependency::Require> is a class to express C<require> dependencies to classes/modules/files in a C<PerlBean>.
EOF
        short_description => 'Require dependency in a Perl bean',
        synopsis => "TODO\n",
    },
    meth_opt => [
        {
            method_name => 'write',
            body => <<'EOF',
    my $self = shift;
    my $fh = shift;

    my $dn = $self->get_dependency_name();

    $fh->print( "require $dn;\n" )
EOF
        },
    ],
} );

1;
