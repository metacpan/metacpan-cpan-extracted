use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Ordered MULTI bean attribute information',
        package => 'PerlBean::Attribute::Multi::Ordered',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Attribute::Multi)],
        description => <<EOF,
C<PerlBean::Attribute::Multi::Ordered> contains ordered MULTI bean attribute information. It is a subclass of C<PerlBean::Attribute::Multi>. The code generation and documentation methods from C<PerlBean::Attribute> are implemented.
EOF
        short_description => 'contains ordered MULTI bean attribute information',
        synopsis => &get_syn(),
    },
    attr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'create_methods',
            description => <<EOF,
__SUPER_POD__ Access methods are B<set...>, B<set_idx...>, B<set_num...>, B<push...>, B<pop...>, B<shift...>, B<unshift...>, B<exists...> and B<get...>.
EOF
            body => <<'EOF',
    my $self = shift;

    return(
        $self->create_method_get(),
        $self->create_method_exists(),
        $self->create_method_pop(),
        $self->create_method_push(),
        $self->create_method_set(),
        $self->create_method_set_idx(),
        $self->create_method_set_num(),
        $self->create_method_shift(),
        $self->create_method_unshift(),
    );
EOF
        },
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

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(${ACS}scalar${BFP}(\@_)${ACS})${PBOC[1]}{
${IND}${IND}my \@ret${AO}=${AO}();
${IND}${IND}foreach my \$i (\@_)${PBOC[2]}{
${IND}${IND}${IND}push${BFP}(${ACS}\@ret,${AC}\$self->{$pkg_us}{$an}[${ACS}int${BFP}(\$i)${ACS}]${ACS});
${IND}${IND}}
${IND}${IND}return${BFP}(\@ret);
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}# Return the full list
${IND}${IND}return${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS});
${IND}}
EOF
    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}\[${ACS}INDEX_ARRAY${ACS}]${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns an C<ARRAY> containing ${desc}. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.
EOF
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_exists',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('exists');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}# Count occurrences
${IND}my \$count${AO}=${AO}0;
${IND}foreach my \$val1 (\@_)${PBOC[1]}{
${IND}${IND}foreach my \$val2 (${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${PBOC[2]}{
${IND}${IND}${IND}(${ACS}\$val1${AO}eq${AO}\$val2${ACS})${AO}&&${AO}\$count${AO}++;
${IND}${IND}}
${IND}}
${IND}return${BFP}(\$count);
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns the count of items in C<ARRAY> that are in ${desc}.
EOF
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_pop',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('pop');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $empt = $self->is_allow_empty() ? '' : ' After popping at least one element must remain.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if (! $self->is_allow_empty()) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}(scalar${BFP}(\@_)${AO}>${AO}1)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Method tail
    $body .= <<EOF;
${IND}# Pop an element from the list
${IND}return${BFP}(${ACS}pop${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS});
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Pop and return an element off ${desc}.${empt}${exc}
EOF
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_push',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('push');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Push the list
${IND}push${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}},${AC}\@_${ACS});
EOF

    # Make description
    my $description = <<EOF;
Push additional values on ${desc}. C<ARRAY> is the list value.${exc}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
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
    my $def = defined( $self->get_default_value() ) ? ' Default value at initialization is C<' . join( ', ', $self->_esc_aq( @{ $self->get_default_value() } ) ) . '>.' : '';
    my $empt = $self->is_allow_empty() ? '' : ' It must at least have one element.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ? " B<NOTE:> Methods B<C<*$mb${BFP}()>> are overloaded from package C<". $attr_overl->get_package() .'>.': '';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}scalar${BFP}(\@_)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

EOF

    # Set the list
    $body .= <<EOF;
${IND}# Set the list
${IND}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}}${AO}=${AO}\@_;
EOF

    # Make description
    my $description = <<EOF;
Set ${desc} absolutely. C<ARRAY> is the list value.${def}${empt}${exc}${overl}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_set_idx',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('set_idx');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;
${IND}my \$idx${AO}=${AO}shift;
${IND}my \$val${AO}=${AO}shift;

EOF

    # Check if index is a positive integer or zero
    $body .= <<EOF;
${IND}# Check if index is a positive integer or zero
${IND}(${ACS}\$idx${AO}==${AO}int${BFP}(\$idx)${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, the specified index '\$idx' is not an integer.");
${IND}(${ACS}\$idx${AO}>=${AO}0${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, the specified index '\$idx' is not a positive integer or zero.");

EOF

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\$val${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

EOF

    # Set the value in the list
    $body .= <<EOF;
${IND}# Set the value in the list
${IND}\$self->{$pkg_us}{$an}[\$idx]${AO}=${AO}\$val;
EOF

    # Make description
    my $description = <<EOF;
Set value in $desc. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}INDEX, VALUE${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_set_num',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('set_num');
    my $op_set_idx = &{$MOF}('set_idx');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;
${IND}my \$num${AO}=${AO}shift;

EOF

    # Check if index is an integer
    $body .= <<EOF;
${IND}# Check if index is an integer
${IND}(${ACS}\$num${AO}==${AO}int${BFP}(\$num)${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, the specified number '\$num' is not an integer.");

EOF

    # Call $op_set_idx$mb
    $body .= <<EOF;
${IND}# Call $op_set_idx$mb
${IND}\$self->$op_set_idx$mb${BFP}(${ACS}\$num${AO}-${AO}1,${AC}\@_${ACS});
EOF

    # Make description
    my $description = <<EOF;
Set value in $desc. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}NUMBER, VALUE${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_shift',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('shift');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $empt = $self->is_allow_empty() ? '' : ' After shifting at least one element must remain.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}(${ACS}scalar${BFP}(\@_)${AO}>${AO}1${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Method tail
    $body .= <<EOF;
${IND}# Shift an element from the list
${IND}return${BFP}(${ACS}shift${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS});
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Shift and return an element off ${desc}.${empt}${exc}
EOF
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_method_unshift',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('unshift');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

${IND}# Unshift the list
${IND}unshift${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}${ACS}},${AC}\@_${ACS});
EOF

    # Make description
    my $description = <<EOF;
Unshift additional values on ${desc}. C<ARRAY> is the list value.${exc}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
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

sub get_syn {
    use IO::File;
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Multi_Ordered.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Multi_Ordered.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
    $syn .= ' ' . $prev_line;
    $prev_line = $line;
    }
    return($syn);
}

1;
