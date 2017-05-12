package Randomize;

=head1 NAME

Randomize - Perl extension for randomizing things.

=head1 SYNOPSIS

  use Randomize;
  my $randomizer = Randomize->new(\@rules);
  print "There are ", $randomizer->permutations(),
        " different possible outcomes.\n";
  while (1) {
    my $random_hash = $randomizer->generate();
  }

=head1 DESCRIPTION

This packages takes a set of randomization rules in the form of an 
array reference, and creates random hashes on request based on 
the rules given.

I know that doesn't make sense, so here's an example.

  my @randomizer_rules =
    [ {Field  => 'Street',
       Values => [{Data   => ['Preston', 'Hillcrest'],
                   Weight => 1},
                  {Data   => ['Coit'],
                   Weight => 2}]},
      {Field  => 'Number', 
       Values => [18100..18299]}
    };

  my $randomizer = Randomize->new(\@randomizer_rules);
  while (1)
    my $hashref = $randomizer->generate();
  }

The key is @randomizer_rules.  What this list tells Randomizer is that,
every time you invoke the generate() method, you want to get back a reference
to a hash that looks like:

  $hashref = { Street => 'Preston', 
               Number => 18111 };

where the Number is between 18100 and 18299 and the Street is either Preston, 
Hillcrest, or Coit.  Further, you want the numbers to be evenly distributed,
but you want the street to be Coit half the time, and evenly distributed 
between Preston and Hillcrest the rest of the time.

So, if you called $randomizer->generate() 1000 times, you'd get roughly
500 addresses on Coit and 250 addresses each on Preston and Hillcrest.

Let's look at a more complicated @randomizer_rules now.

  my @randomizer_rules =
    ( {Field  => 'Street',
       Values => [{Data   => ['Preston', 'Hillcrest'],
                   Weight => 1},
                  {Data   => ['Coit'],
                   Weight => 2}]},
      {Field  => 'Number', 
       Values => [{Precondition => "<<Street>> eq 'Preston'",
                   Alternatives => [{Data => [18100..18199],
                                     Weight => 1},
                                    {Data => [18200..18299],
                                     Weight => 9}]},
                  {Precondition    => 'DEFAULT',
                   Alternatives => [{Data => [18100..18299],
                                     Weight => 1}]}]}
    );

Given this, the generate() method will still return a hash reference in
the form

  $hashref = { Street => 'Preston', 
               Number => 18111 };

with the same streets and address ranges.  However, if the street
picked happens to be Preston, 90% of the addresses generated 
will be in the range 18200 to 18299.

In final example, note the Retry_If clause:

  my @randomizer_rules =
    ( {Field  => 'Street',
       Values => [{Data   => ['Preston', 'Hillcrest'],
                   Weight => 1},
                  {Data   => ['Coit'],
                   Weight => 2}]},
      {Field  => 'Number', 
       Values => [{Precondition => "<<Street>> eq 'Preston'",
                   Alternatives => [{Data => [18100..18199],
                                     Weight => 1},
                                    {Data => [18200..18299],
                                     Weight => 9}],
                   Retry_If     => ['defined $main::addr1 && <<Number>> == $main::addr1->{Number}']},
                  {Precondition    => 'DEFAULT',
                   Alternatives => [{Data => [18100..18299],
                                     Weight => 1}]}]}
    );

  my $randomizer = Randomize->new(\@randomizer_rules);
  while (1)
    $main::addr1 = $main::addr2 = undef;
    $main::addr1 = $randomizer->generate();
    $main::addr2 = $randomizer->generate();
  }

In this example, we're generating pairs of addresses.  The Retry_If clause 
ensures that we never get a pair of identical addresses on Preston.  It's
still possible to get identical addresses on Coit or Hillcrest, however.

Retry_If clauses may also appear at the same level as Field and Values, 
like so:

  my @randomizer_rules =
    ( {Field  => 'Street',
       Values => ['Preston', 'Hillcrest', 'Coit']},
      {Field  => 'Number', 
       Values => [18100..18299],
       Retry_If => ['<<Street>> eq 'Coit' && <<Number>> eq 18200']}
    );

This ruleset tells Randomize to try again if the address generated
is 18200 Coit.

