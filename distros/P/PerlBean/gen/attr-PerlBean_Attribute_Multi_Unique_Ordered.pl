use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Unique, ordered MULTI bean attribute information',
        package => 'PerlBean::Attribute::Multi::Unique::Ordered',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Attribute::Multi)],
        description => <<EOF,
C<PerlBean::Attribute::Multi::Unique::Ordered> contains unique ordered MULTI bean attribute information. It is a subclass of C<PerlBean::Attribute::Multi>. The code generation and documentation methods from C<PerlBean::Attribute> are implemented.`
EOF
        short_description => 'contains unique ordered MULTI bean attribute information',
        synopsis => &get_syn(),
    },
    attr_opt => [
    ],
    meth_opt => [
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
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$count${AO}+=${AO}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS});
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
${IND}${IND}${IND}push${BFP}(${ACS}\@ret,${AC}\$self->{$pkg_us}{$an}{ARRAY}[${ACS}int${BFP}(\$i)${ACS}]${ACS});
${IND}${IND}}
${IND}${IND}return${BFP}(\@ret);
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}# Return the list
${IND}${IND}return${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}}${ACS});
${IND}}
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}\[${ACS}INDEX_ARRAY${ACS}\]${ACS}",
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
            method_name => 'create_method_pop',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('pop');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined($self->get_short_description()) ? $self->get_short_description() : 'not described option';
    my $empt = $self->is_allow_empty() ? '' : ' After popping at least one element must remain.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}(${ACS}scalar${BFP}(\@_)${AO}>${AO}1)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Method tail
    $body .= <<EOF;
${IND}# Pop value
${IND}my \$val${AO}=${AO}pop${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}}${ACS});
${IND}delete${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS});
${IND}return${BFP}(\$val);
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
    my $an_esc = $self->_esc_apos($an);
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
${IND}# Push values
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}next if${BCP}(${ACS}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS})${ACS});
${IND}${IND}push${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}},${AC}\$val${ACS});
${IND}${IND}\$self->{$pkg_us}{$an}{HASH}{\$val}${AO}=${AO}\$val;
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Push additional values on ${desc}. C<ARRAY> is the list value. The push may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element are ignored.${exc}
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
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ? ' Default value at initialization is C<' . join( ', ', $self->_esc_aq ( @{ $self->get_default_value() } ) ) . '>.' : '';
    my $empt = $self->is_allow_empty() ? '' : ' C<ARRAY> must at least have one element.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ? " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<". $attr_overl->get_package() .'>.': '';

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
    # Empty the list
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

${IND}# Empty list
${IND}\$self->{$pkg_us}{$an}{ARRAY}${AO}=${AO}\[];
${IND}\$self->{$pkg_us}{$an}{HASH}${AO}=${AO}\{};

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Push values
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}next if${BCP}(${ACS}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS})${ACS});
${IND}${IND}push${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}},${AC}\$val${ACS});
${IND}${IND}\$self->{$pkg_us}{$an}{HASH}{\$val}${AO}=${AO}\$val;
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Set ${desc} absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the first occurring element to be inserted and the rest to be ignored.${def}${empt}${exc}${overl}
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
            method_name => 'create_method_shift',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
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
${IND}# Shift value
${IND}my \$val${AO}=${AO}shift${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}}${ACS});
${IND}delete${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS});
${IND}return${BFP}(\$val);
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
    my $an_esc = $self->_esc_apos($an);
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

EOF

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Unshift values
${IND}foreach my \$val (${ACS}reverse${BFP}(\@_)${ACS})${PBOC[1]}{
${IND}${IND}next if${BCP}(${ACS}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{HASH}{\$val}${ACS})${ACS});
${IND}${IND}unshift${BFP}(${ACS}\@{${ACS}\$self->{$pkg_us}{$an}{ARRAY}${ACS}},${AC}\$val${ACS});
${IND}${IND}\$self->{$pkg_us}{$an}{HASH}{\$val}${AO}=${AO}\$val;
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Unshift additional values on ${desc}. C<ARRAY> is the list value. The push may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element are ignored.${exc}
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
            method_name => 'create_methods',
            description => <<EOF,
__SUPER_POD__ Access methods are B<set...>, B<push...>, B<pop...>, B<shift...>, B<unshift...>, B<exists...> and B<get...>.
EOF
            body => <<'EOF',
    my $self = shift;

    return(
        $self->create_method_exists(),
        $self->create_method_get(),
        $self->create_method_pop(),
        $self->create_method_push(),
        $self->create_method_set(),
        $self->create_method_shift(),
        $self->create_method_unshift(),
    );
EOF
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
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Multi_Unique_Ordered.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Multi_Unique_Ordered.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
