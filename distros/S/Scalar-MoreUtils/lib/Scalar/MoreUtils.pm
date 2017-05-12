package Scalar::MoreUtils;

use warnings;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 
    all => [ qw(nil empty define default ifnil ifempty) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Scalar::MoreUtils - Provide the stuff missing in Scalar::Util

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Scalar::MoreUtils qw(nil empty define default ifnil ifempty);

  ...

  sub add {
	my $left = default shift, 0;
	my $right = default shift, 0;
	return $left + $right;
  }

  sub greet {
  	return default shift, "This the default greeting!";
  }

=head1 DESCRIPTION

Similar to C<< Hsah::MoreUtils >> and C<< List::MoreUtils >>, C<< Scalar::MoreUtils >>
contains trivial but commonly-used scalar functionality.

Essentially, provide some pretty trivial functionality that I find useful over
and over. The value of this module will probably be blasted away by Perl 5.10.

Suggestions welcome.

=over 4

=item nil VALUE

Returns true if VALUE is not defined.

=cut

sub nil ($) { return ! defined $_[0] }

=item empty VALUE

Returns true if VALUE is not defined or if VALUE is the empty string ("").

=cut

sub empty ($) { return nil $_[0] || 0 == length $_[0] }

=item define VALUE

Returns VALUE if it is defined, otherwise returns the empty string ("").

=cut

sub define ($) { return defined $_[0] ? $_[0] : '' }

=item default VALUE DEFAULT 

Returns VALUE if it is defined, otherwise returns DEFAULT.

This is similar to the "//" in the Perl 5.10 ... well, not really, but kinda.

=cut

sub default ($$) { return defined $_[0] ? $_[0] : $_[1] }

=item ifnil VALUE DEFAULT

Returns VALUE if it is not nil, otherwise returns DEFAULT.

Read "ifnil(A,B)" as "ifnil A, then B, otherwise A"

C<ifnil> behaves exactly the same as C<default>.

=cut

*ifnil = \&default;

=item ifempty VALUE DEFAULT

Returns VALUE if it is not empty, otherwise returns DEFAULT.

Read "ifempty(A,B)" as "ifempty A, then B, otherwise A"

=cut

sub ifempty ($$) { return ! empty $_[0] ? $_[0] : $_[1] }

=back

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-scalar-moreutils at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-MoreUtils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::MoreUtils

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Scalar-MoreUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Scalar-MoreUtils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-MoreUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Scalar-MoreUtils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Scalar::MoreUtils
