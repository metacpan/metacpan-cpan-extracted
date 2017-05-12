package Template::Sandbox::StringFunctions;

use strict;
use warnings;

use base 'Template::Sandbox::Library';

use Template::Sandbox qw/:function_sugar/;

$Template::Sandbox::StringFunctions::VERSION = '1.04';

__PACKAGE__->set_library_functions(
    lc      => ( one_arg sub { lc( $_[ 0 ] ) } ),
    lcfirst => ( one_arg
        sub { ref( $_[ 0 ] ) ?
              [ map { lcfirst( $_ ) } @{$_[ 0 ]} ] : lcfirst( $_[ 0 ] ) } ),
    uc      => ( one_arg sub { uc( $_[ 0 ] ) } ),
    ucfirst => ( one_arg
        sub { ref( $_[ 0 ] ) ?
              [ map { ucfirst( $_ ) } @{$_[ 0 ]} ] : ucfirst( $_[ 0 ] ) } ),
    substr  => ( three_args sub { substr( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) } ),
    length  => ( one_arg sub { length( $_[ 0 ] ) } ),
    possessive =>
        ( one_arg sub { $_[ 0 ] . ( $_[ 0 ] =~ /s$/ ? "'" : "'s" ) } ),
    );

1;

__END__

=pod

=head1 NAME

Template::Sandbox::StringFunctions - Basic string functions library for Template::Sandbox.

=head1 SYNOPSIS

  use Template::Sandbox::StringFunctions qw/:all/;

  # or:

  use Template::Sandbox::StringFunctions;

  my $template = Template::Sandbox->new(
      library => [ Template::Sandbox::StringFunctions => qw/ucfirst uc lc/ ],
      );

=head1 DESCRIPTION

Library of basic string manipulation functions for easy import into a
L<Template::Sandbox> template.

=head1 EXPORTABLE TEMPLATE FUNCTIONS

=over

=item C<lc( string )>

=item C<uc( string )>

Provides access to the C<lc()> and C<uc()> Perl functions.

=item C<lcfirst( string | array )>

=item C<ucfirst( string | array )>

Provides access to the C<lcfirst()> and C<ucfirst()> functions in Perl,
with the added feature that they can operate over an array of strings
to set each in turn.

=item C<substr( string, offset, length )>

Behaves like Perl's C<substr()> except all three arguments are mandatory.

=item C<length( string )>

In case you don't like using C<string.__size__> or C<size( string )>, you
can use the "more Perlish" C<length( string )>.

=item C<possessive( string )>

Turns the noun C<string> into a possessive noun as per English's grammar,
ie: "Duncan" becomes "Duncan's" but "James" becomes "James'".

=back

=head1 EXPORTABLE GROUPS

=over

=item :all

Exports all defined template functions in this library.

=back

=head1 KNOWN ISSUES AND BUGS

There's not really a great many functions in here, the module could
be regarded as largely superfluous since you could easily recreate
it yourself if you needed it.  However it provides a useful example
of how to write your own library of template functions.

=head1 SEE ALSO

L<Template::Sandbox>, L<Template::Sandbox::Library>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Sandbox::StringFunctions


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
