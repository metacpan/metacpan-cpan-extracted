package Perl::Police;

use strict;
use warnings FATAL => 'all';
use 5.008_005;
use vars qw{$VERSION};
BEGIN {
	$VERSION = 'v0.0.2';
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::Police - Essentially a Code Review, on steroids.
NOTE: This version is NOT complete. If you think this Module may be of
interest to you. Track this Module, as the following version will be
operational.

=head1 SYNOPSIS

  use Perl::Police;

=head1 DESCRIPTION

Perl::Police is essentially Code Review. It will allow you to
rigeriously test your Application, or Module, and ultimately save you
from yourself.

But doesn't Perl already provide the tools for accomplishing this sort
of thing?

Yes, it essentially does, and you know how much fun that is.

This sounds a bit like Perl-Critic. Is it?

Nope. Perl::Police is more powerful, and offers a great deal more.

=head1 AUTHOR

C Hutchinson, C<< <taint at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl-police at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Police>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Police

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Police>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Police>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Police>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-Police/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE

Copyright 2013 C Hutchinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
