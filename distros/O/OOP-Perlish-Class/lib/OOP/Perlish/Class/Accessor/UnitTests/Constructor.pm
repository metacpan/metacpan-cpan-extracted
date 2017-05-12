{

    package OOP::Perlish::Class::Accessor::UnitTests::Constructor;
    use Test::Class;
    use base qw(Test::Class);

    use OOP::Perlish::Class::Accessor;
    use Test::More;

    sub invalid_type : Test
    {
        my ($self) = @_;
        eval { OOP::Perlish::Class::Accessor->new( type => 'ASDF', name => 'test' ); };
        ok( "$@" =~ m/Invalid type specified/gsm, "We confess on invalid type" );
    }

    sub missing_type : Test
    {
        my ($self) = @_;
        eval { OOP::Perlish::Class::Accessor->new( name => 'test' ); };
        ok( "$@" =~ m/Missing required field type/gsm, "We confess on missing required 'type' parameter" ) || diag("$@");
    }

    sub missing_name : Test
    {
        my ($self) = @_;
        eval { OOP::Perlish::Class::Accessor->new( type => 'SCALAR' ); };
        ok( "$@" =~ m/Missing required field name/gsim, "We confess on missing required 'name' parameter" ) || diag("$@");
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