There is also one special rule that Randomize looks for:  "DEBUG".
A "DEBUG ON" rule turns debugging messages on so you can see what's
happening when you call generate().  It also attempts to print the 
code it generates to a file.  You can optionally pass the filename
in, like "DEBUG ON myfile.code", or if you don't specify a file, 
the default output file is "Randomize.code".  If the file can't
be opened for writing, a warning is sent to standard error, but
execution of your program is otherwise unaffected.

Correspondingly, a "DEBUG OFF" rule turns debugging off, although
the code is still printed.  Placement of "DEBUG ON" and "DEBUG OFF"
statements determines which fields debugging information is printed for.
For example, take a look at the following ruleset:

  my @randomizer_rules =
    ( 'DEBUG ON',
      {Field  => 'Street',
       Values => ['Preston', 'Hillcrest', 'Coit']},
      'DEBUG OFF',
      {Field  => 'Number', 
       Values => [18100..18299],
       Retry_If => ['<<Street>> eq 'Coit' && <<Number>> eq 18200']},
    );

This ruleset results in debugging information being printed for
generation of the "Street" field, but not for the "Number" field,
and code will be printed to the file "Randomize.code".

NOTE:  Randomize cannot currently generate anything other than simple
hashes.  If you want a complex data structure, you'll have to either
build it yourself by moving items around in the returned hash, or by
using multiple randomize objects.

=head2 EXPORT

None.

=head1 AUTHOR

Brand Hilton

=head1 PUBLIC METHODS
 

=cut


# $Id: Randomize.pm,v 1.10 2001/04/30 13:09:40 bhilton Exp $

# $Log: Randomize.pm,v $
# Revision 1.10  2001/04/30 13:09:40  bhilton
# Added generate_all method
#
# Revision 1.9  2001/04/24 21:59:35  bhilton
# Documentation updates
#
# Revision 1.8  2001/04/24 14:02:42  bhilton
# - Added permutations method
# - Fixed bug that would cause problems if you used both
#   varieties of Retry_If at the same time
#
# Revision 1.7  2001/01/23 15:12:35  bhilton
# Moving to rev 1.7 for the CPAN bundle.
#
# Revision 1.6  2001/01/22 15:13:07  bhilton
# Added lots of error checking, fixed a couple of minor bugs.
#
# Revision 1.5  2000/12/01 19:41:08  bhilton
# Changed first-level "Alternatives" to "Values".
# Added DEBUG flag.
#
# Revision 1.4  2000/11/21 20:40:16  bhilton
# Added "Retry_If" capabilities.
#
# Revision 1.3  2000/11/18 23:50:59  bhilton
# Various improvements and bug fixes.
#
# Revision 1.2  2000/11/18 22:56:38  bhilton
# When you call generate, you can now specify the value of one or more
# fields in the hash.
#
# Revision 1.1  2000/11/18 22:07:59  bhilton
# Initial revision
#

require 5.005_62;
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;

our ($VERSION) = '$Revision: 1.10 $'=~/(\d+(\.\d+))/;

our $errmsg = '';


sub _process_alternatives {
  my ($fieldname, $valueno, $alts) = @_;
  my @array;

  foreach my $index (0..$#{$alts}) {
    my $ary = $alts->[$index];

    unless (exists $ary->{Data}) {
      $errmsg = "Field $fieldname Value $valueno Alternative $index "
              . "doesn't contain a Data element"; 
      return;
    }

    unless (exists $ary->{Weight}) {
      $errmsg = "Field $fieldname Value $valueno Alternative $index "
              . "doesn't contain a Weight element"; 
      return;
    }

    unless (ref $ary->{Data} eq 'ARRAY') {
      $errmsg = "Field $fieldname Value $valueno Alternative $index: "
              . "Data element isn't an array ref."; 
      return;
    }

    unless ($ary->{Weight} =~ /^\d+$/) {
      $errmsg = "Field $fieldname Value $valueno Alternative $index: "
              . "Weight element isn't a positive integer."; 
      return;
    }

    push @array, (@{$ary->{Data}}) x $ary->{Weight};
  }
  return Data::Dumper->Dump([\@array], ['$stuff']);
}


# _create_generate_method
#
# This subroutine creates the Generate method of the randomizer.
# It takes the same set of rules that the new() method takes, and
# returns a code reference.

