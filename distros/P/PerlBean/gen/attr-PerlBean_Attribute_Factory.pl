use strict;

push(@::bean_desc, {
    bean_opt => {
        abstract => 'C<PerlBean::Attribute> object factory',
        package => 'PerlBean::Attribute::Factory',
        use_perl_version => 5.005,
        description => <<EOF,
C<PerlBean::Attribute::Factory> objects create instances of C<PerlBean::Attribute> objects.
EOF
        short_description => 'factory package to generate C<PerlBean::Attribute> objects',
        synopsis => &get_syn(),
    },
    attr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'create_attribute',
            parameter_description => 'OPT_HASH_REF',
            description => <<EOF,
Returns C<PerlBean::Attribute> objects based on C<OPT_HASH_REF>. C<OPT_HASH_REF> is a hash reference used to pass initialization options. The selected subclass of C<PerlBean::Attribute> is initialized using C<OPT_HASH_REF>. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> used by this method may include:

=over

=item associative

Boolean flag. States that the returned attribute must be unique, associative C<MULTI>. Defaults to B<0>. Only makes sense if C<type> is B<MULTI> and B<unique> is true.

=item method_key

Boolean flag. States that the returned attribute must be unique, associative C<MULTI>. Defaults to B<0>. Only makes sense if C<type> is B<MULTI> and B<unique> is true.

=item ordered

Boolean flag. States that the returned attribute must be an ordered list. Defaults to B<0>. Only makes sense if C<type> is B<MULTI>.

=item type

If C<type> is B<BOOLEAN> a C<PerlBean::Attribute::Boolean>, on B<SINGLE> a C<PerlBean::Attribute::Single> and on B<MULTI> a C<PerlBean::Attribute::Multi> is returned. Defaults to B<'SINGLE'>. B<NOTE:> B<type> has precedence over B<ordered> and B<unique>.

=item unique

Boolean flag. States that the items in the C<MULTI> attribute must be unique. Defaults to B<0>. Only makes sense if C<type> is B<MULTI>.

=back

Options for C<OPT_HASH_REF> passed to package B<C<PerlBean::Attribute>> may include:

=over

=item B<C<default_value>>

Passed to L<set_default_value()>.

=item B<C<exception_class>>

Passed to L<set_exception_class()>. Defaults to B<'Error::Simple'>.

=item B<C<mandatory>>

Passed to L<set_mandatory()>. Defaults to B<0>.

=item B<C<method_base>>

Passed to L<set_method_base()>.

=item B<C<method_factory_name>>

Passed to L<set_method_factory_name()>. Mandatory option.

=item B<C<perl_bean>>

Passed to L<set_perl_bean()>.

=item B<C<short_description>>

Passed to L<set_short_description()>.

=back

Options for C<OPT_HASH_REF> passed to package B<C<PerlBean::Attribute::Single>> may include:

=over

=item B<C<allow_empty>>

Passed to L<set_allow_empty()>. Defaults to B<1>.

=item B<C<allow_isa>>

Passed to L<set_allow_isa()>. Must be an C<ARRAY> reference.

=item B<C<allow_ref>>

Passed to L<set_allow_ref()>. Must be an C<ARRAY> reference.

=item B<C<allow_rx>>

Passed to L<set_allow_rx()>. Must be an C<ARRAY> reference.

=item B<C<allow_value>>

Passed to L<set_allow_value()>. Must be an C<ARRAY> reference.

=back
EOF
            body => <<EOF,
    my \$self = shift;
    my \$opt = shift || {};

    # Switch attribute type
    if ( ! defined(\$opt->{type} ) || \$opt->{type} eq 'SINGLE') {
        require PerlBean::Attribute::Single;
        return( PerlBean::Attribute::Single->new(\$opt) );
    }
    elsif ( \$opt->{type} eq 'BOOLEAN' ) {
        require PerlBean::Attribute::Boolean;
        return( PerlBean::Attribute::Boolean->new(\$opt) );
    }
    elsif ( \$opt->{type} eq 'MULTI' ) {
        if ( \$opt->{unique} ) {
            if ( \$opt->{ordered} ) {
                require PerlBean::Attribute::Multi::Unique::Ordered;
                return( PerlBean::Attribute::Multi::Unique::Ordered->new(\$opt) );
            }
            elsif ( \$opt->{associative} ) {
                if ( \$opt->{method_key} ) {
                    require PerlBean::Attribute::Multi::Unique::Associative::MethodKey;
                    return( PerlBean::Attribute::Multi::Unique::Associative::MethodKey->new(\$opt) );
                }
                else {
                    require PerlBean::Attribute::Multi::Unique::Associative;
                    return( PerlBean::Attribute::Multi::Unique::Associative->new(\$opt) );
                }
            }
            else {
                require PerlBean::Attribute::Multi::Unique;
                return( PerlBean::Attribute::Multi::Unique->new(\$opt) );
            }
        }
        else {
            require PerlBean::Attribute::Multi::Ordered;
            return( PerlBean::Attribute::Multi::Ordered->new(\$opt) );
        }
    }
    else {
        throw Error::Simple("ERROR: PerlBean::Attribute::Factory::attribute, option 'type' must be one of 'BOOLEAN', 'SINGLE' or 'MULTI' and NOT '\$opt->{type}'.");
    }
EOF
        },
    ],
} );

sub get_syn {
    use IO::File;
    my $fh = IO::File->new('< syn-PerlBean_Attribute_Factory.pl');
    $fh = IO::File->new('< gen/syn-PerlBean_Attribute_Factory.pl') if (! defined($fh));
    my $syn = '';
    my $prev_line = $fh->getline ();
    while (my $line = $fh->getline ()) {
        $syn .= ' ' . $prev_line;
        $prev_line = $line;
    }
    return($syn);
}

1;
