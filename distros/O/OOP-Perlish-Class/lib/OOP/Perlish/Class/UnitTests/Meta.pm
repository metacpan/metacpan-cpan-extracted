#!/usr/bin/perl
use warnings;
use strict;
{
	package OOP::Perlish::Class::Meta::UnitTests::Foo;
    use OOP::Perlish::Class;
    use base 'OOP::Perlish::Class';

    sub foo
    {
        return;
    }
}
{
	package OOP::Perlish::Class::Meta::UnitTests::Bar;
	use base 'OOP::Perlish::Class::Meta::UnitTests::Foo';
    sub bar 
    {
        return;
    }
}
{
	package OOP::Perlish::Class::Meta::UnitTests::Baz; 
	use base 'OOP::Perlish::Class::Meta::UnitTests::Bar';
    sub baz 
    {
        return;
    }
}
{
	package OOP::Perlish::Class::Meta::UnitTests::Quux;
	use base qw(OOP::Perlish::Class::Meta::UnitTests::Baz OOP::Perlish::Class::Meta::UnitTests::Bar);

    sub quux
    {
        return;
    }
}
{
	package OOP::Perlish::Class::Meta::UnitTests::Thud;
	use base qw(OOP::Perlish::Class::Meta::UnitTests::Quux OOP::Perlish::Class::Meta::UnitTests::Foo);

    sub thud
    {
        return;
    }
}

{
    package OOP::Perlish::Class::UnitTests::Meta;
    use base qw(Test::Class);
    use Test::More;

    sub all_isa : Test(7)
    {
        my ($self) = @_;

        my $n = OOP::Perlish::Class::Meta::UnitTests::Thud->new();
        my @correct = ( 'OOP::Perlish::Class::Meta::UnitTests::Thud', 'OOP::Perlish::Class::Meta::UnitTests::Quux', 'OOP::Perlish::Class::Meta::UnitTests::Baz', 'OOP::Perlish::Class::Meta::UnitTests::Bar', 'OOP::Perlish::Class::Meta::UnitTests::Foo', 'OOP::Perlish::Class', ); # results are in order depth-last by Tie::IxHash
        my @results = $n->_all_isa();

        is(scalar @results, scalar @correct, 'We have the right number of results');
        for(my $i=0; $i < scalar @results; $i++) {
            is($results[$i], $correct[$i], "$results[$i] == $correct[$i]");
        }
    }

    sub all_methods : Test(5)
    {
        my $n = OOP::Perlish::Class::Meta::UnitTests::Thud->new();
        my @correct = ( 'thud', 'bar', 'baz', 'quux', 'foo' );
        my @results = $n->_all_methods();
        my %results_lut;
        @results_lut{ @results } = undef;

        for(@correct) { 
            ok( exists($results_lut{$_}), "We have $_ in our list of methods" );
        }
    }

    sub all_methods_external : Test(5)
    {
        my $n = OOP::Perlish::Class::Meta::UnitTests::Foo->new();
        my @correct = ( 'thud', 'bar', 'baz', 'quux', 'foo' );
        my @results = $n->_all_methods('OOP::Perlish::Class::Meta::UnitTests::Thud');
        my %results_lut;
        @results_lut{ @results } = undef;

        for(@correct) { 
            ok( exists($results_lut{$_}), "We have $_ in our list of methods" );
        }
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
