package Test::Able::Runner::Role::Meta::Class;
use Moose::Role;

=head1 NAME

Test::Able::Runner::Role::Meta::Class - metaclass role for test runners

=head1 DESCRIPTION

This class provides the real guts for loading the test objects to run. However, you probably don't need to use it directly unless you are doing something fancy. See L<Test::Able::Runner> for the usual cases.

=head1 ATTRIBUTES

=head2 base_package

This is set by the C<< -base_package >> option sent to C<< use_test_packages >>. A C<< has_base_package >> predicate will tell you if this has been set.

=cut

has base_package => (
    is        => 'rw',
    isa       => 'ArrayRef[Str] | Str',
    predicate => 'has_base_package',
);

=head2 test_packages

This is set by the C<< -test_packages >> option sent to C<< use_test_packages >>. A C<< has_test_packages >> predicate will tell you if this has been set.

=cut

has test_packages => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_test_packages',
);

=head2 test_path

This is set by teh C<< -test_path >> option sent to C<< use_test_packages >>.

=cut

has test_path => (
    is        => 'rw',
    isa       => 'ArrayRef[Str] | Str | Undef ',
    default   => sub { 't/lib' },
);

=head1 METHODS

=head2 test_classes

This returns all the packages that will be loaded for testing. This does not filter classes out that have C<< $NOT_A_TEST >> set.

This will search for test classes if L</base_package> has been set or it return the contents of L</test_packages>.

=cut

sub test_classes {
    my $meta = shift;

    # Use Module::Pluggable to find the test classes
    if ($meta->has_base_package) {
        my $base_package = $meta->base_package;
        $meta->search_path( 
            new => (ref $base_package ? @$base_package : $base_package) 
        );
        return $meta->test_modules;
    }

    # Use the exact list given
    elsif ($meta->has_test_packages) {
        return @{ $meta->test_packages };
    }

    # Probably shouldn't happen...
    return ();
}

=head2 build_test_objects

This method returns all the test objects that should be run by this runner. It works by doing the following:

=over

=item 1

It retrieves a list of potential test classes using L</test_classes>. 

=item 2

It checks each package and throws away those with a package global variable named C<< $NOT_A_TEST >> that has been set to a true value. 

=item 3

It instantiates the test classes and returns an arrayref of those test objects.

=back

=cut

sub build_test_objects {
    my $meta = shift;

    # Insert our test paths into the front of the @INC search path
    if (defined $meta->test_path) {
        my $test_path = $meta->test_path;
        unshift @INC, (ref $test_path ? @$test_path : $test_path);
    }

    # Load all the test objects
    my @test_objects;
    PACKAGE: for my $test_class ($meta->name, $meta->test_classes) {

        # Attempt to load the classes
        unless (Class::MOP::load_class($test_class)) {
            warn $@ if $@;
            warn "FAILED TO LOAD $test_class. Skipping.";
            next PACKAGE;
        }

        # Only Test::Able::Objects are tests we want
        next PACKAGE unless $test_class->isa('Test::Able::Object');

        # Make sure this test has not been excluded
        {
            no strict 'refs';
            next PACKAGE if ${$test_class."::NOT_A_TEST"};
        }

        # Instantiate and add the test to the list
        push @test_objects, $test_class->new;
    }

    # Return the tests
    return \@test_objects;
}

=head2 setup_test_objects

Calls L</build_test_objects> and sets the C<test_objects> accessor from L<Test::Able::Role::Meta::Class>.

=cut

sub setup_test_objects {
    my $meta = shift;
    $meta->test_objects($meta->build_test_objects);
};

# Use Module::Pluggable to find tests for us
use Module::Pluggable sub_name => 'test_modules';
__PACKAGE__->meta->add_method(search_path  => \&search_path);
__PACKAGE__->meta->add_method(test_modules => \&test_modules);

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Qubling Software LLC.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