sub _create_generate_method {
  my ($rules) = @_;

  my $print_filename;   # Name of the file to print code to.  Also serves
                        # as a flag signalling whether to print code at all.

  my $code = "sub {\n"
           . "  my \%retval = \@_;\n"
           . "  my \$stuff;\n"
           . "  my \$debug = 0;\n"
           . "  my \$counter;\n\n";

  foreach my $i (0..$#{$rules}) {
    if ($rules->[$i] =~ /^\s*DEBUG\s/i) {
      unless ($rules->[$i] =~ /^\s*DEBUG\s+(ON|OFF)\s*(.*?)\s*$/i) {
        $errmsg = "Syntax error in DEBUG directive";
        return;
      }
      my $onoff = uc $1;
      $print_filename = $2 || 'Randomize.code' if $onoff eq 'ON';
      $code .= "  \$debug = " . {ON => 1, OFF => 0}->{$onoff} . ";\n\n";
      next;
    }

    unless (exists $rules->[$i]{Field}) {
      $errmsg = "Rule " . ($i+1) . " doesn't contain a field name"; 
      return;
    }

    unless (exists $rules->[$i]{Values}) {
      $errmsg = "Field '$rules->[$i]{Field}' doesn't have a Values field"; 
      return;
    }


    my $fieldname = $rules->[$i]{Field};

    if (ref $rules->[$i]{Values} eq 'ARRAY') {
      my $outer_retry_clause;
      my $outer_indent = '  ';
      if (exists $rules->[$i]{Retry_If}) {
        $outer_retry_clause = '('
                      . join(') || (', @{$rules->[$i]{Retry_If}})
                      . ')';
        $outer_retry_clause =~ s/<<(.*?)>>/\$retval{$1}/g;
      }
      if (ref $rules->[$i]{Values}[0] eq '') {
        # In the form [1..15] or ['one', 'two', 'three']
        if (exists $rules->[$i]{Retry_If}) {
          $code .= _retry_if_start_for_generate($outer_retry_clause, 
                                                $fieldname, 
                                                $outer_indent);
          $outer_indent .= '      ';
        }
        my $temp_code = Data::Dumper->Dump([$rules->[$i]{Values}], ['$stuff']);
        $temp_code =~ s/^/  /mg;
        $code .= $temp_code;
        if (exists $rules->[$i]{Retry_If}) {
          $code .= _retry_if_finish_for_generate($outer_retry_clause, 
                                                 $fieldname, 
                                                 $outer_indent);
        }
        else {
          $code .= "  \$retval{$fieldname} ||= \$stuff->[rand \@\$stuff];\n";
          $code .= "  print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
        }
      }
      elsif (ref $rules->[$i]{Values}[0] eq 'HASH') {
        if (exists $rules->[$i]{Values}[0]{Alternatives}) {
          # In the form [{Precondition => "<<Street>> eq 'Preston'",
          #               Alternatives => [{Data => [18100..18199],
          #                                 Weight => 1},
          #                                {Data => [18200..18299],
          #                                 Weight => 9}],
          #               Retry_If     => "<<Number>> == 18113"},
          #              {Precondition => 'DEFAULT',
          #               Alternatives => [{Data => [18100..18299],
          #                                 Weight => 1}]}]
          my $done = 0;
          my $branchno = 1;
          $code .= "  \$counter = 0;\n";
          foreach my $j (0..$#{$rules->[$i]{Values}}) {
            my $hash = $rules->[$i]{Values}[$j];

            unless (exists $hash->{Precondition}) {
              $errmsg = "Field '$fieldname', Value " . ($j+1) .
                        ": No precondition given.";
              return;
            }

            unless (exists $hash->{Alternatives}) {
              $errmsg = "Field '$fieldname', Value " . ($j+1) .
                        ": No alternatives given.";
              return;
            }

            my $condition = $hash->{Precondition};
            if ($condition eq 'DEFAULT') {
              if ($branchno > 1) {
                $code .= "  else {\n";
                $code .= "    print \"Field $fieldname, inside else\\n\" if \$debug;\n";
              }
              else {
                $code .= "  if (1) {\n";
                $code .= "    print \"Field $fieldname, inside if (1)\\n\" if \$debug;\n";
              }
              $done = 1;
            }
            else {
              if ($done) {
                $errmsg = "Error in field '$fieldname':  " .
                          "DEFAULT must be the last condition listed.";
                return;
              }
              $condition =~ s/<<(.*?)>>/\$retval{$1}/g;
              $code .= '  ';
              $code .= 'els' if $branchno > 1;
              $code .= "if ($condition) {\n";
              $code .= "    print \"Field $fieldname, inside branch number $branchno\\n\" if \$debug;\n";
              $branchno++;
            }

            my $retry_clause;
            my $indent = '    ';
            if (exists $hash->{Retry_If}) {
              $retry_clause = '('
                            . join(') || (', @{$hash->{Retry_If}})
                            . ')';
              $retry_clause =~ s/<<(.*?)>>/\$retval{$1}/g;
            }

            if (exists $hash->{Retry_If} || exists $rules->[$i]{Retry_If}) {
              my @clauses;
              push @clauses, $retry_clause if exists $hash->{Retry_If};
              push @clauses, $outer_retry_clause 
                if exists $rules->[$i]{Retry_If};
              $retry_clause = '(' . join(' || ', @clauses) . ')';
              $code .= _retry_if_start_for_generate($retry_clause, 
                                                    $fieldname, 
                                                    $indent);
              $indent .= '    ';
            }

            my $temp_code;
            if (ref $hash->{Alternatives}[0] eq '') {
              # In the form [1..15] or ['one', 'two', 'three']
              $temp_code = Data::Dumper->Dump([$hash->{Alternatives}], ['$stuff']);
            }
            elsif (ref $hash->{Alternatives}[0] eq 'HASH') {
              $temp_code = _process_alternatives($fieldname, $j, 
                                                 $hash->{Alternatives})
                or return;
            }
            else {
              $errmsg = "Error in Field '$fieldname'.  " . 
                        "First element of the conditional Alternatives " .
                        "array is neither a scalar nor an array.";
              return;
            }
            $temp_code =~ s/^/$indent/mg;
            $code .= $temp_code;

            if (exists $hash->{Retry_If} || exists $rules->[$i]{Retry_If}) {
              $code .= _retry_if_finish_for_generate($retry_clause, 
                                                     $fieldname, 
                                                     $indent);
            }
            else {
              $code .= $indent . "\$retval{$fieldname} ||= \$stuff->[rand \@\$stuff];\n\n";
              $code .= $indent . "print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
            }
            $code .= "  }\n\n";
          }
          #if (exists $rules->[$i]{Retry_If}) {
          #  $code .= substr($outer_indent, 0, length($outer_indent)-2) . "}\n";
          #  $code .= substr($outer_indent, 0, length($outer_indent)-4) . "}\n";
          #}
        }
        else {
          # In the form [{Data   => [1..5], 
          #               Weight => 1}, 
          #              {Data   => [6..10],
          #               Weight => 2}]
          if (exists $rules->[$i]{Retry_If}) {
            $code .= _retry_if_start_for_generate($outer_retry_clause, 
                                                  $fieldname, 
                                                  $outer_indent);
            $outer_indent .= '      ';
          }
          my $temp_code .= (_process_alternatives($fieldname, 0, 
                            $rules->[$i]{Values})
                            or return);
          $temp_code =~ s/^/$outer_indent/mg;
          $code .= $temp_code;
          if (exists $rules->[$i]{Retry_If}) {
            $code .= _retry_if_finish_for_generate($outer_retry_clause, 
                                                   $fieldname, 
                                                   $outer_indent);
          }
          else {
            $code .= "  \$retval{$fieldname} ||= \$stuff->[rand \@\$stuff];\n\n";
            $code .= "  print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
          }
        }
      }
      else {
        $errmsg = "Error in field '$fieldname':  " .
                  "First element of Values is neither a scalar nor a hash.";
        return;
      }
    }
    else {
      $errmsg = "Error in field '$fieldname':  " . 
                "Values element should be an array.";
      return;
    }
  }

  $code .= "  return \\\%retval;\n}\n";

  if ($print_filename) {
    if (open CODE, ">$print_filename") {
      print CODE "# generate() method\n\n", $code;
      close CODE;
    }
    else {
      print STDERR "Failed to open $print_filename for writing: $!";
    }
  }

  my $retval = eval $code;
  unless (defined $retval) {
    $errmsg = $@;
    return;
  }
  return $retval;
}


