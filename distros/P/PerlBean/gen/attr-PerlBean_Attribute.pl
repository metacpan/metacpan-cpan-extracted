use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Abstract PerlBean attribute information',
        base => [ qw( PerlBean::Method::Factory ) ],
        package => 'PerlBean::Attribute',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Attribute> abstract class for bean attribute information. Attribute access methods are implemented and code and documentation generation interface methods are defined.
EOF
        short_description => 'contains bean attribute information',
        synopsis => "None. This is an abstract class.\n",
    },
    attr_opt => [
#        {
#            method_factory_name => 'method_factory_name',
#            type => 'SINGLE',
#            mandatory => 1,
#            allow_empty => 0,
#            allow_rx => [qw(^\w+$)],
#            short_description => 'attribute\'s name',
#        },
        {
            method_factory_name => 'default_value',
            type => 'SINGLE',
            short_description => 'attribute default value',
        },
        {
            method_factory_name => 'documented',
            type => 'BOOLEAN',
            default_value => 1,
            short_description => 'the attribute is documented',
        },
        {
            method_factory_name => 'exception_class',
            type => 'SINGLE',
            allow_empty => 0,
            default_value => 'Error::Simple',
            short_description => 'the class to throw when an exception occurs',
        },
        {
            method_factory_name => 'mandatory',
            type => 'BOOLEAN',
            default_value => 0,
            short_description => 'the attribute is mandatory for construction',
        },
        {
            method_factory_name => 'method_base',
            type => 'SINGLE',
            short_description => 'the method base name',
        },
#        {
#            method_factory_name => 'perl_bean',
#            type => 'SINGLE',
#            allow_isa => [qw(PerlBean)],
#            short_description => 'the PerlBean to which this attribute belongs',
#        },
        {
            method_factory_name => 'short_description',
            type => 'SINGLE',
            short_description => 'the attribute description',
        },
    ],
    meth_opt => [
        {
            method_name => 'get_package',
            description => <<EOF,
Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.
EOF
            body => <<'EOF',
    my $self = shift;

    defined( $self->get_perl_bean() ) || return('main');
    return( $self->get_perl_bean()->get_package() );
EOF
        },
        {
            method_name => 'get_package_us',
            description => <<EOF,
Calls C<get_package()> and replaces C<:+> with C <_>.
EOF
            body => <<'EOF',
    my $self = shift;

    my $pkg = $self->get_package();
    $pkg =~ s/:+/_/g;
    return($pkg);
EOF
        },
        {
            method_name => 'create_methods',
#            description => <<EOF,
#Returns a list containing the access methods for the attribute.
#EOF
            interface => 1,
        },
        {
            method_name => 'write_allow_isa',
            documented => 0,
            interface => 1,
            description => <<EOF,
Returns a C<\%ALLOW_ISA> line string for the attribute.
EOF
        },
        {
            method_name => 'write_allow_ref',
            documented => 0,
            interface => 1,
            description => <<EOF,
Returns a C<\%ALLOW_REF> line string for the attribute.
EOF
        },
        {
            method_name => 'write_allow_rx',
            documented => 0,
            interface => 1,
            description => <<EOF,
Returns a C<\%ALLOW_RX> line string for the attribute.
EOF
        },
        {
            method_name => 'write_allow_value',
            documented => 0,
            interface => 1,
            description => <<EOF,
Returns a C<\%ALLOW_VALUE> line string for the attribute.
EOF
        },
        {
            method_name => 'write_default_value',
            description => <<'EOF',
Returns a C<%DEFAULT_VALUE> line string for the attribute.
EOF
            interface => 1,
        },
        {
            method_name => 'write_constructor_option_code',
            description => <<EOF,
Writes constructor code for the attribute option.
EOF
            interface => 1,
        },
        {
            method_name => 'write_constructor_option_doc',
            description => <<EOF,
Writes constructor documentation for the attribute option.
EOF
            interface => 1,
        },
        {
            method_name => '_esc_apos',
            documented => 0,
            description => <<EOF,
Escapes apostrophes in string
EOF
            body => <<'EOF',
    my $self = shift;

    my @in = @_;
    my @el = ();
    foreach my $el (@in) {
        if ( $el =~ /^[+-]?\d+$/ ) {
            $el = ( int($el) );
        }
        else {
            $el =~ s/'/\\'/g;
            $el = '\'' . $el . '\'';
        }
        push( @el, $el );
    }
    if (wantarray) {
        return(@el);
    }
    else {
        return( join( ', ', @el ) );
    }
EOF
        },
        {
            method_name => '_esc_aq',
            documented => 0,
            description => <<EOF,
Escapes apostrophes and quotes in string
EOF
            body => <<'EOF',
    my $self = shift;

    my $do_quote = 0;
    foreach my $el (@_) {
        if ($el =~ /[\n\r\t\f\a\e]/) {
            $do_quote = 1;
            last;
        }
    }

    if (wantarray) {
        return (
            $do_quote ?
                ( $self->_esc_quote(@_) ) :
                ( $self->_esc_apos(@_) )
        );
    }
    else {
        return (
            $do_quote ?
                scalar( $self->_esc_quote(@_) ) :
                scalar( $self->_esc_apos(@_) )
        );
    }
EOF
        },
        {
            method_name => '_esc_quote',
            documented => 0,
            description => <<EOF,
Escapes quotes in string
EOF
            body => <<'EOF',
    my $self = shift;

    my @in = @_;
    my @el = ();
    foreach my $el (@in) {
        if ( $el =~ /^[+-]?\d+$/ ) {
            $el = ( int($el) );
        }
        else {
            $el =~ s/\\/\\\\/g;
            $el =~ s/\n/\\n/g;
            $el =~ s/\r/\\r/g;
            $el =~ s/\t/\\t/g;
            $el =~ s/\f/\\f/g;
            $el =~ s/\a/\\a/g;
            $el =~ s/\e/\\e/g;
            $el =~ s/([\$\@\%"])/\\$1/g;
            $el = '"' . $el . '"';
        }
        push( @el, $el );
    }
    if (wantarray) {
        return(@el);
    }
    else {
        return( join( ', ', @el ) );
    }
EOF
        },
        {
            method_name => '_get_overloaded_attribute',
            documented => 0,
            description => <<EOF,
Searches superclass packages for an identically named C<PerlBean::Attribute>. If found it is returned otherwise C<undef> is returned.
EOF
            body => <<'EOF',
    my $self = shift;

    # No attribute found if no collection defined
    defined( $self->get_perl_bean() ) || return(undef);
    defined( $self->get_perl_bean()->get_collection() ) || return(undef);

    # Look for the attribute in super classes
    foreach my $super_pkg ( $self->get_perl_bean()->get_base() ) {
        # Get the super class bean
        my $super_bean = ( $self->get_perl_bean()->get_collection()->
                                            values_perl_bean($super_pkg) )[0];

        # If the super class bean has no bean in the collection then no
        # attribute is found
        defined($super_bean) || return(undef);

        # See if the super class bean has an attribute
        my $attr_over = $super_bean->_get_overloaded_attribute( $self, {
            $self->get_perl_bean()->get_package() => 1,
        } );

        # Return the overloaded bean if found
        defined($attr_over) && return($attr_over);
    }

    # Nothing found
    return(undef);
EOF
        },
        {
            method_name => 'type',
            description => <<EOF,
Determines and returns the type of the attribute. The type is either C<BOOLEAN>, C<SINGLE> or C<MULTI>.
EOF
            body => <<'EOF',
    my $self = shift;

    $self->isa('PerlBean::Attribute::Boolean') && return('BOOLEAN');
    $self->isa('PerlBean::Attribute::Multi') && return('MULTI');
    $self->isa('PerlBean::Attribute::Single') && return('SINGLE');
EOF
        },
        {
            method_name => 'mk_doc_clauses',
            description => <<EOF,
Returns a string containing the documentation for the clauses to which the contents the contents of the attribute must adhere.
EOF
            body => <<'THE_EOF',
    my $self = shift;

    return('') if ( ! scalar( $self->values_allow_isa() ) &&
        ! scalar( $self->values_allow_ref() ) &&
        ! scalar( $self->values_allow_rx() ) &&
        ! scalar( $self->values_allow_value() )
    );

    # Make the clauses for documentation
    my $doc = <<EOF;
\=over

EOF

    $doc .= $self->mk_doc_clauses_allow_isa(@_);
    $doc .= $self->mk_doc_clauses_allow_ref(@_);
    $doc .= $self->mk_doc_clauses_allow_rx(@_);
    $doc .= $self->mk_doc_clauses_allow_value(@_);

    $doc .= <<EOF;
\=back

EOF

    # Return the clauses for documentation
    return($doc);
THE_EOF
        },
    ],
    sym_opt => [
        {
            symbol_name => '$LEGACY_COUNT',
            comment => <<EOF,
# Legacy count variable
EOF
            assignment => "0;\n",
        },
    ],
    use_opt => [
        {
            dependency_name => 'PerlBean::Style',
            import_list => [ 'qw(:codegen)' ],
        },
    ],
} );

1;
