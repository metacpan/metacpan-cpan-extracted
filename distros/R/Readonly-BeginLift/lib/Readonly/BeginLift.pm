package Readonly::BeginLift;

use warnings;
use strict;

use Readonly;
use Devel::BeginLift ();
Devel::BeginLift->setup_for(
    Readonly => [
        qw(
          Readonly
          Scalar
          Array
          Hash
          )
    ]
);

use parent 'Exporter';
our @EXPORT    = 'Readonly';
our @EXPORT_OK = qw/Scalar Array Hash Scalar1 Array1 Hash1/;

=head1 NAME

Readonly::BeginLift - Readonly at BEGIN time

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Readonly::BeginLift;
    Readonly         my $VAR  => 'foo';
    Readonly::Scalar my $VAR2 => 'bar';
    BEGIN { print $VAR, $VAR2 }
    __END__
    foo,bar

=head1 DESCRIPTION

The L<Readonly> module exports the C<Readonly> subroutine, but this subroutine
executes at runtime.  This module causes it to execute at BEGIN time.  Thus:

    use strict;
    use warnings;
    use Readonly;
    use constant MY_VALUE => 'foo';
    Readonly my $MY_VALUE => 'bar';

    BEGIN {
        print MY_VALUE, "\n";
        print $MY_VALUE, "\n";
    }

That will print "foo" and issue an uninitialized value warning.  One way to
make it work is to do this:

    use strict;
    use warnings;
    use Readonly;
    use constant MY_VALUE => 'foo';
    my $MY_VALUE;

    BEGIN {
        Readonly my $MY_VALUE => 'bar';
        print MY_VALUE, "\n";
        print $MY_VALUE, "\n";
    }
    
That's a bit clumsy, so we use C<Devel::BeginLift> to make C<Readonly> execute
at begin time.

=head1 EXPORT

=head2 C<Readonly>

This is identical to the L<Readonly> module, except that it happens at BEGIN
time.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-readonly-beginlift at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-BeginLift>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Readonly::BeginLift

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-BeginLift>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Readonly-BeginLift>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Readonly-BeginLift>

=item * Search CPAN

L<http://search.cpan.org/dist/Readonly-BeginLift/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks for Florian Ragwitz for L<Devel::BeginLift>.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
