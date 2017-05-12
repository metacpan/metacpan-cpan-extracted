#!/usr/bin/perl
{
	package OOP::Perlish::Class::Multiton::UnitTests::Test1;
	use OOP::Perlish::Class::Multiton;
	use base qw(OOP::Perlish::Class::Multiton);

	BEGIN {
		__PACKAGE__->_accessors(
			thing => { type => 'SCALAR', validator => qr/.*foo.*/, required => 1 },
		);
	}

	sub _multiton_key { return 'thing' };
}

{
    package OOP::Perlish::Class::Multiton::UnitTests::Multiton;
    use base Test::Class;
    use Test::More;

    sub multitons : Test(10)
    {
        my ($self) = @_;

        my $a = OOP::Perlish::Class::Multiton::UnitTests::Test1->new( thing => 'hello foo' );
        my $b = OOP::Perlish::Class::Multiton::UnitTests::Test1->new( thing => 'goodbye foo' );
        my $c = OOP::Perlish::Class::Multiton::UnitTests::Test1->new( thing => 'hello foo' );
        my $d = OOP::Perlish::Class::Multiton::UnitTests::Test1->new( thing => 'goodbye foo' );

        is($a, $c, 'Multitons of the same key are the same a => c');
        is($b, $d, 'Multitons of the same key are the same b => d');

        is($a->thing(), $c->thing(), 'Multitons of the same key have the same thing a => c');
        is($b->thing(), $d->thing(), 'Multitons of the same key have the same thing b => d');

        ok( $a != $b,  'Multitons of different keys are unique a => b');
        ok( $b != $c,  'Multitons of different keys are unique b => c');
        ok( $c != $d,  'Multitons of different keys are unique c => d');


        ok( $a->thing() ne $b->thing(),  'Multitons of different keys have unique things a(' . $a->thing() . ') => b(' . $b->thing() . ')');
        ok( $b->thing() ne $c->thing(),  'Multitons of different keys have unique things b(' . $b->thing() . ') => c(' . $c->thing() . ')');
        ok( $c->thing() ne $d->thing(),  'Multitons of different keys have unique things c(' . $c->thing() . ') => d(' . $d->thing() . ')');
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
