package Regexp::Extended;

use strict;
use open qw(:std :utf8);
use Carp;
use overload;
use Regexp::Extended::Match;
use Regexp::Extended::MatchGroup;
use Data::Dumper;
use re 'eval';

use vars qw(@VARS @MATCH_ARRAY $RXV $RXT $DEBUG $VERSION %EXPORT_TAGS @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(rxt rebuild upto uptoAndIncluding);
%EXPORT_TAGS = (
  "all" => \@EXPORT_OK,
);
$VERSION   = '0.01';
$DEBUG     = 0;

@VARS = ();
@MATCH_ARRAY = ();
$RXV = {};
$RXT = [];

# additional operators that are used in (?$op) constructs 
my $ops = {
  qr/\*/        => { head => '(??{Regexp::Extended::upto(\'', tail => '\')})', middle => \&escapeSlash },
  qr/\+/        => { head => '(??{Regexp::Extended::uptoAndIncluding(\'', tail => '\')})', middle => \&escapeSlash },
  qr/\&/        => { head => '(??{', tail => '})' },
  qr/<([^>]+)>/ => { head => '(?:(', tail => ')(?{ local $n = $n + 1; $Regexp::Extended::MATCH_ARRAY[$n - 1] = new Regexp::Extended::Match("$1", $^N, pos()) }))' },
};

my $const = {
  qr/\\A/ => '(?{ $n = 0; })',
  qr/\\Z/ => '(?{ splice(@Regexp::Extended::MATCH_ARRAY, $n); Regexp::Extended::analyse(); })',
};

# Matches an even number of \'s
my $evenSlashes = qr/
  (?<!\\)
  (?>
    (?:\\\\)*
  )
  (?!\\)
/x;

# Matches a complete group: (1,2,3) or (1, (2,3)) but not 1,2,(3)
our $parenGrp = qr/
  \(
  (?:
    (?> [^()\\]+ ) 
    |
    \\.
    |
    (??{ $parenGrp }) 
  )*
  \)
/x;

our $mixedParenGrp = qr/
  (?>
    (?:
      (?> 
        (?: 
          [^()\\]*
          (?:\\.)*
        )*
      )
      (?:$parenGrp)?
    )*
  )
/x;

my $currentLevel = 0;
my $currentOp    = 0;
my @currentParams = ();

sub escapeSlash {
  my ($string) = @_;

  $string =~ s/\//\\\//g;
  return $string;
}

# Go upto the supplied pattern
sub upto {
  my ($pattern) = @_;

  return qr/(?>(?:(?!$pattern).)*(?=$pattern))/;
}

# Go upto and including the supplied pattern
sub uptoAndIncluding {
  my ($pattern) = @_;

  return qr/(?>(?:(?!$pattern).)*$pattern)/;
}

sub unbalancedLevel {
  my ($string) = @_;
  my $left  = $string =~ y/\(//;
  my $right = $string =~ y/\)//;
  
  return $left - $right;
}

sub fillNumericalParams {
  my ($replaceStr) = @_;

  $replaceStr =~ s/\$(\d+)/$currentParams[$1]/g;

  return $replaceStr;
}

sub evaluateNumericalParams {
  my ($origStr, $replaceStr) = @_;
  my $nbParams = scalar @+ - 1;
  
  @currentParams = map(rg($origStr, $_), 1..$nbParams);

  $replaceStr =~ s/\$(\d+)/$currentParams[$1]/g;
  
  return $replaceStr;
}

sub rg {
  my ($origStr, $param) = @_;
  my $start   = $-[$param];
  my $length  = $+[$param] - $start;

  return substr($origStr, $start, $length);
}

sub var {
  my ($pattern) = @_;

  return qr/(?{ $n = 0; })$pattern(?{ splice(@Regexp::Extended::MATCH_ARRAY, $n); Regexp::Extended::analyse(); })/;
}

sub rxt {
  my ($pattern) = @_;
    
  foreach my $op (keys %{$ops}) {
    my $head = $ops->{$op}->{'head'};
    my $tail = $ops->{$op}->{'tail'};

    $pattern =~ s/
                  ($evenSlashes)
                  \(\?$op
                  ($mixedParenGrp)
                  \)
                /evaluateNumericalParams($pattern, rg($pattern, 1) . $head . rg($pattern, -1) . $tail)/gex;
  }

  return $pattern;
}

sub analyse {
  $RXV = {};
  $RXT = [];

  foreach my $m (@MATCH_ARRAY) {
    my $len   = length($m->{'value'});  
    my $start = $m->{'end'} - $len;
    $m->{'length'} = $len;
    $m->{'start'}  = $start;

    for(my $i = 0; $i < scalar @{$RXT}; $i++) {
      my $match = $RXT->[$i];
      
      if ($m->{'start'} <= $match->{'start'}) {
        my @group = splice(@{$RXT}, $i);
        $m->{'childs'} = \@group;
        last;
      }
    }

    push @{$RXT}, $m;

    my $name = $m->{'name'};
    if (not exists $RXV->{$name}) {
      $RXV->{$name} = new Regexp::Extended::MatchGroup(undef, $name);
      eval("\$::$name = \$RXV->{$name}");
    }

    push @{$RXV->{$name}}, $m;
  }
}

sub rebuildFromTree {
  my ($string, $tree, $last_index, $result) = @_;

  foreach my $match (@{$tree}) {
    if (defined $match->{'childs'}) {
      if ($match->{'dirty'}) {
        push @{$result}, substr($string, $last_index, $match->{'start'} - $last_index);    
        push @{$result}, $match->{'value'};
        $last_index = $match->{'end'};
      }
      else {
        $last_index = rebuildFromTree($string, $match->{'childs'}, $last_index, $result);
      }
    }
    else {
      push @{$result}, substr($string, $last_index, $match->{'start'} - $last_index);    
      push @{$result}, $match->{'value'};
      $last_index = $match->{'end'};
    }
  }

  return $last_index;
}

sub rebuild {
  my ($string) = @_;
  my @result = ();
  my $last_index = rebuildFromTree($string, $RXT, 0, \@result);
  push @result, substr($string, $last_index);
  return join('', @result);
}

sub import {
  overload::constant(
    qr => sub {
      my ($orig, $interp, $context) = @_;
 
      print STDERR "input : $interp, orig: $orig\n" if $DEBUG;

      # Search for constants
      foreach my $c (keys %{$const}) {
        $interp =~ s/$c/$const->{$c}/g;
      }
      
      # If we are in a partial match, check if the group can be closed.
      if ($currentLevel != 0) {
        my $l = $currentLevel - 1;
        my $tail = $ops->{$currentOp}->{'tail'};
        #my $func = exists $ops->{$currentOp}->{'middle'} ? $ops->{$currentOp}->{'middle'} : sub { return $_[0] };

        if ($interp =~ s/^((?:$mixedParenGrp\)){$l}$mixedParenGrp)\)/fillNumericalParams("$1$tail")/e) {
          $currentLevel = 0;
        }
        else {
          $currentLevel += unbalancedLevel($interp);
        }
      }

      if ($currentLevel == 0) {
        # Search for complete groups (?op...)
        foreach my $op (keys %{$ops}) {
          my $head = $ops->{$op}->{'head'};
          my $tail = $ops->{$op}->{'tail'};
          #my $func = exists $ops->{$op}->{'middle'} ? $ops->{$op}->{'middle'} : sub { return $_[0] };

          $interp =~ s/
                        ($evenSlashes)
                        \(\?$op
                        ($mixedParenGrp)
                        \)
                     /evaluateNumericalParams($interp, rg($interp, 1) . $head . rg($interp, -1) . $tail)/gex;
        }

        # Search for one and *only one* incomplete group (?op...
        foreach my $op (keys %{$ops}) {
          my $head = $ops->{$op}->{'head'};
          my $tail = $ops->{$op}->{'tail'};
          #my $func = exists $ops->{$op}->{'middle'} ? $ops->{$op}->{'middle'} : sub { return $_[0] };
          
          if ($interp =~ s/
                            ($evenSlashes)
                            \(\?$op
                            (.*)
                         /evaluateNumericalParams($interp, rg($interp, 1) . $head . rg($interp, -1))/gex) {
            $currentLevel = unbalancedLevel($2) + 1;  # How many ('s need to be closed
            $currentOp    = $op;                      # Which operator is incomplete
            last;
          }
        }
      }
     
      print STDERR "result: $interp\n" if $DEBUG;
      return $interp;
    },
  );

  Regexp::Extended->export_to_level(1, @_);
}