# _create_permutations_generateall_method
#
# This subroutine creates the anonymous sub that implements both
# the permutations() and the generate_all() methods of the randomizer.
# It takes the same set of rules that the new() method takes, and
# returns a code reference.

sub _create_permutations_generateall_method {
  my ($rules) = @_;

  my $print_filename;   # Name of the file to print code to.  Also serves
                        # as a flag signalling whether to print code at all.
  my $nestlevel = 0;
  
  my @fieldnames;

  my $retry_code = '';

  my $code = "sub {\n"
           . "  my \$count_or_generate = shift;\n"
           . "  my \%parms  = \@_;\n"
           . "  my \%retval = \@_;\n"
           . "  my \$stuff;\n"
           . "  my \$debug = 0;\n"
           . "  my \@retlist;\n"
           . "  my \$permutations = 0;\n\n";

  foreach my $i (0..$#{$rules}) {
    if ($rules->[$i] =~ /^\s*DEBUG\s/i) {
      unless ($rules->[$i] =~ /^\s*DEBUG\s+(ON|OFF)\s*(.*?)\s*$/i) {
        $errmsg = "Syntax error in DEBUG directive";
        return;
      }
      my $onoff = uc $1;
      $print_filename = $2 || 'Randomize.code' if $onoff eq 'ON';
      $code .= "  \$debug = " . {ON => 1, OFF => 0}->{$onoff} . ";\n\n";
      next;
    }

    unless (exists $rules->[$i]{Field}) {
      $errmsg = "Rule " . ($i+1) . " doesn't contain a field name"; 
      return;
    }

    unless (exists $rules->[$i]{Values}) {
      $errmsg = "Field '$rules->[$i]{Field}' doesn't have a Values field"; 
      return;
    }


    my $fieldname = $rules->[$i]{Field};

    if (ref $rules->[$i]{Values} eq 'ARRAY') {
      my $outer_retry_clause;
      my $outer_indent = '  ';
      if (exists $rules->[$i]{Retry_If}) {
        $outer_retry_clause = '('
                      . join(') || (', @{$rules->[$i]{Retry_If}})
                      . ')';
        $outer_retry_clause =~ s/<<(.*?)>>/\$retval{$1}/g;
        $retry_code .= "    if ($outer_retry_clause) {\n";
        $retry_code .= "      print \"  rejected\\n\" if \$debug;\n";
        $retry_code .= "      next;\n";
        $retry_code .= "    }\n";
        #$code .= _retry_if_start_for_permutations($outer_retry_clause, 
        #                                          $fieldname, 
        #                                          $outer_indent);
        $outer_indent .= '      ';
      }
      if (ref $rules->[$i]{Values}[0] eq '') {
        # In the form [1..15] or ['one', 'two', 'three']
        my $temp_code = Data::Dumper->Dump([$rules->[$i]{Values}], ['$stuff']);
        $temp_code =~ s/^/    /mg;
        $code .= "  if (\$parms{$fieldname}) {\n";
        $code .= "    \$stuff = [\"\$parms{$fieldname}\"];\n";
        $code .= "  }\n";
        $code .= "  else {\n";
        $code .= $temp_code;
        $code .= "  }\n";
        $code .= "  foreach my \$thingy (\@\$stuff) {\n";
        $code .= "    \$retval{$fieldname} = \$thingy;\n";
        $code .= "    print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
        $fieldnames[$nestlevel] = $fieldname;
        $nestlevel++;
      }
      elsif (ref $rules->[$i]{Values}[0] eq 'HASH') {
        if (exists $rules->[$i]{Values}[0]{Alternatives}) {
          # In the form [{Precondition => "<<Street>> eq 'Preston'",
          #               Alternatives => [{Data => [18100..18199],
          #                                 Weight => 1},
          #                                {Data => [18200..18299],
          #                                 Weight => 9}],
          #               Retry_If     => "<<Number>> == 18113"},
          #              {Precondition => 'DEFAULT',
          #               Alternatives => [{Data => [18100..18299],
          #                                 Weight => 1}]}]
          my $done = 0;
          my $branchno = 1;
          $code .= "  if (\$parms{$fieldname}) {\n";
          #$code .= "    \$stuff = [\"\$parms{$fieldname}\"];\n";
          $code .= "    \$stuff = [\$parms{$fieldname}];\n";
          $code .= "  }\n";
          foreach my $j (0..$#{$rules->[$i]{Values}}) {
            my $hash = $rules->[$i]{Values}[$j];

            unless (exists $hash->{Precondition}) {
              $errmsg = "Field '$fieldname', Value " . ($j+1) .
                        ": No precondition given.";
              return;
            }

            unless (exists $hash->{Alternatives}) {
              $errmsg = "Field '$fieldname', Value " . ($j+1) .
                        ": No alternatives given.";
              return;
            }

            my $condition = $hash->{Precondition};
            if ($condition eq 'DEFAULT') {
              if ($branchno > 1) {
                $code .= "  else {\n";
                $code .= "    print \"Field $fieldname, inside else\\n\" if \$debug;\n";
              }
              else {
                $code .= "  if (1) {\n";
                $code .= "    print \"Field $fieldname, inside if (1)\\n\" if \$debug;\n";
              }
              $done = 1;
            }
            else {
              if ($done) {
                $errmsg = "Error in field '$fieldname':  " .
                          "DEFAULT must be the last condition listed.";
                return;
              }
              $condition =~ s/<<(.*?)>>/\$retval{$1}/g;
              $code .= "  elsif ($condition) {\n";
              $code .= "    print \"Field $fieldname, inside branch number $branchno\\n\" if \$debug;\n";
              $branchno++;
            }

            my $retry_clause;
            my $indent = '    ';
            if (exists $hash->{Retry_If}) {
              $retry_clause = '('
                            . join(') || (', @{$hash->{Retry_If}})
                            . ')';
              $retry_clause =~ s/<<(.*?)>>/\$retval{$1}/g;
              $retry_code .= "    if ($retry_clause) {\n";
              $retry_code .= "      print \"  rejected\\n\" if \$debug;\n";
              $retry_code .= "      next;\n";
              $retry_code .= "    }\n";
              #$code .= _retry_if_start_for_permutations($retry_clause, 
              #                                          $fieldname, 
              #                                          $indent);
              $indent .= '    ';
            }

            my $temp_code;
            if (ref $hash->{Alternatives}[0] eq '') {
              # In the form [1..15] or ['one', 'two', 'three']
              $temp_code = Data::Dumper->Dump([$hash->{Alternatives}], ['$stuff']);
            }
            elsif (ref $hash->{Alternatives}[0] eq 'HASH') {
              my @array;
              foreach my $index (0..$#{$hash->{Alternatives}}) {
                my $ary = $hash->{Alternatives}[$index];
                push @array, @{$ary->{Data}};
              }
              $temp_code = Data::Dumper->Dump([\@array], ['$stuff']);
            }
            else {
              $errmsg = "Error in Field '$fieldname'.  " . 
                        "First element of the conditional Alternatives " .
                        "array is neither a scalar nor an array.";
              return;
            }
            $temp_code =~ s/^/$indent/mg;
            $code .= $temp_code;
            $code .= "  }\n";
          }
          $code .= "  foreach my \$thingy (\@\$stuff) {\n";
          $code .= "    my \$stuff;\n";
          $code .= "    \$retval{$fieldname} = \$thingy;\n";
          $code .= "    print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
          $fieldnames[$nestlevel] = $fieldname;
          $nestlevel++;
        }
        else {
          # In the form [{Data   => [1..5], 
          #               Weight => 1}, 
          #              {Data   => [6..10],
          #               Weight => 2}]
          my @array;
          foreach my $index (0..$#{$rules->[$i]{Values}}) {
            my $ary = $rules->[$i]{Values}[$index];
            push @array, @{$ary->{Data}};
          }
          my $temp_code = Data::Dumper->Dump([\@array], ['$stuff']);
          $temp_code =~ s/^/$outer_indent/mg;
          $code .= $outer_indent . "if (\$parms{$fieldname}) {\n";
          $code .= $outer_indent . "  \$stuff = [\"\$parms{$fieldname}\"];\n";
          $code .= $outer_indent . "}\n";
          $code .= $outer_indent . "else {\n";
          $code .= $temp_code;
          $code .= $outer_indent . "}\n";
          $code .= $outer_indent . "foreach my \$thingy (\@\$stuff) {\n";
          $code .= $outer_indent . "  \$retval{$fieldname} = \$thingy;\n";
          $code .= $outer_indent . "  print \"$fieldname just set to \$retval{$fieldname}\\n\" if \$debug;\n\n";
          $fieldnames[$nestlevel] = $fieldname;
          $nestlevel++;
        }
      }
      else {
        $errmsg = "Error in field '$fieldname':  " .
                  "First element of Values is neither a scalar nor a hash.";
        return;
      }
    }
    else {
      $errmsg = "Error in field '$fieldname':  " . 
                "Values element should be an array.";
      return;
    }
  }

  $code .= $retry_code;
  $code .= "  if (\$count_or_generate eq 'count') {\n";
  $code .= "    \$permutations++;\n";
  $code .= "  }\n";
  $code .= "  else {\n";
  $code .= "    push \@retlist, {\%retval};\n";
  $code .= "  }\n";

  while ($nestlevel) {
    $nestlevel--;
    $code .= "delete \$retval{$fieldnames[$nestlevel]};\n";
    $code .= "}\n";
  }
  $code .= "\n\n";
  $code .= "  return \$count_or_generate eq 'count' ? \$permutations\n";
  $code .= "                                       : \@retlist;\n";
  $code .= "}\n";

  if ($print_filename) {
    if (open CODE, ">>$print_filename") {
      print CODE "\n\n\n# permutations() and generate_all() method\n\n", $code;
      close CODE;
    }
    else {
      print STDERR "Failed to open $print_filename for append: $!";
    }
  }

  my $retval = eval $code;
  unless (defined $retval) {
    $errmsg = $@;
    return;
  }
  return $retval;
}


