use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'MULTI bean attribute abstraction',
        package => 'PerlBean::Attribute::Multi',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Attribute::Single)],
        description => <<EOF,
C<PerlBean::Attribute::Multi> is a subclass of C<PerlBean::Attribute> and it's only function is to group the MULTI attribute classes.
EOF
        short_description => 'contains MULTI bean attribute information',
        synopsis => "None. This is an abstract class.\n",
    },
    attr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'mk_doc_clauses_allow_isa',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty string if no values_allow_isa
    return('') if ( ! scalar( $self->values_allow_isa() ) );

    # Make clauses head
    my $clauses = <<EOF;
\=item The values in C<ARRAY> must be a (sub)class of:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_isa() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
THE_EOF
        },
        {
            method_name => 'mk_doc_clauses_allow_ref',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty string if no values_allow_ref
    return('') if ( ! scalar( $self->values_allow_ref() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() ) ? 'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must be a reference of:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_ref() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
THE_EOF
        },
        {
            method_name => 'mk_doc_clauses_allow_rx',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty string if no values_allow_rx
    return('') if ( ! scalar( $self->values_allow_rx() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() || $self->values_allow_ref() ) ?
        'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must match regular expression:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_rx() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
THE_EOF
        },
        {
            method_name => 'mk_doc_clauses_allow_value',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty string if no values_allow_value
    return('') if ( ! scalar( $self->values_allow_value() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() || $self->values_allow_ref() ||
        $self->values_allow_rx() ) ? 'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must be a one of:

\=over

EOF

    # Make clauses body
    foreach my $val ( sort( $self->values_allow_value() ) ) {
        $clauses .= <<EOF;
\=item ${val}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
THE_EOF
        },
        {
            method_name => 'create_methods',
            interface => 1,
        },
        {
            method_name => 'write_default_value',
            body => <<'THE_EOF',
    my $self = shift;

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( @{ $self->get_default_value() } );

    return( "${IND}$an${AO}=>${AO}\[$dv],\n" );
THE_EOF
        },
        {
            method_name => 'write_constructor_option_code',
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_perl_bean()->get_package();

    # Comment
    my $code = "${IND}# $an, " . $self->type();
    $code .= $self->is_mandatory() ? ', mandatory' : '';
    $code .= defined( $self->get_default_value() ) ? ', with default value' : '';
    $code .= "\n";

    # is_mandatory check
    if ( $self->is_mandatory() ) {
        $code .= <<EOF;
${IND}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::_initialize, option '$an' is mandatory.");
EOF
    }

    my $pre = '';
    if ( ! $self->is_mandatory() ) {
        $pre .= "${IND}";
        $code .= <<EOF;
${IND}if${BCP}(${ACS}exists${BFP}(${ACS}\$opt->{$an}${ACS})${ACS})${PBOC[1]}{
EOF
    }
    $code .= <<EOF;
${IND}${pre}ref${BFP}(${ACS}\$opt->{$an}${ACS})${AO}eq${AO}'ARRAY'${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::_initialize, specified value for option '$an' must be an 'ARRAY' reference.");
${IND}${pre}\$self->set$mb${BFP}(${ACS}\@{${ACS}\$opt->{$an}${ACS}}${ACS});
EOF
    # default value
    if ( ! $self->is_mandatory() ) {
        if ( defined( $self->get_default_value() ) ) {
            $code .= <<EOF;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->set$mb${BFP}(${ACS}\@{${ACS}\$DEFAULT_VALUE{$an}${ACS}}${ACS});
EOF
        }
        else {
            $code .= <<EOF;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->set$mb${BFP}();
EOF
            }
        }
    if ( ! $self->is_mandatory()) {
        $code .= <<EOF;
${IND}}
EOF
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
    my $mb = $self->get_method_base();
    my $mand = $self->is_mandatory() ? ' Mandatory option.' : '';
    my $multi = ( $self->isa('PerlBean::Attribute::Multi') ) ? ' Must be an C<ARRAY> reference.' : '';
    my $def = '';
    if ( defined( $self->get_default_value() ) ) {
        my $list = join( '> , B<', $self->_esc_aq( @{ $self->get_default_value() } ) );
        $def = ' Defaults to B<[> B<' . $list . '> B<]>.';
    }

    return(<<EOF);

\=item B<C<$an>>

Passed to L<set$mb${BFP}()>.${multi}${mand}${def}
EOF
THE_EOF
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

1;
