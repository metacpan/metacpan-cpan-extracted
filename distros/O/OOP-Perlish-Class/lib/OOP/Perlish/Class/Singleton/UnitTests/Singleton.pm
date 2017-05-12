#!/usr/bin/perl

{
	package OOP::Perlish::Class::Singleton::UnitTests::Foo;
	use OOP::Perlish::Class::Singleton;
	use base qw(OOP::Perlish::Class::Singleton);
    
    BEGIN {
        __PACKAGE__->_accessors(
            bar => { type => 'SCALAR', validator => qr/.*bar.*/ },
        );
    };

	sub foo(@)
	{
		my $self = shift;
		return $self;
	}
}

{
    package OOP::Perlish::Class::Singleton::UnitTests::Singleton;
    use base qw(Test::Class);
    use Test::More;

    sub singletons : Test(7)
    {
        my ($self) = @_;

        my $a = OOP::Perlish::Class::Singleton::UnitTests::Foo->new( bar => 'bar-baz' );
        my $b = OOP::Perlish::Class::Singleton::UnitTests::Foo->new( bar => 'bar-fred' );
        my $c = OOP::Perlish::Class::Singleton::UnitTests::Foo->new();

        is($a, $b, 'Singleton instantiation a=>b');
        is($b, $c, 'Singleton instantiation b=>c');
        is($a->bar(), $b->bar(), 'Matching values a=>b');
        is($b->bar(), $c->bar(), 'Matching values b=>c');
        is($a->bar(), 'bar-baz', 'Initial constructor instantiation wins a');
        is($b->bar(), 'bar-baz', 'Initial constructor instantiation wins b');
        is($c->bar(), 'bar-baz', 'Initial constructor instantiation wins c');
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
