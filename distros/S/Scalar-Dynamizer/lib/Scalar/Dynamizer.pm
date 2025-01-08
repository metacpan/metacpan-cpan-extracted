package Scalar::Dynamizer;

use Scalar::Dynamizer::Tie;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(dynamize);

use overload
  'bool'   => sub { ${ $_[0] } },
  '""'     => sub { ${ $_[0] } },
  '0+'     => sub { ${ $_[0] } },
  fallback => 1;

sub dynamize(&) {
    my ($code) = @_;
    my $scalar;

    if ( ref($code) ne 'CODE' ) {
        croak('dynamize{} requires a code reference');
    }

    tie $scalar, 'Scalar::Dynamizer::Tie', $code;

    return bless \$scalar, __PACKAGE__;
}

=head1 NAME

Scalar::Dynamizer - Create dynamic, update-on-access scalars

=head1 VERSION

Version 1.000

=cut

our $VERSION = '1.000';

=head1 SYNOPSIS

    use Scalar::Dynamizer qw(dynamize);

    my $count = 0;

    # Contrived example of a simple counter
    my $counter = dynamize {
        return ++$count;
    };

    print $counter;             # 1
    print $counter * 100;       # 200
    print "Count is $counter";  # "Count is 3"

    # More realistic example involving a database query
    my $points = dynamize {
        return database->quick_count("solved_challenges", { 
            user => session("user") 
        });
    };

=head1 DESCRIPTION

C<Scalar::Dynamizer> enables the creation of dynamic scalars whose values are 
automatically recomputed each time they are accessed. This functionality is 
powered by Perl's C<tie> mechanism and operator overloading. By providing 
convenient syntactic sugar that simplies the use of tied scalars, this module 
makes working with dynamically evaluated scalars transparent and less verbose.

Dynamic scalars are particularly useful when a scalar's value depends on the 
program's current state at the time of access, such as counters, timestamps, or 
real-time data from a database.

=head1 EXPORT

The module exports a single method, C<dynamize>.

=head1 SUBROUTINES/METHODS

=head2 dynamize

    my $scalar = dynamize { ... };

Creates a dynamic, update-on-access scalar. The code block provided must return 
the value of the scalar. Each time the scalar is accessed, the provided code 
block is executed and its return value is used as the scalar's new value.

=head3 Parameters

=over

=item * A code block (required)

The block of code that returns the scalar's value.

=back

=head3 Returns

A scalar reference that transparently behaves like a scalar in boolean, numeric, 
and string contexts.

=head3 Example

    use POSIX qw(strftime);
    my $timestamp = dynamize { strftime("[%Y/%m/%d %H:%M:%S]", localtime) };
    print "$timestamp something happened\n";
    sleep(1);
    print "$timestamp something else happened later\n";

See the `examples/` directory for additional examples.

=head1 DIAGNOSTICS

=over

=item C<dynamize{} requires a code reference>

This error occurs when the argument to C<dynamize> is not a code reference. 
Ensure that you pass a valid code block.

=item C<Cannot assign to a dynamic scalar>

Dynamic scalars are immutable and cannot be assigned a value. Any attempt to do 
so will result in this error.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Scalar::Dynamizer does not utilize any special configuration or environment 
variables.

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

There are no known incompatibilities with other modules at this time.

=head1 BUGS AND LIMITATIONS

=over

=item * Overload Limitations

In certain contexts, Perl may bypass operator overloading for C<Scalar::Dynamizer> 
objects. This occurs when the object is accessed in a way that does not explicitly 
trigger stringification, numeric conversion, or boolean evaluation. For example, 
passing the variable to a subroutine expecting a raw scalar reference or using 
it in highly specific scenarios may result in the tied scalar being returned 
as an object reference instead of the computed value.

To mitigate this, ensure the dynamized scalar is used in a context that explicitly 
resolves it (e.g., string or numeric operations). For example:

    my $string = "$dynamized_scalar";    # interpolation triggers stringification
    my $number = 0 + $dynamized_scalar;  # explicit numerical context


=item * Thread Safety

The module does not guarantee thread safety. Use with care in threaded programs.

=item * Immutable Scalars

Dynamic scalars cannot be assigned a value.

=item * Performance

Frequent computation of dynamic values may have a performance impact, particularly 
if the code block involves expensive operations.

=back

=head1 AUTHOR

Jeremi Gosney, C<< <epixoip at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scalar-dynamizer at rt.cpan.org>, 
or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-Dynamizer>.  
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Dynamizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Dynamizer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Scalar-Dynamizer>

=item * Search CPAN

L<https://metacpan.org/release/Scalar-Dynamizer>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Jeremi Gosney.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<perltie>, L<overload>

=cut

1;    # End of Scalar::Dynamizer
