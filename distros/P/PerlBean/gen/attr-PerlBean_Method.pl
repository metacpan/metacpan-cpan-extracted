use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'Abstract PerlBean method information',
        package => 'PerlBean::Method',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Method> class for bean method information.
EOF
        short_description => 'contains bean method information',
        #synopsis => '???',
    },
    attr_opt => [
        {
            method_factory_name => 'body',
            type => 'SINGLE',
            allow_rx => [qw(.*)],
            short_description => 'the method\'s body',
        },
        {
            method_factory_name => 'exception_class',
            type => 'SINGLE',
            allow_empty => 0,
            default_value => 'Error::Simple',
            short_description => 'the class to throw in eventual interface implementations',
        },
        {
            method_factory_name => 'interface',
            type => 'BOOLEAN',
            short_description => 'the method is defined as interface',
        },
        {
            method_factory_name => 'method_name',
            type => 'SINGLE',
            mandatory => 1,
            allow_empty => 0,
            allow_rx => [qw(^\w+$)],
            short_description => 'the method\'s name',
        },
        {
            method_factory_name => 'parameter_description',
            type => 'SINGLE',
            short_description => 'the parameter description',
        },
        {
            method_factory_name => 'perl_bean',
            type => 'SINGLE',
            allow_isa => [qw(PerlBean)],
            short_description => 'the PerlBean to which this method belongs',
        },
        {
            method_factory_name => 'description',
            type => 'SINGLE',
            short_description => 'the method description',
        },
        {
            method_factory_name => 'documented',
            type => 'BOOLEAN',
            default_value => 1,
            short_description => 'the method is documented',
        },
        {
            method_factory_name => 'implemented',
            type => 'BOOLEAN',
            default_value => 1,
            short_description => 'the method is implemented',
        },
        {
            method_factory_name => 'volatile',
            type => 'BOOLEAN',
            short_description => 'the method is volatile',
        },
    ],
    meth_opt => [
        {
            method_name => 'write_code',
            parameter_description => 'FILEHANDLE',
            description => <<EOF,
Write the code for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'THE_EOF',
    my $self = shift;
    my $fh = shift;

    # Do nothing if not implemented
    $self->is_implemented() || return;

    my $name = $self->get_method_name();
    my $ec = $self->get_exception_class();
    my $body = $self->is_interface() ?
            "${IND}throw $ec${BFP}(\"ERROR: " .
            $self->get_package() .
            '::' .
            $self->get_method_name() .
            ", call this method in a subclass that has implemented it.\");\n"
        : '';
    $body = defined( $self->get_body() ) ? $self->get_body() : $body;
    $fh->print(<<EOF);
$SUB $name${PBOC[0]}{
$body}

EOF
THE_EOF
        },
        {
            method_name => 'write_pod',
            parameter_description => 'FILEHANDLE',
            description => <<EOF,
Write the documentation for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'THE_EOF',
    my $self = shift;
    my $fh = shift;
    my $pkg = shift;

    # Do nothing if not documented
    $self->is_documented() || return;

    my $name = $self->get_method_name();
    my $pre = '';
    my $par = $self->get_parameter_description();
    my $desc = $self->get_description() || "\n";;
    if ( $pkg eq $self->get_package() ) {
        if ( $self->is_interface() ) {
            $pre = "This is an interface method. ";
        }
        else {
            my $super_meth = $self->_get_super_method();
            if ( defined($super_meth) ) {
                if ( $super_meth->is_interface() ) {
                    $pre = "This method is an implementation from package C<" .
                        $super_meth->get_package() . ">. ";
                }
                elsif( ! $self->isa('PerlBean::Method::Constructor') ) {
                    $pre = "This method is overloaded from package C<" .
                        $super_meth->get_package() . ">. ";
                }
            }
        }
    }
    elsif( ! $self->isa('PerlBean::Method::Constructor') ) {
        $pre = "This method is inherited from package C<" .
            $self->get_package() . ">. ";
    }
    $fh->print(<<EOF);
\=item $name${BFP}($par)

$pre$desc
EOF
THE_EOF
        },
        {
            method_name => '_get_super_method',
            documented => 0,
            description => <<EOF,
Search the superclass hierarchy for an identically named C<PerlBean::Method> and return it. If no method is found C<undef> is returned.
EOF
            body => <<'THE_EOF',
    my $self = shift;

    # No super method found if no collection defined
    defined( $self->get_perl_bean() ) || return(undef);
    defined( $self->get_perl_bean()->get_collection() ) || return(undef);

    # Look for the method in super classes
    foreach my $super_pkg ( $self->get_perl_bean()->get_base() ) {
        # Get the superclass bean
        my $super_bean = ( $self->get_perl_bean()->get_collection()->values_perl_bean($super_pkg) )[0];

        # If the super class bean has no bean in the collection then no method is found
        defined($super_bean) || return(undef);

        # See if the super class bean has the method
        my $super_meth = $super_bean->_get_super_method( $self, {
            $self->get_perl_bean()->get_package() => 1,
        } );

        # Return the suprclass method if found
        defined($super_meth) && return($super_meth);
    }

    # Nothing found
    return(undef);
THE_EOF
        },
        {
            method_name => 'get_package',
            description => <<EOF,
Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.
EOF
            body => <<'EOF',
    my $self = shift;

    # Get the package name from the PerlBean
    defined( $self->get_perl_bean ) &&
        return( $self->get_perl_bean()->get_package() );

    # Return 'main' as default
    return('main');
EOF
        },
    ],
    sym_opt => [
        {
            symbol_name => '$SUB',
            comment => <<EOF,
# Variable to not confuse AutoLoader
EOF
            assignment => "'sub';\n",
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
