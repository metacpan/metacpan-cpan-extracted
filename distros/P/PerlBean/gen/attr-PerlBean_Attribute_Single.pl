use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'SINGLE bean attribute information',
        package => 'PerlBean::Attribute::Single',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Attribute)],
        description => <<EOF,
C<PerlBean::Attribute::Single> contains SINGLE bean attribute information. It is a subclass of C<PerlBean::Attribute>. The code and documentation methods are implemented.
EOF
        short_description => 'contains SINGLE bean attribute information',
        synopsis => &get_syn(),
    },
    attr_opt => [
        {
            method_factory_name => 'allow_empty',
            type => 'BOOLEAN',
            default_value => 1,
            short_description => 'the attribute is allowed to be empty',
        },
        {
            method_factory_name => 'allow_isa',
            type => 'MULTI',
            unique => 1,
            short_description => 'the list of allowed classes',
        },
        {
            method_factory_name => 'allow_ref',
            type => 'MULTI',
            unique => 1,
            short_description => 'the list of allowed references',
        },
        {
            method_factory_name => 'allow_rx',
            type => 'MULTI',
            unique => 1,
            short_description => 'the list of allow regular expressions',
        },
        {
            method_factory_name => 'allow_value',
            type => 'MULTI',
            unique => 1,
            short_description => 'allowed values',
        },
    ],
    meth_opt => [
        {
            method_name => 'create_method_get',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('get');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns ${desc}.
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}return${BFP}(${ACS}\$self->{$pkg_us}{$an}${ACS});
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
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();

    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ? ' Default value at initialization is C<' . $self->get_default_value() . '>.' : '';
    my $empt = $self->is_allow_empty() ? '' : ' C<VALUE> may not be C<undef>.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ? " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<". $attr_overl->get_package() .'>.': '';


    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;
${IND}my \$val${AO}=${AO}shift;

EOF

    # Check if value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# Value for $an_esc is not allowed to be empty
${IND}defined${BFP}(\$val)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, value may not be empty.");

EOF
    }

    # Check if isa/ref/rx/value is allowed
    $body .= <<EOF;
${IND}# Check if isa/ref/rx/value is allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\$val${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, the specified value '\$val' is not allowed.");

EOF

    # Assignment and method tail
    $body .= <<EOF;
${IND}# Assignment
${IND}\$self->{$pkg_us}{$an}${AO}=${AO}\$val;
EOF

    # Make description
    my $description = <<EOF;
Set ${desc}. C<VALUE> is the value.${def}${empt}${exc}${overl}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'VALUE',
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_methods',
            body => <<'EOF',
    my $self = shift;

    return(
        $self->create_method_get(),
        $self->create_method_set()
    );
EOF
        },
        {
            method_name => 'write_allow_isa',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    scalar( $self->values_allow_isa() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( sort( $self->values_allow_isa() ) );
    return( "${IND}$an${AO}=>${AO}\[${ACS}$dv${ACS}],\n" );
THE_EOF
        },
        {
            method_name => 'write_allow_ref',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    scalar( $self->values_allow_ref() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my @dv = sort( $self->_esc_aq( $self->values_allow_ref() ) );

    my $ass = "${IND}$an${AO}=>${AO}\{\n";
    foreach my $dv (@dv) {
        $ass .= "${IND}${IND}$dv${AO}=>${AO}1,\n";
    }
    $ass .= "${IND}},\n";

    return($ass);
THE_EOF
        },
        {
            method_name => 'write_allow_rx',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    scalar( $self->values_allow_rx() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( sort( $self->values_allow_rx() ) );
    return( "${IND}$an${AO}=>${AO}\[${ACS}$dv${ACS}],\n" );
THE_EOF
        },
        {
            method_name => 'write_allow_value',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;
    my $fh = shift;

    scalar( $self->values_allow_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my @dv = sort( $self->_esc_aq( $self->values_allow_value() ) );

    my $ass = "${IND}$an${AO}=>${AO}\{\n";
    foreach my $dv (@dv) {
        $ass .= "${IND}${IND}$dv${AO}=>${AO}1,\n";
    }
    $ass .= "${IND}},\n";
THE_EOF
        },
        {
            method_name => 'write_default_value',
            body => <<'THE_EOF',
    my $self = shift;
    my $fh = shift;

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( $self->get_default_value() );

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
    if ( $self->is_mandatory() ) {
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
        if ( defined( $self->get_default_value() ) ) {
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
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty if no clauses at all
    return('') if ( ! scalar( $self->values_allow_isa() ) &&
        ! scalar( $self->values_allow_ref() ) &&
        ! scalar( $self->values_allow_rx() ) &&
        ! scalar( $self->values_allow_value() )
    );

    # Make the clauses head for documentation
    my $doc = <<EOF;
\=over

EOF

    # Make body
    $doc .= $self->mk_doc_clauses_allow_isa(@_);
    $doc .= $self->mk_doc_clauses_allow_ref(@_);
    $doc .= $self->mk_doc_clauses_allow_rx(@_);
    $doc .= $self->mk_doc_clauses_allow_value(@_);

    # Make tail
    $doc .= <<EOF;
\=back
EOF

    # Return the clauses for documentation
    return($doc);
THE_EOF
        },
        {
            method_name => 'mk_doc_clauses_allow_isa',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    # Return empty string if no values_allow_isa
    return('') if ( ! scalar( $self->values_allow_isa() ) );

    # Make clauses head
    my $clauses = <<EOF;
\=item VALUE must be a (sub)class of:

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
    my $or = scalar( $self->values_allow_isa() ) ? 'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must be a reference of:

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
        'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must match regular expression:

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
        $self->values_allow_rx() ) ? 'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must be a one of:

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
    ],
    sym_opt => [
    ],
    use_opt => [
        {
            dependency_name => 'PerlBean::Method',
        },
        {
            dependency_name => 'PerlBean::Style',
            import_list => [ 'qw(:codegen)' ],
        },
    ],
} );

sub get_syn {
    use IO::File;
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Single.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Single.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
