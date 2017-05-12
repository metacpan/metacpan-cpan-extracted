package SmokeRunner::Multi::Runner;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Base class for running test sets
$SmokeRunner::Multi::Runner::VERSION = '0.21';
use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors( 'set' );

use SmokeRunner::Multi::Validate qw( validate TEST_SET_TYPE );


{
    my $spec = { set => TEST_SET_TYPE,
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        return bless \%p, $class;
    }
}

sub run_tests
{
    die "The run_tests() method must be overridden in a subclass.\n"
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::Runner - Base class for running test sets

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  use base 'SmokeRunner::Multi::Runner';

  sub run_tests {
      ...
  }

=head1 DESCRIPTION

This class is the parent class for running tests. It provides a
constructor, but subclasses are expected to provide a C<run_tests()>
method.

=head1 METHODS

This class provides the following methods:

=head2 SmokeRunner::Multi::Runner->new(...)

This method creates a new runner object. It requires one parameter:

=over 4

=item * set

A C<SmokeRunner::Multi::TestSet> object.

=back

=head2 $runner->set()

Returns the test set object passed to the constructor.

=head2 $runner->run_tests()

This method should be implemented by subclasses.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and /or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
