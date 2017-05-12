use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Unique MULTI bean attribute information',
        package => 'PerlBean::Attribute::Multi::Unique',
        use_perl_version => 5.005,
        base => [ qw(PerlBean::Attribute::Multi)],
        description => <<EOF,
C<PerlBean::Attribute::Multi::Unique> contains unique MULTI bean attribute information. It is a subclass of C<PerlBean::Attribute::Multi>. The code generation and documentation methods from C<PerlBean::Attribute> are implemented.
EOF
        short_description => 'contains unique MULTI bean attribute information',
        synopsis => &get_syn(),
    },
    attr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'create_method_add',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('add');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined($self->get_short_description()) ? $self->get_short_description() : 'not described option';
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
${IND}# Add values
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}{\$val}${AO}=${AO}\$val;
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Add additional values on ${desc}. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted.${exc}
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
            method_name => 'create_method_delete',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('delete');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $empt = $self->is_allow_empty() ? '' : ' After deleting at least one element must remain.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}my \%would_delete${AO}=${AO}();
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$would_delete{\$val}${AO}=${AO}\$val if${BCP}(${ACS}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS})${ACS});
${IND}}
${IND}(${ACS}scalar${BFP}(${ACS}keys${BFP}(${ACS}\%{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS})${AO}==${AO}scalar(${ACS}keys${BFP}(\%would_delete)${ACS})${ACS})${AO}&&${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Method tail
    $body .= <<EOF;
${IND}# Delete values
${IND}my \$del${AO}=${AO}0;
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS})${AO}||${AO}next;
${IND}${IND}delete${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS});
${IND}${IND}\$del${AO}++;
${IND}}
${IND}return${BFP}(\$del);
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Delete elements from ${desc}.${empt} Returns the number of deleted elements.${exc}
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
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$count${AO}+=${AO}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS});
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
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@_${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@_' is/are not allowed.");

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Empty list
${IND}\$self->{$pkg_us}{$an}${AO}=${AO}\{};

${IND}# Add values
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}{\$val}${AO}=${AO}\$val;
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Set ${desc} absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored.${def}${empt}${exc}${overl}
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
            method_name => 'create_method_values',
            documented => 0,
            body => <<'THE_EOF',
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('values');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}# Return all values
${IND}return${BFP}(${ACS}values${BFP}(${ACS}\%{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS});
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns an C<ARRAY> containing all values of ${desc}.
EOF
        body => $body,
    } ) );
THE_EOF
        },
        {
            method_name => 'create_methods',
            description => <<EOF,
__SUPER_POD__ Access methods are B<set...>, B<add...>, B<delete...>, B<exists...> and B<values...>.
EOF
            body => <<'EOF',
    my $self = shift;

    return(
        $self->create_method_add(),
        $self->create_method_delete(),
        $self->create_method_exists(),
        $self->create_method_set(),
        $self->create_method_values(),
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
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Multi_Unique.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Multi_Unique.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
