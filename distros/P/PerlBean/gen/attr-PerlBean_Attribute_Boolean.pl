use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'BOOLEAN bean attribute information',
        package => 'PerlBean::Attribute::Boolean',
        use_perl_version => 5.005,
        base => [qw(PerlBean::Attribute)],
        description => <<EOF,
C<PerlBean::Attribute::Boolean> contains BOOLEAN bean attribute information. It is a subclass of C<PerlBean::Attribute>. The code generation and documentation methods are implemented.
EOF
        short_description => 'contains BOOLEAN bean attribute information',
        synopsis => &get_syn(),
    },
    attr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'create_method_is',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('is');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        volatile => 1,
        documented => $self->is_documented(),
        description => <<EOF,
Returns whether ${desc} or not.
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(${ACS}\$self->{$pkg_us}{$an}${ACS})${PBOC[1]}{
${IND}${IND}return${BFP}(1);
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}return${BFP}(0);
${IND}}
EOF
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_set',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ?
        $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ?
        ' Default value at initialization is C<' .
            $self->_esc_aq( $self->get_default_value() ) . '>.' :
        '';
    my $exc = ' On error an exception C<' . $self->get_exception_class() .
        '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ?
        " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<" .
            $attr_overl->get_perl_bean()->get_package() .'>.' :
        '';

    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'VALUE',
        volatile => 1,
        documented => $self->is_documented(),
        description => <<EOF,
State that $desc. C<VALUE> is the value.$def$exc$overl
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(shift)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}${AO}=${AO}1;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}${AO}=${AO}0;
${IND}}
EOF
    } ) );
THE_EOF
        },
        {
            method_name => 'create_methods',
            body => <<'EOF',
    my $self = shift;

    return(
        $self->create_method_is(),
        $self->create_method_set()
    );
EOF
        },
        {
            method_name => 'write_allow_isa',
            documented => 0,
            body => "    return('');\n",
        },
        {
            method_name => 'write_allow_ref',
            documented => 0,
            body => "    return('');\n",
        },
        {
            method_name => 'write_allow_rx',
            documented => 0,
            body => "    return('');\n",
        },
        {
            method_name => 'write_allow_value',
            documented => 0,
            body => "    return('');\n",
        },
        {
            method_name => 'write_default_value',
            body => <<'THE_EOF',
    my $self = shift;

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->get_default_value() ? 1 : 0;

    return( "${IND}$an${AO}=>${AO}$dv,\n" );
THE_EOF
        },
        {
            method_name => 'write_constructor_option_code',
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();


    # Comment
    my $code = "${IND}# $an, " . $self->type();
    $code .= $self->is_mandatory() ? ', mandatory' : '';
    $code .= defined( $self->get_default_value() ) ? ', with default value' : '';
    $code .= "\n";

    # is_mandatory check
    if ($self->is_mandatory()) {
        $code .= <<EOF;
${IND}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::_initialize, option '$an' is mandatory.");
EOF
    }

    if ( $self->is_mandatory() ) {
        $code .= <<EOF;
${IND}\$self->$op$mb${BFP}(${ACS}\$opt->{$an}${ACS});
EOF
    }
    else {
        if ( defined( $self->get_default_value () ) ) {
            $code .= <<EOF;
${IND}\$self->$op$mb${BFP}(${ACS}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}?${AO}\$opt->{$an}${AO}:${AO}\$DEFAULT_VALUE{$an}${ACS});
EOF
        }
        else {
            $code .= <<EOF;
${IND}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}&&${AO}\$self->$op$mb${BFP}(${ACS}\$opt->{$an}${ACS});
EOF
        }
    }

    # Empty line
    $code .= "\n";

    return($code);
THE_EOF
        },
        {
            method_name => 'write_constructor_option_doc',
            body => <<'THE_EOF',
    my $self = shift;

    # Do nothing if not documented
    $self->is_documented() || return('');

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $mand = $self->is_mandatory() ? ' Mandatory option.' : '';
    my $def = '';
    if ( defined( $self->get_default_value() ) ) {
        $def = ' Defaults to B<' . $self->_esc_aq( $self->get_default_value() ) . '>.';
    }

    return(<<EOF);

\=item B<C<$an>>

Passed to L<$op$mb${BFP}()>.${mand}${def}
EOF
THE_EOF
        },
        {
            method_name => 'mk_doc_clauses',
            body => "    return('');\n",
        },
    ],
    sym_opt => [
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
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Boolean.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Boolean.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
