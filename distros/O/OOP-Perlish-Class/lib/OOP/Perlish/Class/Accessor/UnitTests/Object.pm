{
    package OOP::Perlish::Class::Accessor::UnitTests::Object;
    use OOP::Perlish::Class::Accessor::UnitTests::Base;
    use base qw(OOP::Perlish::Class::Accessor::UnitTests::Base);
    use OOP::Perlish::Class::Accessor;
    use Test::More;
    use IO::Handle;
    use Getopt::Long;
    use File::Temp;

    sub setup : Test(setup)
    {
        my ($self) = @_;
        $self->{accessor} = OOP::Perlish::Class::Accessor->new( type => 'OBJECT', name => 'test', self => bless({}, __PACKAGE__) );
    }

    sub set_object : Test
    {
        my ($self) = @_;

        my $obj = IO::Handle->new();

        $self->{accessor}->value($obj);
        is($self->{accessor}->value(), $obj, 'can set an object');
    }

    sub negative_assertion_set_object : Test
    {
        my ($self) = @_;

        $self->{accessor}->value('foo');
        ok( ! $self->{accessor}->value(), 'Negative assertion: cannot set something that is not an object' ) || diag( $self->{accessor}->value() );
    }

    sub polymorphism : Test
    {
        my ($self) = @_;

        my $obj = IO::Handle->new();
        $self->{accessor}->object_can(['fileno','fdopen','close']);

        $self->{accessor}->value($obj);
        is($self->{accessor}->value(), $obj, 'can set an object matching object_can');
    }

    sub negative_assert_polymorphism : Test
    {
        my ($self) = @_;

        my $obj = Getopt::Long::Parser->new();
        $self->{accessor}->object_can(['fileno','fdopen','close']);

        $self->{accessor}->value($obj);
        ok( ! $self->{accessor}->value(), 'Negative assertion: cannot set an object not matching object_can');
    }

    sub negative_assert_derived : Test
    {
        my ($self) = @_;

        my $obj = Getopt::Long::Parser->new();
        $self->{accessor}->object_isa(['IO::Handle']);

        $self->{accessor}->value($obj);
        ok( ! $self->{accessor}->value(), 'Negative assertion: cannot set an object not matching object_isa');
    }

    sub derived : Test
    {
        my ($self) = @_;

        my $obj = File::Temp->new();
        $self->{accessor}->object_isa(['IO::Handle']);

        $self->{accessor}->value($obj);
        is( $self->{accessor}->value(), $obj, 'can set an object not matching object_isa');
    }

    sub validator : Test
    {
        my ($self) = @_;

        my $obj = File::Temp->new();
        $self->{accessor}->validator(qr/.*Temp.*/);

        $self->{accessor}->value($obj);
        is( $self->{accessor}->value(), $obj, 'can set an object matching regexp');
    }

    sub negative_validator : Test
    {
        my ($self) = @_;

        my $obj = IO::Handle->new();
        $self->{accessor}->validator(qr/.*Temp.*/);

        $self->{accessor}->value($obj);
        ok( ! $self->{accessor}->value(), 'Negative assert: cannot set an object not matching regexp');
    }

    sub validator_sub : Test
    {
        my ($self) = @_;

        my $obj = File::Temp->new();
        $self->{accessor}->validator(sub { my ($self, $o) = @_; ref($o) =~ m/File::Temp/ && return $o; return });

        $self->{accessor}->value($obj);
        is( $self->{accessor}->value(), $obj, 'can set an object matching sub');
    }

    sub negative_validator_sub : Test
    {
        my ($self) = @_;

        my $obj = IO::Handle->new();
        $self->{accessor}->validator(sub { my ($self, $o) = @_; ref($o) =~ m/File::Temp/ && return $o; return });

        $self->{accessor}->value($obj);
        ok( ! $self->{accessor}->value(), 'Negative assert: cannot set an object not matching sub');
    }

    sub implementation : Test
    {
        my ($self) = @_;

        $self->{accessor}->implements([ 'IO::Handle' ]);

        my $obj = IO::Handle->new();
        $self->{accessor}->value($obj);
        is($self->{accessor}->value(), $obj, 'can set an object matching implementation');
    }

    sub negative_assert_implementation : Test
    {
        my ($self) = @_;

        $self->{accessor}->implements(['IO::Handle']);

        my $obj = Getopt::Long::Parser->new();
        $self->{accessor}->value($obj);
        ok( ! $self->{accessor}->value(), 'Negative assertion: cannot set an object not matching implementation');
    }

    sub unset_value : Test
    {
        my ($self) = @_;
        my $undef = $self->{accessor}->value();
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