=head1 new

=head2 Description

This is the constructor for Randomize objects.  It takes one parameter:
a reference to an array containing randomizer rules.  From these rules, 
the generate() and permutations() methods are created.  If an error is 
detected in the rules, the package variable $Randomize::errmsg will contain 
the error message and new() will return undef.

=head2 Syntax

  $randomizer = Randomize->new(\@rules);

    $randomizer  - On success, a Randomize object.  On failure, undef
                   is returned and $Randomize::errmsg will contain a
                   descriptive error message.

    \@rules      - A reference to an array containing Randomize rules, 
                   as described in the DESCRIPTION section.

=cut

sub new {
  my ($class, $rules) = @_;
  $errmsg = '';
  $errmsg = "No class specified", return unless $class;
  $errmsg = "No rules specified", return unless $rules;
  $errmsg = "\$rules is not an array ref", return
    unless ref $rules eq 'ARRAY';

  my $self = {};

  return unless $self->{Generate} = _create_generate_method($rules);

  return unless $self->{Permutations_and_Generate_All} = 
                _create_permutations_generateall_method($rules);


  bless $self, $class;

} # new




##################################################################
#
# _retry_if_start_for_generate
#
# Generates code for the Retry_If clause for the generate method.
#
# Syntax:
#
#   $code = _retry_if_start_for_generate($retry_clause, $fieldname, $indent);

