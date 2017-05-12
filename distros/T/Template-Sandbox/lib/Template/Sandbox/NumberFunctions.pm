package Template::Sandbox::NumberFunctions;

use strict;
use warnings;

use base 'Template::Sandbox::Library';

use Template::Sandbox qw/:function_sugar/;

$Template::Sandbox::NumberFunctions::VERSION = '1.04';

#  From perlfaq5: add thousands-commas to number.
#  Yes it doesn't respect locale.
sub _commify
{
    local $_  = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/o;
    return $_;
}

__PACKAGE__->set_library_functions(
    int      => ( one_arg sub { int( $_[ 0 ] ) } ),
    round    => ( one_arg
        sub
        {
            ( int( $_[ 0 ] * 10 ) % 10 >= 5 ) ?
            ( int( $_[ 0 ] ) + 1 ) :
            int( $_[ 0 ] )
        } ),
    abs      => ( one_arg sub { abs( $_[ 0 ] ) } ),

    #  Pretty numeric formatting.
    numeric  => ( one_arg \&_commify ),
    currency => ( one_arg
        sub { _commify( sprintf( '%.2f', $_[ 0 ] ) ) } ),
    accountant_currency => ( one_arg
        sub
        {
            ( $_[ 0 ] < 0 ) ?
                ( '(' . _commify( sprintf( '%.2f', abs( $_[ 0 ] ) ) ) . ')' ) :
                ( _commify( sprintf( '%.2f', $_[ 0 ] ) ) )
        } ),
    decimal  => ( two_args sub { sprintf( '%.' . $_[ 1 ] . 'f', $_[ 0 ] ) } ),

    exp     => ( one_arg sub { exp( $_[ 0 ] ) } ),
    log     => ( one_arg sub { log( $_[ 0 ] ) } ),
    pow     => ( two_args sub { $_[ 0 ] ** $_[ 1 ] } ),
    sqrt    => ( one_arg sub { sqrt( $_[ 0 ] ) } ),

    rand    => ( one_arg inconstant
        sub
        {
            ref( $_[ 0 ] ) ?
            $_[ 0 ]->[ int( rand( $#{$_[ 0 ]} + 1 ) ) ] :
            rand( $_[ 0 ] )
        } ),
    srand   => ( one_arg inconstant sub { srand( $_[ 0 ] ) } ),

    max     => ( two_args sub { $_[ 0 ] > $_[ 1 ] ? $_[ 0 ] : $_[ 1 ] } ),
    min     => ( two_args sub { $_[ 0 ] < $_[ 1 ] ? $_[ 0 ] : $_[ 1 ] } ),
    );

__PACKAGE__->set_library_tags(
    'maths'    => [ qw/exp log pow sqrt/ ],
    'display'  => [ qw/numeric currency accountant_currency decimal/ ],
    );

1;

__END__

=pod

=head1 NAME

Template::Sandbox::NumberFunctions - Basic number functions library for Template::Sandbox.

=head1 SYNOPSIS

  use Template::Sandbox::NumberFunctions qw/:all/;

  # or:

  use Template::Sandbox::NumberFunctions;

  my $template = Template::Sandbox->new(
      library => [ Template::Sandbox::NumberFunctions => qw/ucfirst uc lc/ ],
      );

=head1 DESCRIPTION

Library of basic string manipulation functions for easy import into a
L<Template::Sandbox> template.

=head1 EXPORTABLE TEMPLATE FUNCTIONS

=over

=item C<int( number )>

Rounds C<number> down to the first integer of lower value as per Perl's
C<int()>.

=item C<round( number )>

Rounds C<number> to the nearest integer using mathematical rounding, that
being 0.5 and greater being rounded up and everyhing below 0.5 being rounded
down.

=item C<abs( number )>

Return the absolute value of C<number> as per Perl's C<abs()> function.

=item C<numeric( number )>

Reformat C<number> for pretty display by adding thousands commas. Note
that this does not respect locale.

=item C<currency( number )>

Reformat C<number> for pretty display by adding thousands commas and
displaying to two decimal places. Note that this does not respect locale.

=item C<accountant_currency( number )>

Reformat C<number> for pretty display by adding thousands commas and
displaying to two decimal places, additionally negative numbers will
be displayed in round brackets rather than with a leading minus-sign.
Note that this does not respect locale.

=item C<decimal( number, places )>

Reformat C<number> for display to C<places> decimal places.

=item C<exp( number )>

=item C<log( number )>

=item C<pow( number, exponent )>

=item C<sqrt( number )>

Wrappers to corresponding Perl power functions (or ** operator for C<pow()>.)

=item C<rand( number | array )>

Returns either a random number from C<0> to C<< number - 1 >>, or if
passed an array will return a random element from that array.

=item C<srand( number )>

Wrapper to C<srand()> Perl function.

=item C<min( a, b )>

=item C<max( a, b )>

Returns the min or max value from C<a> or C<b> accordingly.

=back

=head1 EXPORTABLE GROUPS

=over

=item :all

Exports all defined template functions in this library.

=item :maths

Exports C<exp>, C<log>, C<pow> and C<sqrt>.

=item :display

Exports C<numeric>, C<currency>, C<accountant_currency> and C<decimal>.

=back

=head1 KNOWN ISSUES AND BUGS

There's not really a great many functions in here, the module could
be regarded as largely superfluous since you could easily recreate
it yourself if you needed it.  However it provides a useful example
of how to write your own library of template functions.

The pretty display functions don't respect locale and aren't going
to do what you want if you're expecting "." as your thousands
seperator and "," as your decimal marker.

=head1 SEE ALSO

L<Template::Sandbox>, L<Template::Sandbox::Library>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Sandbox::NumberFunctions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Sandbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Sandbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Sandbox>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Sandbox>

=back

=head1 AUTHORS

Original author: Sam Graham <libtemplate-sandbox-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Sam Graham, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
