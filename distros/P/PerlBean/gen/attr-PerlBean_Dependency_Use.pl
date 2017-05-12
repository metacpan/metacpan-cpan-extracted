use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Use dependency in a Perl bean',
        package => 'PerlBean::Dependency::Use',
        use_perl_version => 5.005,
        base => [ qw( PerlBean::Dependency ) ],
        description => <<EOF,
C<PerlBean::Dependency::Use> is a class to express C<use> dependencies to classes/modules/files in a C<PerlBean>.
EOF
        short_description => 'Use dependency in a Perl bean',
        synopsis => "TODO\n",
    },
    attr_opt => [
        {
            method_factory_name => 'import_list',
            type => 'MULTI',
            ordered => 1,
            short_description => 'the list after the C<dependency_name>',
        },
    ],
    meth_opt => [
        {
            method_name => 'write',
            body => <<'EOF',
    my $self = shift;
    my $fh = shift;

    my $dn = $self->get_dependency_name();
    my $tail ='';

    if ( $self->get_import_list() ) {
        $tail .= ' ';
        $tail .= join( ', ', $self->get_import_list() );
    }
    $fh->print( "use $dn$tail;\n" )
EOF
        },
    ],
} );

1;