sub _retry_if_start_for_generate {
  my ($retry_clause, $fieldname, $indent) = @_;

  my $code = '';
  $code .= "if (exists  \$retval{$fieldname}) {\n";
  $code .= "  print \"The user specified a value for $fieldname\\n\" if \$debug;\n";
  $code .= "  if ($retry_clause) {\n";
  $code .= "    die \"The user-specified value for $fieldname violates the Retry_If rule.\"\n";
  $code .= "  }\n";
  $code .= "}\n";
  $code .= "else {\n";
  $code .= "  my \$done = 0;\n";
  $code .= "  while (!\$done) {\n";
  $code .= "    print \"Getting ready to choose a value for $fieldname\\n\" if \$debug;\n";
  $code .= "    \$counter++;\n";
  $code =~ s/^/$indent/mg;

  return $code;
}




##################################################################
#
# _retry_if_finish_for_generate
#
# Generates code for the Retry_If clause for the generate method.
#
# Syntax:
#
#   $code = _retry_if_finish_for_generate($retry_clause, $fieldname, $indent);

sub _retry_if_finish_for_generate {
  my ($retry_clause, $fieldname, $indent) = @_;
  my $code = $indent . "\$retval{$fieldname} = \$stuff->[rand \@\$stuff];\n";
  $code .= $indent . "print \"$fieldname just set to \", Dumper(\$retval{$fieldname}), \"\\n\" if \$debug;\n\n";
  $code .= $indent . "if ($retry_clause) {\n";
  $code .= $indent . "  print \"Gonna have to retry\\n\" if \$debug;\n";
  $code .= $indent . "  die <<EOT if \$counter >= 100;\n";
  $code .= "Couldn't find a usable value for $fieldname in 100 tries.\n";
  $code .= "Maybe your retry clauses are too restrictive.\n";
  $code .= "EOT\n";
  $code .= $indent . "}\n";
  $code .= $indent . "else {\n";
  $code .= $indent . "  print \"Passed the retry clause.\\n\" if \$debug;\n";
  $code .= $indent . "  \$done = 1;\n";
  $code .= $indent . "}\n";
  $code .= substr($indent, 0, length($indent)-2) . "}\n";
  $code .= substr($indent, 0, length($indent)-4) . "}\n";
  return $code;
}




