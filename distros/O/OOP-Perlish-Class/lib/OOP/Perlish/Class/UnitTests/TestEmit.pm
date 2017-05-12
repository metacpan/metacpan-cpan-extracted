{
    package OOP::Perlish::Class::UnitTests::TestEmit;
    use warnings;
    use strict;
    use Test::Class;
    use Test::More;
    use OOP::Perlish::Class::UnitTests::Base;
    use base qw(OOP::Perlish::Class::UnitTests::Base);

    sub setup : Test(setup)
    {
        my ($self) = @_;

        $self->{obj} = OOP::Perlish::Class::UnitTests::Baz::Foo::Bar->new( bar => 'bar' );

        $self->{obj}->_emitlevel(9);
        $self->{string} = '';

        close STDERR;
        open(STDERR, '>', \$self->{string} ); 
    }

    sub test_emit
    {
        my ($self, $level) = @_;

        $self->{obj}->$level('Hello world ' . $level);
        is($self->{string}, uc($level) . ': ' . 'Hello world ' . $level . $/, $level . ' output correctly');
    }

    sub testerror : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('error');
    }

    sub testwarning : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('warning');
    }

    sub testinfo : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('info');
    }

    sub testverbose : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('verbose');
    }

    sub testdebug : Test(1)
    {
        my ($self) = @_;

        $self->{obj}->debug('Hello world debug');
        is($self->{string}, 'DEBUG0: ' . 'Hello world debug' . $/, 'debug output correctly');
    }

    sub testdebug1 : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('debug1');
    }

    sub testdebug2 : Test(1)
    {
        my ($self) = @_;
        $self->test_emit('debug2');
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
