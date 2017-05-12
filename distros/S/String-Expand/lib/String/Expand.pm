#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006,2007,2009 -- leonerd@leonerd.org.uk

package String::Expand;

use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
   expand_string
   expand_strings
);

use Carp;

our $VERSION = '0.04';

my $VARNAME_MATCH = qr/\$([A-Z_][A-Z0-9_]*|\{.*?\})/;

=head1 NAME

C<String::Expand> - string utility functions for expanding variables in
self-referential sets

=head1 SYNOPSIS

 use String::Expand qw( expand_strings );

 my %vars = ( MESSAGE => 'My home is $HOME',
              TEXT    => 'Message is "$MESSAGE"' );

 expand_strings( \%vars, \%ENV );

 # %vars now contains something like:
 #   MESSAGE => 'My home is /home/user',
 #   TEXT    => 'Message is "My home is /home/user"'

=head1 DESCRIPTION

This module implements utility functions for expanding embedded variables in a
string. Variable references are embedded in strings in a similar form to the
Bourne shell, namely, in the form C<$NAME> or C<${NAME}>. In the former case,
the C<NAME> must consist of a capital letter or underscore, and may be
followed by zero or more capital letters, digits or underscores. In the latter
case, the name can consist of any characters, but will be terminated by the
first close brace character C<'}'>.

The string may also contain literal dollar marks, escaped by C<\$>, and
literal escape marks, escaped by C<\\>. These will be converted to C<$> and
C<\> respectively on return.

While there are many other modules that also provide expansion such as this,
this module provides the function C<expand_strings()>, which will perform
variable expansions in all the values in a given hash, where values can refer
to other values within the same hash. 

=cut

=head1 FUNCTIONS

=cut

sub expand_one_var($$)
{
   my ( $var, $vars ) = @_;

   # Chop off delimiting {braces} if present
   $var =~ s/^\{(.*)\}$/$1/;

   unless( defined $vars->{$var} ) {
      croak "Unknown variable '$var'";
   }

   return $vars->{$var};
}

=head2 $expanded = expand_string( $str, \%vars )

This function expands embedded variable references in the passed string, and
returns the expanded copy. 

=over 8

=item $str

A string possibly containing variable expansions

=item \%vars

Reference to a hash containing variable values

=item Returns

A string with variables expanded

=back

=cut

sub expand_string($$)
{
   my ( $str, $vars ) = @_;

   $str =~ s{\\([\\\$])|$VARNAME_MATCH}
            {     $1  or expand_one_var( $2, $vars )}eg;

   return $str;
}

sub expand_strings_inner($$$$);

sub expand_strings_one_var($$$$)
{
   my ( $var, $strs, $overlay, $done ) = @_;

   # Chop off delimiting {braces} if present
   $var =~ s/^\{(.*)\}$/$1/;

   if( exists $strs->{$var} ) {
      return $strs->{$var} if( $done->{$var} );
      # Detect loops
      if( exists $done->{$var} ) {
         croak "Variable loop trying to expand '$var'";
      }
      $done->{$var} = 0;
      expand_strings_inner( $strs, $overlay, $var, $done );
      return $strs->{$var};
   }

   return $overlay->{$var} if( exists $overlay->{$var} );
   
   croak "Unknown variable '$var'";
}

sub expand_strings_inner($$$$)
{
   my ( $strs, $overlay, $v, $done ) = @_;
   
   if( $strs->{$v} =~ m/[\\\$]/ ) {
      $strs->{$v} =~ s{\\([\\\$])|$VARNAME_MATCH}
                      {     $1  or expand_strings_one_var( $2, $strs, $overlay, $done )}eg;
   }

   $done->{$v} = 1;
}

=head2 expand_strings( \%strs, \%overlay )

This function takes a hash of strings, and expands variable names embedded in
any of them, in the same form as the string passed to C<expand_string()>.
Expansions may refer to other strings, or to values in the C<I<%overlay>>
hash. Values in the main variables hash take precidence over values in the
overlay.

Where values refer to other values, care must be taken to avoid cycles. If a
cycle is detected while attempting to expand the values, then an exception is
thrown.

=over 8

=item \%strs

Reference to a hash containing variables to expand

=item \%overlay

Reference to a hash containing other variable values

=item Returns

Nothing

=back

=cut

sub expand_strings($$)
{
   my ( $strs, $overlay ) = @_;

   # 0: a variable expansion is in progress
   # 1: value has been correctly expanded
   my %done;

   foreach my $v ( keys %$strs ) {
      expand_strings_inner( $strs, $overlay, $v, \%done );
   }
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<String::Interpolate> - Wrapper for builtin the Perl interpolation engine

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