##################################################################
#
# _retry_if_start_for_permutations
#
# Generates code for the Retry_If clause for the permutations method.
#
# Syntax:
#
#   $code = _retry_if_start_for_permutations($retry_clause, $fieldname, $indent);

sub _retry_if_start_for_permutations {
  my ($retry_clause, $fieldname, $indent) = @_;

  my $code = '';
  $code .= "if (exists  \$retval{$fieldname}) {\n";
  $code .= "  print \"The user specified a value for $fieldname\\n\" if \$debug;\n";
  $code .= "  if ($retry_clause) {\n";
  $code .= "    die \"The user-specified value for $fieldname violates the Retry_If rule.\"\n";
  $code .= "  }\n";
  $code .= "}\n";
  $code .= "else {\n";
  $code =~ s/^/$indent/mg;

  return $code;
}


=head1 generate

=head2 Description

This method returns a reference to a hash.  The hash contains the fields
you specified in your randomizer rules.  Each call to generate() gives you
a new hash, with a new set of randomized values.

NOTE:  If you wish to specify a value for one or more fields of the hash,
you can pass in the field and its value.

=head2 Syntax

  $hashref = $randomizer->generate( [ $fieldname, $value, ... ] );

    $hashref    - A hash reference returned by generate().

    $randomizer - A Randomize object.

    $fieldname  - The name of a field in the hash.

    $value      - The value you wish that field to take 
                  this time through.

