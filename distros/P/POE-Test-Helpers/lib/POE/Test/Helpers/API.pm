use strictures 1;
package POE::Test::Helpers::API;
BEGIN {
  $POE::Test::Helpers::API::VERSION = '1.11';
}
# ABSTRACT: Documentation of POE::Test::Helpers API
1;



=pod

=head1 NAME

POE::Test::Helpers::API - Documentation of POE::Test::Helpers API

=head1 VERSION

version 1.11

=head1 DESCRIPTION

This is a documentation of the API of L<POE::Test::Helpers>. It is useful if you
want to embed POE::Test::Helpers into a more complex testing scheme.

POE::Test::Helpers employs an object that contains both the tests to run, how to
run some of these tests and the run method to create a session to hook up to.

The object also has methods you should call from inside events, and it injects
calling them into the L<POE::Session> object the run method creates.

=head1 METHODS

=head2 new

Creates an instance of the object. This does not create a L<POE::Session>
instance.

It works with the following attributes:

=head3 tests

A hash reference describing tests you want done.

B<< You can read more about them in L<POE::Test::Helpers> >>.

=head3 params_type

The type of parameter checks. Either I<ordered> or I<unordered>.

B<< You find can examples of it in L<POE::Test::Helpers> >>.

=head2 reached_event

Reached event should be run from inside the events. It gives the object details
on the event that it can then use to run tests.

Calling this method is injected into any event you want to test in the session
returned by the C<run> attribute, defined in L<POE::Test::Helpers>.

    $object->reached_event(
        name   => 'special',
        order  => 3, # we're 4th (counting starts at 0)
        params => [ @_[ ARG0 .. $# ] ], # if any
    );

=head2 check_deps

Runs a check of the event dependencies against the tests that were given.

=head2 check_order

Runs a check of the order of events against the tests that were given.

=head2 check_params

Runs a check of the parameters of events against the tests that were given.

=head2 check_all_counts

Requests to run count checks for every event.

=head2 check_count

Runs a check of the events' runtime count against the tests that were given.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

Please use the Github Issues tracker.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Test::Helpers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Test-Helpers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Test-Helpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Test-Helpers>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Test-Helpers/>

=back

=head1 ACKNOWLEDGEMENTS

I owe a lot of thanks to the following people:

=over 4

=item * Chris (perigrin) Prather

Thanks for all the comments and ideas. Thanks for L<MooseX::POE>!

=item * Rocco (dngor) Caputo

Thanks for the input and ideas. Thanks for L<POE>!

=item * #moose and #poe

Really great people and constantly helping me with stuff, including one of the
core principles in this module.

=back

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

