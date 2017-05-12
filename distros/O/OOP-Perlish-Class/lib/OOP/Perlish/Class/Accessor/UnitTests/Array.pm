#!/usr/bin/perl
use warnings;
use strict;
{
    package OOP::Perlish::Class::Accessor::UnitTests::Array;
    use warnings;
    use strict;
    use OOP::Perlish::Class::Accessor::UnitTests::Base;
    use base 'OOP::Perlish::Class::Accessor::UnitTests::Base';
    use OOP::Perlish::Class::Accessor;
    use Test::More;
    use Data::Dumper;

    sub setup : Test(setup)
    {
        my ($self) = @_;
        $self->{accessor} = OOP::Perlish::Class::Accessor->new( type => 'ARRAY', name => 'test', self => bless( {}, __PACKAGE__ ) );
    }

    sub get_value
    {
        my ($self) = @_;

        my @values = $self->{accessor}->value();
        return( @values );
    }

    # Utility function to test positive/negative assignment for validators
    # Adds 2 + N to your test count
    sub use_validator(@)
    {
        my ( $self, @values ) = @_;

        $self->{accessor}->value(@values);
        $self->compare_values_to_array(@values);

        $self->{accessor}->value( 'invalid1', 'invalid2', 'invalid3' );
        my @compare_values = $self->get_value();
        is( scalar @compare_values, 0, 'we pass negative assertion of validation' );
    }

    # Utility function for testing equality
    # Adds 1 + N to test count
    sub compare_values_to_array(@)
    {
        my ( $self, @values ) = @_;

        my @test_values = $self->get_value();

        is( scalar @test_values, scalar @values, 'we pass positive assertion of validation' );
        for(my $n=0; $n < scalar @values; $n++) {
            is( $values[$n], $test_values[$n], "possitive assertion that \$test_values[$n] == \$values[$n]" );
        }
    }

    sub test_type_with_array(@) : Test(5)
    {
        my ($self) = @_;
        my @values = ( 'foo', 'bar', 'baz', 'bup' );

        $self->{accessor}->value(@values);
        $self->compare_values_to_array(@values);
    }

    sub test_type_with_arrayref(@) : Test(5)
    {
        my ($self) = @_;
        my @values = ( 'foo', 'bar', 'baz', 'bup');

        $self->{accessor}->value( \@values );
        $self->compare_values_to_array(@values);
    }

    sub test_handling_of_references_to_other_types : Test(4) 
    {
        my ($self) = @_;
        my @values = ( {'foo' => 'bar' } );

        $self->{accessor}->value( @values );
        $self->compare_values_to_array( @values ); 
        
        @values = ( \'foo' );
        $self->{accessor}->value( @values );
        $self->compare_values_to_array( @values ); 
    }

    sub test_setting_array_with_regex_validator(@) : Test(6)
    {
        my ($self) = @_;
        my @values = ( 'test1', 'test2', 'test3', 'test4' );

        $self->{accessor}->validator(qr/.*test.*/i);
        $self->use_validator(@values);
    }

    sub test_setting_array_with_sub_validator(@) : Test(6)
    {
        my ($self) = @_;
        my @values = ( 'test1', 'test2', 'test3', 'test4' );

        $self->{accessor}->validator(
            sub {
                my ( $self, @values ) = @_;
                my @checked = ();
                for( @values ) { return unless( $_ =~ m/^(.*test.*)$/ ); push(@checked, $1) }
                return @checked;
            }
        );
        $self->use_validator(@values);
    }

    sub unset_value : Test
    {
        my ($self) = @_;

        my @test = $self->get_value();
        ok( ! @test, 'we get an empty list when nothing has been set' ) || diag( Dumper( [ @test ] ) );
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
