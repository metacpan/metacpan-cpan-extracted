package Set::Formula;

use 5.8.8;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(formula_checker formula_calcul equality_checker);

use Carp qw(cluck);
our $VERSION = '0.05';
my $debug = 0;

my %operators = (
                  '+'   => \&_union
                 ,'-'   => \&_complement
                 ,'^'   => \&_intersection
                );

my $counter = 0;
#------------------------------------------#
sub _union
{
   my ($hrefA, $hrefB, $href_result) = @_;
   %{$href_result} = ();  # reset this hash

   for  (keys %{$hrefA}) { ${$href_result}{$_} = 0 }
   for  (keys %{$hrefB}) { ${$href_result}{$_} = 0 }
}
#------------------------------------------#
sub _complement
{  # Result := A - B
   my ($hrefA, $hrefB, $href_result) = @_;
   %{$href_result} = ();  # reset this hash

   for  (keys %{$hrefA})
   {  unless (exists ${$hrefB}{$_}) { ${$href_result}{$_} = 0 } }
}
#------------------------------------------#
sub _intersection
{
   my ($hrefA, $hrefB, $href_result) = @_;
   %{$href_result} = ();  # reset this hash

   for  (keys %{$hrefB})
   {  if (exists ${$hrefA}{$_})  { ${$href_result}{$_} = 0; } }
}
#------------------------------------------#
sub equality_checker   # returns 1 if equal, else 0
{
   my ($hrefA, $hrefB, $debug) = @_;

   $debug = (defined $debug)? 1:0;
   if ($debug)
   {
      printf "*** %s: running in debug mode ***\n", (caller(0))[3];
      print "DEBUG: 1st operand: "; for (sort keys %{$hrefA}) { print "$_ "; }; print "\n";
      print "DEBUG: 2nd operand: "; for (sort keys %{$hrefB}) { print "$_ "; }; print "\n";
   }

   for (keys %{$hrefA})
   { unless (exists ${$hrefB}{$_}) { return 0 } }

   for (keys %{$hrefB})
   { unless (exists ${$hrefA}{$_}) { return 0 } }
   return 1;
} 
#------------------------------------------#

