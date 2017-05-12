#!/usr/bin/perl
use warnings;
use strict;
{
    package OOP::Perlish::Class::Accessor::UnitTests::Hash;
    use warnings;
    use strict;
    use OOP::Perlish::Class::Accessor::UnitTests::Base;
    use base 'OOP::Perlish::Class::Accessor::UnitTests::Base';
    use OOP::Perlish::Class::Accessor;
    use Test::More;
    use Data::Dumper;

    sub get_value
    {
        my ($self) = @_;

        my %values = $self->{accessor}->value();
        return( %values );
    }

    # Utility function to test positive/negative assignment for validators
    # Adds 2 + N to your test count
    sub use_validator(@)
    {
        my ( $self, %values ) = @_;

        $self->{accessor}->value(%values);
        $self->compare_values_to_hash(%values);

        $self->{accessor}->value( 'invalid1' => 'invalid1', 'invalid2' => 'invalid2', 'invalid3' => 'invalid3' );
        my %compare_values = $self->get_value();
        is( scalar keys(%compare_values), 0, 'we pass negative assertion of validation' );
    }

    # Utility function for testing equality
    # Adds 1 + N to test count
    sub compare_values_to_hash(@)
    {
        my ( $self, %values ) = @_;

        my %test_values = $self->get_value();

        is( scalar keys %test_values, scalar keys %values, 'we pass positive assertion of validation' );
        while( my ( $k, $v ) = each %values ) {
            is( $test_values{$k}, $v, "possitive assertion that \$test_values{$k} == \$values{$k}" );
        }
    }

    sub setup : Test(setup)
    {
        my ($self) = @_;
        $self->{accessor} = OOP::Perlish::Class::Accessor->new( type => 'HASH', name => 'test', self => bless( {}, __PACKAGE__ ) );
    }

    sub test_type_with_hash(@) : Test(5)
    {
        my ($self) = @_;
        my %values = ( 'foo' => 'bar', 'bar' => 'baz', 'baz' => 'bup', 'bup' => 'quux' );

        $self->{accessor}->value(%values);
        $self->compare_values_to_hash(%values);
    }

    sub test_type_with_hashref(@) : Test(5)
    {
        my ($self) = @_;
        my %values = ( 'foo' => 'bar', 'bar' => 'baz', 'baz' => 'bup', 'bup' => 'quux' );

        $self->{accessor}->value( \%values );
        $self->compare_values_to_hash(%values);
    }

    sub test_negative_assertion_type : Test
    {
        my ($self) = @_;
        
        $self->{accessor}->value( [ 'foo', 'bar' ] );
        ok( ! $self->get_value(), "negative assertion for type with non-hash" );
    }

    sub test_setting_hash_with_regex_validator(@) : Test(6)
    {
        my ($self) = @_;
        my %values = ( 'foo' => 'test1', 'bar' => 'test2', 'baz' => 'test3', 'bup' => 'test4' );

        $self->{accessor}->validator(qr/.*test.*/i);
        $self->use_validator(%values);
    }

    sub test_setting_hash_with_sub_validator(@) : Test(6)
    {
        my ($self) = @_;
        my %values = ( 'foo' => 'test1', 'bar' => 'test2', 'baz' => 'test3', 'bup' => 'test4' );

        $self->{accessor}->validator(
            sub {
                my ( $self, %values ) = @_;
                my %checked = ();
                while( my ( $k, $v ) = each %values ) { return unless( $v =~ m/^(.*test.*)$/ ); $checked{$k} = $1 }
                return %checked;
            }
        );
        $self->use_validator(%values);
    }

    sub unset_value : Test
    {
        my ($self) = @_;

        my %test = $self->get_value();
        ok( ! keys %test, 'we get an empty list when nothing has been set' ) || diag( Dumper( { %test } ) );
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