1;

__END__

=head1 NAME

Regexp::Extended - Perl wrapper that extends the re module with new features.

=head1 SYNOPSIS

  use Regexp::Extended qw(:all);

  # (?<>...): named parameters 
  $date =~ /(?<year>\d+)-(?<month>\d+)-(?<day>\d+)/;
  if ("2002-10-30" =~ /$date/) {
    print "The date is : $::year->[0]-$::month->[0]-$::day->[0]\n";
  }
  
  # You can also access individial matches in ()* or ()+
  "1234" =~ /(?<digit>\d)+/;
  print "Digit 1 is : $::digit->[0]\n";
  print "Digit 2 is : $::digit->[1]\n";
  ...

  # You can also modify individual matches
  "1234" =~ /(?<digit>\d)+/;
  $::digit->[0] = 99;
  $::digit->[1] = 88;
  print "Modified string is: " . rebuild("1234"); # "998834"

  # (?*...): upto a certain pattern
  $text = "this is some <i>italic</i> text";
  $text =~ /<i>((?*</i>))</i>/;  # $1 = "italic"

  # (?+...): upto and including a certain pattern
  $text = "this is some <i>italic</i> text";
  $text =~ /(<i>(?+</i>))/;  # $1 = "<i>italic</i>"

  # You can also use fonctions inside patterns:

  sub foo {
    return "foo";
  }

  "foo bar" =~ /((?&foo()))/; # $1 => "foo"

=head1 DESCRIPTION

Rexexp::Extended is a simple wrapper arround the perl rexexp syntax. It uses the overload module to parse constant qr// expressions and substitute known operators with an equivalent perl re.

=head1 ADDED FEATURES

=head2 named parameters: (?<var>...)

The new construct: (?<var>pattern) will match pattern and if successfull will set a numeric parameters ($1, $2, ...) as well as a named parameter ($var). The parameter is called $::var or $var if you imported Regexp::Extended with qw(:all). 

=head2 function dereferencing: (?&func(...))

The new construct: (?&function(...)) will be replaced by the result of the call to function(...). Note that the result of the call will not be evaluated for named parameters of additionnal function calls.

=head2 upto constructs: (?*...) and (?+...)

The new construct: (?*pattern) will be rewritten as follow: (?:(?!pattern).)*

You could also write is as (?&upto(pattern)) if you import Regexp::Extended with qw(:all).

This basically matches upto a certain pattern (or includes it in the latter).

=head1 EXPORTED FUNCTIONS

=head2 rxt($string), rxt($string)

This function parses a string (or pattern) and returns the transformed version according the the above operators.

=head1 AUTHOR

Daniel Shane, E<lt>lachinois@hotmail.comE<gt>

=head1 SEE ALSO

Regexp::Fields for yet another way of extending the perl re engine by patching it.

=cut