sub formula_checker   # returns true on success and undefined value on error
{
   my $formula = shift;
   my $remainder;
   my $debug = (defined $ARGV[0]) && $ARGV[0] ?1:0;
   $debug && printf "*** %s: running in debug mode ***\n", (caller(0))[3];
   unless (defined $remainder) { $remainder = ''; }
   my $parentheses_cnt = 0;
   my $parentheses_number_cnt = 0;
   my $operator;
   my $regexpr ;

   # ---- check "interlacing": start ----
   # rule 1: 2 operands  can't be adjacent
   # rule 2: 2 operators can't be adjacent
   # rule 3: operator can be neither first not last formula element

   $debug && print "DEBUG 10: formula:  $formula\n";
   $remainder = $formula;
   $remainder =~ s/[()]//g;  # remove all parentheses
   $debug && print "DEBUG 20: remainder: $remainder\n";
   my $operator_found = 0;

   INTERLACING:
   while(1)
   {
      unless ( $remainder =~ /^\s*(\w+)\s*/ ) 
      {
         $debug && cluck "ERROR: remainder of formula $remainder must begin with operand";
         return;
      }

      $remainder = $';
      $debug && print "DEBUG 30: operand:  $1    remainder: $remainder\n";
      
      unless ($remainder) { last INTERLACING; } # interlacing is correct
      
      $operator_found = 0;
      for (keys %operators)
      {
         $debug && print "DEBUG 40: operator: $_\n";
         $regexpr = qq (^\\s*(\\$_)\\s*);
         $debug && printf "DEBUG 45: regexpr = %s\n", $regexpr;
         if ( $remainder =~ /$regexpr/ )
         {
            $operator_found = 1;
            $operator = $_;
            $remainder = $';
            last;
         }
      }

      unless ($operator_found)
      {
         $debug && cluck "ERROR: remainder of formula $remainder must begin with operator";
         return;
      }

      $debug && printf "DEBUG 50: operator: %s\n", $operator;

      unless ($remainder)
      { 
         $debug && cluck "ERROR: formula must begin with operator";
         return;
      }
   }  #  end of 'while (1)'

   # ---- check "interlacing": finish  ----

   # ---- check parentheses: start ----
   $remainder = $formula;
   $debug && printf "DEBUG 60: *** remainder = %s\n", $remainder;

   for $operator (keys %operators)
   {
      $regexpr = qq (\\(\\s*\\$operator|\\$operator\\s*\\));
      $debug && printf "DEBUG 65: *** operator = %-3s   regexpr = %s\n", $operator, $regexpr;
      if ( $remainder =~ /$regexpr/ )
      {
         $debug && cluck "ERROR: $& has no sense";
         return;
      }
   }

   while ($remainder =~ /[()]/)
   {
      $debug && printf "DEBUG 70: *** remainder = %s\n", $remainder;
      $parentheses_number_cnt ++;
      $remainder = $';
      unless (defined $remainder) { $remainder = ''; }
      $debug && printf "DEBUG 75: *** remainder = %s\n", $remainder;
      if ( $& =~ /\(/ ) {  $parentheses_cnt ++; }
      else
      {
         $parentheses_cnt --;
         if ($parentheses_cnt < 0)
         {
            $debug && cluck "ERROR: negative parentheses amount at parentheses nr.$parentheses_number_cnt from left";
            return;
         }
      }
   }  #  end of "while ($remainder)"

   if ($parentheses_cnt)
   {
      $debug && cluck "ERROR: more opening parentheses than closing parentheses";
      return;
   }
   return 1;
}  #  end of "sub formula_checker"
#------------------------------------------#
#------------------------------------------#

sub formula_calcul
{
   my ($curr_formula, $href_result, $href_HoH_sets, $debug) = @_;
   %{$href_result} = ();  # reset this hash
   unless (defined $curr_formula) { $curr_formula = '' }

   $debug = (defined $debug) && $debug ?1:0;
   $debug && printf "*** %s: running in debug mode ***\n", (caller(0))[3];

   $debug && print "\n--------------------------\n#1 curr_formula = $curr_formula\n";

   my $href_operand_left;
   my $href_operand_right;
   my $operator;           # a key of %operators
   my $href_remainder;
   my $new_name;

   # parse formula: search internal (...)
   while ( $curr_formula =~ /\(([^(]+?)\)/ )
   {
      #  $curr_formula contains parentheses
      #  $1 is innenmost formula part, that does not contains parentheses.
      #  Opened and closed parentheses are located on boundaries of $1 and don't belong it.
      $debug && print "#2 in parentheses:  $1\n";
      #------------------------------------------#
      unless (defined &formula_calcul ($1, $href_result, $href_HoH_sets, $debug)) 
      { $debug && cluck "Error in formula \"$1\""; return; }

      $new_name = "InTeRmEdIaTe$counter";
      $counter++;
      for (keys %{$href_result})  { $href_HoH_sets->{$new_name}{$_} = 0; }
      unless (exists $href_HoH_sets->{$new_name}) { $href_HoH_sets->{$new_name} = () }
      %{$href_result} = ();  # reset this hash

      $curr_formula = "$` $new_name $'";
      $debug && print "#3 curr_formula = $curr_formula\n\n";
   }

   # parenthesesless formula.
   # Calculate all operators with equal priority from left to right
   if ( $curr_formula =~ /(\w+)\s*(\S+)\s*(\w+)/ )
   {
      $href_operand_left  = $1;
      $operator           = $2;
      $href_operand_right = $3;
      $href_remainder     = $';
      if ($operator !~ /^(\+|\-|\^)$/)
      { $debug && cluck "ERROR: Unknown operator \"$operator\" in formula \"$curr_formula\"\n"; return; }

      $debug && printf "*** left operand = $href_operand_left, operator = $operator, right operand = $href_operand_right,  remainder = %s\n", $href_remainder;

      unless (exists $href_HoH_sets->{$href_operand_left})
      {
         $debug && cluck "ERROR: Unknown left operand \"$href_operand_left\" in formula \"$curr_formula\"\n";
         return;
      }

      unless (exists $href_HoH_sets->{$href_operand_right})
      {
         $debug && cluck "ERROR: Unknown right operand \"$href_operand_right\" in formula \"$curr_formula\"\n";
         return;
      }

      if ($debug)
      {
         printf "!!! %-13s : ", $href_operand_left;
         for ( keys %{$href_HoH_sets->{$href_operand_left}} ) {print "$_ "}
         print "\n";

         printf "!!! %-13s : ", $href_operand_right;
         for ( keys %{$href_HoH_sets->{$href_operand_right}} ) {print "$_ "}
         print "\n";
      }

      $operators{$operator} ( $href_HoH_sets->{$href_operand_left}
                            , $href_HoH_sets->{$href_operand_right}
                            , $href_result );

      if ($debug)
      {
         print "DEBUG: result of ($href_operand_left  $operator  $href_operand_right) : ";
         for (keys %{$href_result}) { print "$_ " }
         print "\n";
      }

      if ($href_remainder =~ /\S/)
      {
         $new_name = "InTeRmEdIaTe$counter";
         $counter++;
         for (keys %{$href_result}) { $href_HoH_sets->{$new_name}{$_} = 0 }
         unless (exists $href_HoH_sets->{$new_name}) { $href_HoH_sets->{$new_name} = () }
         %{$href_result} = ();  # reset this hash

         $curr_formula = "$new_name $href_remainder";
         $debug && print "#4 curr_formula = $curr_formula\n\n";
         if (defined &formula_calcul ($curr_formula, $href_result, $href_HoH_sets, $debug))
         { return 1; }
         else { $debug && cluck "ERROR 33\n"; return; }
      }
   }  # end of "if ( $curr_formula =~ ...)"
   return 1;
}  #  end of "sub formula_calcul"

1;
__END__

=head1 NAME

Set::Formula - Formula calculation for sets

=head1 SYNOPSIS

 use Set::Formula;
 formula_checker (string_containing_formula);    # syntax check without debug
 formula_checker (string_containing_formula, 1); # syntax check with    debug

 formula_calcul  (string_containing_formula, \%result, \%HoH_sets);    # without debug
 formula_calcul  (string_containing_formula, \%result, \%HoH_sets, 1); # with    debug

 equality_checker (\%set1, \%set2);              # without debug
 equality_checker (\%set1, \%set2, 1);           # with    debug

=head1 DESCRIPTION

=head2 C<formula_checker>

 checks syntax of formula without its calculation.

=head2 C<formula_calcul>

 calculates formula without its syntax check.

=head2 C<equality_checker>

 checks, if 2 sets are equal.

Formula should be written in common arithmetic notation (infix notation)
and can contain unrestricted amount of nested parentheses ().

Supported set operators are

    +     - union 
    -     - complement 
    ^     - intersection 

All these operators are binary operators, i.e. they require 2 operands.

Formulas without parentheses are evaluated from left to right
with equal priority for all operators.
Parentheses increase priority of partial formula expressions.

White characters including new line in formula are accepted and ignored.
Thus formula might be placed into both a single line and multiple lines.

=head2 C<Return values>

formula_checker ind formula_calcul return nonzero on success,
the undefined value otherwise.

equality_checker returns 1 if both sets are equal, else 0.

=head2 TECHNICAL IMPLEMENTATION OF SETS

 For formula_checker and formula_calcul
 --------------------------------------
All formula operands must be highest level keys of a hash of hashes,
that is named in example below as %HoH_sets.
Lowest level keys of this hash of hashes form corresponding sets.
Values of lowest level hashes are irrelevant (can be undefined).

Name convention for formula operands: begin with a character, optionally
following by any amount of characters, digits, underlines.
Operand names are case sensitive.

 For equality_checker
 --------------------
Operands are sets, written in keys of one dimensional hashes.

=head2 EXAMPLES

 use Set::Formula;

 @A{qw (bisque  red      blue  yellow)} = (); 
 @B{qw (bisque  brown    white yellow)} = (); 
 @C{qw (magenta pink     green       )} = (); 
 @D{qw (magenta pink     rose        )} = (); 
 @E{qw (bisque  honeydew             )} = (); 
 %HoH_sets = ( A=>\%A, B=>\%B, C=>\%C, D=>\%D, E=>\%E );

or alternatively

 %HoH_sets = ( 
    A => { bisque  => 0,  red      => 0,  blue  => 0,  yellow => 0, },
    B => { bisque  => 0,  brown    => 0,  white => 0,  yellow => 0, },
    C => { magenta => 0,  pink     => 0,  green => 0,               },
    D => { grey    => 0,  pink     => 0,  rose  => 0,               },
    E => { bisque  => 0,  honeydew => 0,                            }
 );

A, B, C, D, F are operands. Every of them is a set, written in keys of sublevel hash.

 $formula  = "A ^ ( B + (C ^ D) ) - E";
 %result = ();  # this hash must be declared, but it must not be emptied before
                # call of formula_calcul()

Usage of formula_checker() before formula_calcul() is recommended,
but is not mandatory

 formula_checker ($formula)                       || die "Error in formula\n";
 formula_calcul  ($formula, \%result, \%HoH_sets) || die "Error in formula\n";

 for (keys %result) {print "$_\n"}   # prints result of formula calculation

 @expected_result{qw (magenta yellow)} = ();
 if (equality_checker (\%result, \%expected_result)) { print "equal\n" }
 else                                                { print "not equal\n" }

=head2 EXPORT

 formula_checker,
 formula_calcul,
 equality_checker.

=head1 SEE ALSO

 Part "Basic operations" - L<http://en.wikipedia.org/wiki/Set_(mathematics)>
 Infix notation          - L<http://en.wikipedia.org/wiki/Infix_notation>

=head1 AUTHOR

Mart E. Rivilis, rivilism@cpan.org

=head1 BUGS

Please report any bugs or feature requests via mail to L<bug-set-formula@rt.cpan.org>
or at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Formula>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::Formula

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)
 L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-Formula>

=item * AnnoCPAN: Annotated CPAN documentation
 L<http://annocpan.org/dist/Set-Formula>

=item * CPAN Ratings
 L<http://cpanratings.perl.org/d/Set-Formula>

=item * Search CPAN
 L<http://search.cpan.org/dist/Set-Formula/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Mart Rivilis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
