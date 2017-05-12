{
    package OOP::Perlish::Class::Accessor::UnitTests::Scalar;
    use OOP::Perlish::Class::Accessor::UnitTests::Base;
    use base qw(OOP::Perlish::Class::Accessor::UnitTests::Base);
    use OOP::Perlish::Class::Accessor;
    use Test::More;
    use Data::Dumper;

    sub setup : Test(setup)
    {
        my ($self) = @_;
        $self->{accessor} = OOP::Perlish::Class::Accessor->new( type => 'SCALAR', name => 'test', self => bless({}, __PACKAGE__) );
    }

    sub get_value
    {
        my ($self) = @_;
        return $self->{accessor}->value();
    }


    # Utility function to test positive/negative assignment for validators
    sub use_validator(@) {
        my ($self, $value) = @_;

        $self->{accessor}->value($value);
        is($self->get_value(), $value, 'we pass positive assertion for validation');

        $self->{accessor}->value('invalid');
        ok( ! $self->get_value(), 'we pass negative assertion for validation');
    }

    sub test_negative_assertion_type : Test
    {
        my ($self) = @_;
        
        $self->{accessor}->value('foo' => 'bar');
        ok( ! $self->get_value(), "Cannot set value with invalid type" );
    }

    sub test_negative_assertion_type_ref : Test
    {
        my ($self) = @_;

        $self->{accessor}->value([ 'foo' ]);
        ok( ! $self->get_value(), "Cannot set type with a reference to a non-scalar-type" );
    }

    sub test_type_with_scalar: Test
    {
        my ($self) = @_;

        $self->{accessor}->value('foo');
        is( $self->get_value(), 'foo', 'Value is set with scalar' );
    }

    sub test_type_with_ref : Test
    {
        my ($self) = @_;
		my $refscalar = 'foo';

        $self->{accessor}->value(\$refscalar);
        is( $self->get_value(), 'foo', 'value is set with scalar ref');
    }

    sub test_setting_with_regex_validator(@) : Test(2)
    {
        my ($self) = @_;
        $self->{accessor}->validator( qr/.*test.*/i );

        $self->use_validator("test");
    }

    sub test_setting_with_sub_validator(@) : Test(2)
    {
        my ($self) = @_;

        $self->{accessor}->validator( sub { my ($self, $value) = @_; $value eq 'hello' && return $value; return } );
        $self->use_validator("hello");
    }

    sub unset_value : Test
    {
        my ($self) = @_;
        my $undef = $self->get_value(); 
        ok( ! $undef, 'when nothing has been defined, we get undef for scalar' ) || diag(Dumper($undef));
    }
}
1;
=head1 NAME

=head1 VERSION

=head1 SYNOPSIS

=head1 METHODS

=head1 AUTHOR

Jamie Beverly, C<< <jbeverly at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-foo-bar at rt.cpan.org>,
or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OOP-Perlish-Class>.  I will be
notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OOP::Perlish::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OOP-Perlish-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OOP-Perlish-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OOP-Perlish-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/OOP-Perlish-Class/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jamie Beverly

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
