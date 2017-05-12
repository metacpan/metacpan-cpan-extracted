package Regexp::Shellish ;

#
# Copyright 1999, Barrie Slaymaker <barries@slaysys.com>
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=head1 NAME

Regexp::Shellish - Shell-like regular expressions

=head1 SYNOPSIS

   use Regexp::Shellish qw( :all ) ;

   $re = compile_shellish( 'a/c*d' ) ;

   ## This next one's like 'a*d' except that it'll
   ## match 'a/d'.
   $re = compile_shellish( 'a**d' ) ;

   ## And here '**' won't match 'a/d', but behaves
   ## like 'a*d', except for the possibility of high
   ## cpu time consumption.
   $re = compile_shellish( 'a**d', { star_star => 0 } ) ;

   ## The next two result in identical $re1 and $re2.
   ## The second is a noop so that Regexp references can
   ## be easily accomodated.
   $re1 = compile_shellish( 'a{b,c}d' ) ;
   $re2 = compile_shellish( qr/\A(?:a(?:b|c)d)\Z/ ) ;

   @matches = shellish_glob( $re, @possibilities ) ;


=head1 DESCRIPTION

Provides shell-like regular expressions.  The wildcards provided
are C<?>, C<*> and C<**>, where C<**> is like C<*> but matches C</>.  See
L</compile_shellish> for details.

Case sensitivity and constructs like <**>, C<(a*b)>, and C<{a,b,c}>
can be disabled.

=over

=cut

use strict ;

use Carp ;
use Exporter ;

use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS ) ;

$VERSION = '0.93' ;

@ISA = qw( Exporter ) ;

@EXPORT_OK = qw(
   compile_shellish
   shellish_glob
) ;

%EXPORT_TAGS = ( 'all' => \@EXPORT_OK ) ;

=item compile_shellish

Compiles a string containing a 'shellish' regular expression, returning a
Regexp reference.  Regexp references passed in are passed through
unmolested.

Here are the transformation rules from shellish expression terms to
perl regular expression terms:

   Shellish  Perl RE
   ========  =======
   *         [^/]*
   ?         .
   **        .*               ## unless { star_star   => 0 }
   ...       .*               ## unless { dot_dot_dot => 0 }

   (         (                ## unless { parens => 0 }
   )         )                ## unless { parens => 0 }

   {a,b,c}   (?:a|b|c)        ## unless { braces => 0 }

   \a        a                ## These are de-escaped and
   \*        \*               ## passed to quotemeta()

The wildcards treat newlines as normal characters.

Parens group in to $1..$n, since they are passed through unmolested
(unless option parens => 0 is passed).  This is useless when using
glob_shellish(), though.

The final parameter can be a hash reference containing options:

   compile_shellish(
      '**',
      {
         anchors        => 0,   ## Doesn't put ^ and $ around the
	                        ## resulting regexp
         case_sensitive => 0,   ## Make case insensitive
         dot_dot_dot    => 0,   ## '...' is now just three '.' chars
         star_star      => 0,   ## '**' is now two '*' wildcards
	 parens         => 0,   ## '(', ')' are now regular chars
	 braces         => 0,   ## '{', '}' are now regular chars
      }
   ) ;

No option affects Regexps passed through.

=cut

sub compile_shellish {
   my $o = @_ && ref $_[-1] eq 'HASH' ? pop : {} ;
   my $re = shift ;

   return $re if ref $re eq 'Regexp' ;

   my $star_star = ( ! exists $o->{star_star} || $o->{star_star} )
      ? '.*'
      : '[^/]*[^/]*' ;

   my $dot_dot_dot = ( ! exists $o->{dot_dot_dot} || $o->{dot_dot_dot} )
      ? '.*'
      : '\.\.\.' ;

   my $case = ( ! exists $o->{case_sensitive} || $o->{case_sensitive} )
      ? ''
      : 'i' ;

   my $anchors     = ( ! exists $o->{anchors} || $o->{anchors} ) ;
   my $pass_parens = ( ! exists $o->{parens}  || $o->{parens} ) ;
   my $pass_braces = ( ! exists $o->{braces}  || $o->{braces} ) ;

   my $brace_depth = 0 ;

   my $orig = $re ;

   $re =~ s@
      (  \\.
      |  \*\*
      |  \.\.\.
      |  .
      )
   @
      if ( $1 eq '?' ) {
	 '[^/]' ;
      }
      elsif ( $1 eq '*' ) {
	 '[^/]*' ;
      }
      elsif ( $1 eq '**' ) {
	 $star_star ;
      }
      elsif ( $1 eq '...' ) {
	 $dot_dot_dot;
      }
      elsif ( $pass_braces && $1 eq '{' ) {
	 ++$brace_depth ;
         '(?:' ;
      }
      elsif ( $pass_braces && $1 eq '}' ) {
	 croak "Unmatched '}' in '$orig'" unless $brace_depth-- ;
         ')' ;
      }
      elsif ( $pass_braces && $brace_depth && $1 eq ',' ) {
         '|' ;
      }
      elsif ( $pass_parens && index( '()', $1 ) >= 0 ) {
         $1 ;
      }
      else {
	 quotemeta(substr( $1, -1 ) );
      }
   @gexs ;

   croak "Unmatched '{' in '$orig'" if $brace_depth ;

   return $anchors ? qr/\A(?$case:$re)\Z/s : qr/(?$case:$re)/s ;
}


=item shellish_glob

Pass a regular expression and a list of possible values, get back a list of
matching values.

   my @matches = shellish_glob( '*/*', @possibilities ) ;
   my @matches = shellish_glob( '*/*', @possibilities, \%options ) ;

=cut

sub shellish_glob {
   my $o = @_ > 1 && ref $_[-1] eq 'HASH' ? pop : {} ;
   my $re = compile_shellish( shift, $o ) ;
   return grep { m/$re/ } @_ ;
}

=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut


1 ;
