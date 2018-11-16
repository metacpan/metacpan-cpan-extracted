package Table::BoxFormat::Unicode::CharClasses;
#                                doom@kzsu.stanford.edu
#                                22 Dec 2016


=head1 NAME

Table::BoxFormat::Unicode::CharClasses - character classes to work with db SELECT result formats

=head1 SYNOPSIS

   use Table::BoxFormat::Unicode::CharClasses ':all';

   $horizontal_dashes_plus_crosses_or_whitespace = 
           qr{ ^              
                [ \p{IsHor} \s ] +             
               $  }x;               

   $cross_character = 
            qr{ 
                 \p{IsCross}               
                    {1,1}   # just one 
               }xms;

   $column_separator = 
         qr{
            \s+         # require leading whitespace
            \p{IsDelim}
                {1,1}   # just one
            \s+         # require trailing whitespace
        }xms;


=head1 DESCRIPTION

Table::BoxFormat::Unicode::CharClasses, contains a number of
pre-defined character classes to assist in writing regular
expressions to match elements of typical database SELECT result
formats (see: L<Table::BoxFormat>).

=head2 EXPORT

None by default, ':all' for all.

=cut

use 5.10.0;
use strict;
use warnings;
use utf8;
my $DEBUG = 1;
use Carp;
use Data::Dumper;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS, @EXPORT);
BEGIN {
 require Exporter;
 @ISA = qw(Exporter);
 %EXPORT_TAGS = ( 'all' => [
 qw(
     IsHor
     IsCross
     IsDelim
    ) ] );
  @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
  @EXPORT = qw(  ); # items to export into callers namespace by default (avoid this!)
}

our $VERSION = '0.01';


=head2 regexp properties

Definitons of some custom regexp character properties that might
be useful for projects such as L<Table::BoxFormat>, that work with
the tabular text formats used by database monitors to display
select results.

=over

=cut

=item IsHor

Matches characters found in a "horizontal rule" row.

=cut

# defining character properties for regexp defaults
sub IsHor {
  my @codepoints =
    ('002D',  # -  \N{HYPHEN-MINUS}
     '002B',  # +  \N{PLUS SIGN}
     '2500',  # ─  \N{BOX DRAWINGS LIGHT HORIZONTAL}
     '253C',  # ┼  \N{BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL}
     );
  my $list = join "\n", @codepoints;
  return $list;
}

=item IsCross

Matches the "cross" characters used at line intersections.

=cut

sub IsCross {
  my @codepoints =
    (
     '002B',  # +  \N{PLUS SIGN}
     '253C',  # ┼  \N{BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL}
     );
  my $list = join "\n", @codepoints;
  return $list;
}

=item IsDelim

Matches the delimeter/separator characters used on column boundaries.

=cut

sub IsDelim {
  my @codepoints =
    (
     '007C',  #  |  \N{VERTICAL LINE}
     '2502',  #  │  \N{BOX DRAWINGS LIGHT VERTICAL}
    );
  my $list = join "\n", @codepoints;
  return $list;
}



1;

=head1 NOTES

=head2 about characters used in the above classes

=head3 unicode characters

the unicode psql format uses these three characters:

uniprops U+2502
U+2502 ‹│› \N{BOX DRAWINGS LIGHT VERTICAL}
    \pS \p{So}
    All Any Assigned InBoxDrawing Box_Drawing Common Zyyy So S Gr_Base
       Grapheme_Base Graph GrBase Other_Symbol Pat_Syn Pattern_Syntax PatSyn
       Print Symbol Unicode X_POSIX_Graph X_POSIX_Print

uniprops U+2500
U+2500 ‹─› \N{BOX DRAWINGS LIGHT HORIZONTAL}
    \pS \p{So}
    All Any Assigned InBoxDrawing Box_Drawing Common Zyyy So S Gr_Base
       Grapheme_Base Graph GrBase Other_Symbol Pat_Syn Pattern_Syntax PatSyn
       Print Symbol Unicode X_POSIX_Graph X_POSIX_Print

uniprops U+253c
U+253C ‹┼› \N{BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL}
    \pS \p{So}
    All Any Assigned InBoxDrawing Box_Drawing Common Zyyy So S Gr_Base
       Grapheme_Base Graph GrBase Other_Symbol Pat_Syn Pattern_Syntax PatSyn
       Print Symbol Unicode X_POSIX_Graph X_POSIX_Print


=head3 delimiter characters

Either of these two characters may be data delimiters,
the ascii vertical bar or the unicode "BOX DRAWINGS LIGHT VERTICAL":

    |│


=head1 SEE ALSO

L<Table::BoxFormat>
L<perlrecharclass>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