=cut



sub generate {
  my $self = shift;
  &{$self->{Generate}}(@_);
}


=head1 permutations

=head2 Description

This method returns the number of permutations of the hash you've 
specified.

NOTE:  If you wish to specify a value for one or more fields of the hash,
you can pass in the field and its value.

=head2 Syntax

  $permutations = $randomizer->permutations( [ $fieldname, $value, ... ] );

    $permutations - The exact number of permutations of the
                    hash you've specified.

    $randomizer   - A Randomize object.

    $fieldname    - The name of a field in the hash.
                 
    $value        - The value you wish that field to take 
                    this time through.

=cut



sub permutations {
  my $self = shift;
  &{$self->{Permutations_and_Generate_All}}('count',@_);
}





=head1 generate_all

=head2 Description

This method returns a list containing every permutation of the hash you've 
specified.

NOTE:  If you wish to specify a value for one or more fields of the hash,
you can pass in the field and its value.

=head2 Syntax

  @permutations = $randomizer->generate_all( [ $fieldname, $value, ... ] );

    @permutations - A list containing every possible permutation
                    of the hash you've specified.

    $randomizer   - A Randomize object.

    $fieldname    - The name of a field in the hash.
                 
    $value        - The value you wish that field to take 
                    this time through.

=cut



sub generate_all {
  my $self = shift;
  &{$self->{Permutations_and_Generate_All}}('generate',@_);
}

1;

