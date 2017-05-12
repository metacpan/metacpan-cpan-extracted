use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Symbol in a Perl bean',
        package => 'PerlBean::Symbol',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Symbol> allows to specify, declare, assign an export a symbol from a C<PerlBean>.
EOF
        short_description => 'Symbol in a Perl bean',
        synopsis => &get_syn(),
    },
    attr_opt => [
        {
            method_factory_name => 'declared',
            type => 'BOOLEAN',
            default_value => 1,
            short_description => 'the symbol is to be declared with C<our>',
        },
        {
            method_factory_name => 'export_tag',
            type => 'MULTI',
            unique => 1,
            short_description => 'the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default',
            allow_rx => [ qw(^\S*$) ],
        },
        {
            method_factory_name => 'symbol_name',
            short_description => 'the symbol\'s name (e.g. C<$var> or C<@list>)',
            allow_rx => [ qw(^\S+$) ],
        },
        {
            method_factory_name => 'assignment',
            short_description => 'the value assigned to the symbol during declaration',
        },
        {
            method_factory_name => 'comment',
            short_description => 'the comment for the symbol declaration',
        },
        {
            method_factory_name => 'description',
            short_description => 'the description of the symbol',
        },
        {
            method_factory_name => 'volatile',
            type => 'BOOLEAN',
            short_description => 'the symbol is volatile',
        },
    ],
    meth_opt => [
        {
            method_name => 'write',
            parameter_description => 'FILEHANDLE',
            description => <<EOF,
Writes the code for the symbol. C<FILEHANDLE> is an C<IO::Handle> object.
EOF
            body => <<'EOF',
    my $self = shift;
    my $fh = shift;

    # Do nothing if symbol should not be declared
    $self->is_declared() || return;

    my $name = $self->get_symbol_name() || '';

    my $comment = $self->get_comment() || '';

    my $decl = $self->get_assignment() ?
            "$AO=$AO" . $self->get_assignment() : ";\n";

    $fh->print( "${comment}our ${name}${decl}\n" );
EOF
        },
    ],
    use_opt => [
        {
            dependency_name => 'PerlBean::Style',
            import_list => [ 'qw(:codegen)' ],
        },
    ],
} );

sub get_syn {
    use IO::File;
    my $fh = IO::File->new('< syn-PerlBean.pl');
    $fh = IO::File->new('< gen/syn-PerlBean.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
