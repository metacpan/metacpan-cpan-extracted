package Scalar::Andand;

use 5.008;

use strict;
use warnings;
our $VERSION = '0.05';

my %args;
use Scalar::Andand::Undef;
use Scalar::Andand::Scalar;
BEGIN { %args = (SCALAR => [ 'Scalar::Andand::Scalar', 'autobox::Core::SCALAR' ], UNDEF => 'Scalar::Andand::Undef') }
use autobox::Core %args;

sub import {    ## no critic (RequireArgUnpacking)
	push @_, %args;
	goto &autobox::Core::import;
}

sub UNIVERSAL::andand {
	return shift;
}

1;

__END__

=head1 NAME

Scalar::Andand - Guarded method invocation.

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Scalar::Andand lets us write:

 $phone = Location->find('first', name => 'Johnson' )->andand->phone

And get a guarded method invocation or safe navigation method. This snippet performs a C<find> on the Location class, then calls C<phone> to the result if the result is defined. If the result is not defined, then the expression returns false without throwing an exception. 

=head1 EXPORT

This module doesn't export anything to your namespace, but it does add a universal method andand, which is a far graver sin.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

You have to include the module in every package where you use the magic C<andand> method, or else it doesn't work on undefined values.

This module contains more magic than what is responsible, don't be surprised by weird bugs.

Note that this module was intended as a proof of concept. The author has never used it in production code, nor is he planning to do so. YMMV.

Please report any bugs or feature requests to C<bug-scalar-andand at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-Andand>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Andand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Andand>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Scalar-Andand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Scalar-Andand>

=item * Search CPAN

L<http://search.cpan.org/dist/Scalar-Andand>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
