package PFIX;

use warnings;
use strict;

=head1 NAME

PFIX - Perl FIX protocol library!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Perl FIX protocol implementation.

The Financial Information eXchange (FIX) Protocol is a messaging standard developed specifically for the real-time electronic exchange of securities transactions. FIX is a public-domain specification owned and maintained by FIX Protocol, Ltd.

This module offers some simple methods to parse or build a FIX message.
It has knowledge of the FIX dictionary.

The module here is vastly imcomplete but was written for an interface project (now in production) and thus is operational.
However to take it to the next step it needs more work.

Although I will do my best to minimise radical changes, next versions may not be backward compatible - be prepared (sorry).


    use PFIX::Message;

    # create a FIX message object
    my $msg = PFIX::Message->new(version=>'FIX44');
    # initialise it with a string
    $msg->fromString("8=FIX.4.4\0019=41\00135=.........10=011");

    # set some fields 
    $msg->setField('Symbol','IBM');      # assign value using tag name
    $msg->setField(56,'TARGETSYSTEM');   # assign value using tab number
    # get some field values
    $msg->getField(11);
    # delete fields
    $msg->delField(123);

    # now produce new FIX protocol string.
    my $str=$msg->toString();
    ...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

"Gabriel Galibourg", C<< <""> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pfix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PFIX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PFIX


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PFIX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PFIX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PFIX>

=item * Search CPAN

L<http://search.cpan.org/dist/PFIX/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 "Gabriel Galibourg".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of PFIX
