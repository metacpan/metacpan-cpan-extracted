# String::RexxParse.pm
#
# Copyright (c) 1999, 2000, 2001, 2002 Dan Campbell (String::RexxParse->email).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This module is intended to provide REXX-like parsing in Perl.
#
# Documentation at http://www.danofsteel.com/Parser

package String::RexxParse;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION $debug);

require Exporter;

@ISA    = qw(Exporter);
@EXPORT_OK = qw(parse drop);
$VERSION = "1.10";

use Carp;

require 5.003; # 5.003 is required to support subroutine prototypes.


sub _packagize
{
  my $in = shift;
  my $callpkg = shift;
  while ($in =~ /\$(\w+(?=\W|$)(?!::))/g)
  {
    substr($in,pos($in)-length($1),length($1)) = "$callpkg\:\:$1";
  }
  return $in;
}



sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }
sub min { $_[0] <= $_[1] ? $_[0] : $_[1] }
sub email { reverse 'moc.leetsfonad' . '@' . 'esrapxxer' }



sub _tokens
{
  my $template = shift;
  my $callpkg = shift;
  my $matchpos = 0;

  my ($tok,@tok) = ("");

  my $tokexp = <<'TOK';
  \G(
    \'[^']*\' |
    \"[^"]*\" |
    \([^()]*\) |
    [=]?\d+ |
    [=]\([^()]*\) |
    [-+]\d+ |
    [-+]\([^()]*\) |
    [.] |
    (?:\w|[$&])\S* |
    \s+
  )
TOK

  while ( $template =~ m/$tokexp/gox)
  {
    my $match = $1;
    unless ($match =~ /^\s*$/) 
    { 
      for ($match)
      {
        if (/^[.]$/)
        {
          push @tok,$match;
          $tok .= 'v';
          last;
        }
        if (/^\(/)
        {
          if ($tok =~ /(?:^$|[LP]$)/)
          {
            push @tok, '.';
            $tok .= 'v';
            redo;
          }
          $match =~ s/^\(//;
          $match =~ s/\)$//;
          push @tok,_packagize('quotemeta('.$match.')',$callpkg);
          $tok .= 'P';
          last;
        }
        if (/^['"]/)
        {
          if ($tok =~ /(?:^$|[LP]$)/)
          {
            push @tok, '.';
            $tok .= 'v';
            redo;
          }
          $match =~ s/^['"]//;
          $match =~ s/['"]$//;
          push @tok,quotemeta($match);
          $tok .= 'L';
          last;
        }
        if (/^[=]?\d+/)
        {
          $match =~ s/^=//;
          push @tok,$match;
          $tok .= 'N';
          last;
        }
        if (/^[=]\(/)
        {
          $match =~ s/(?:^=\(|\)$)//g;
          push @tok,_packagize($match,$callpkg);
          $tok .= 'n';
          last;
        }
        if (/^[-+]\d+/)
        {
          push @tok,$match;
          $tok .= 'R';
          last;
        }
        if (/^[-+]\(/)
        {
          $match =~ s/^([-+])\(/$1/;
          $match =~ s/\)$//;
          push @tok,_packagize($match,$callpkg);
          $tok .= 'r';
          last;
        }
        if (/^\S+$/)
        {
          push @tok, _packagize($match,$callpkg);
          $tok .= 'V';
          last;
        }
      }
      if ($tok =~ /L$/) 
      { 
        eval "my \$test = \"$tok[$#tok]\"";
        if ($@) { croak "Syntax error in template near >$match<" }
      }
      elsif ($tok =~ /V$/) 
      { 
        eval "$tok[$#tok] = $tok[$#tok]";
        if ($@) { croak "Syntax error in template near >$match<" }
      }
      elsif ($tok !~ /v$/)
      { 
        eval "my \$test = $tok[$#tok]";
        if ($@) { croak "Syntax error in template near >$match<" }
      }
    }
    $matchpos = pos($template);

  }

  croak "Syntax error in template near position $matchpos\n===>$template<===\n" 
    unless $matchpos == length($template);

  if ($tok =~ /[PL]$/)
  {
    push @tok, '.';
    $tok .= 'v';
  }
  return ($tok,@tok);

}






sub _VvRN (\@\$)
{
  my ($value,$type) = @_;
  my $utemplate = "";
  my $tmp = "";
  my $pos = 0;
  my $next = 0;
  my @vars = ();
  my @tvars = ();
  my $max = 0;
  my $cur = 0;

  my $parser = "sub\n{\n  my \@list = ();\n  eval\n  {\n    my \$source = shift;\n    my \@tlist = ();\n" .  "    \@list = ";
  for my $i (0..$#$value)
  {
    for (substr($$type,$i,1))
    {
      if (/^[Vv]$/)
      {
        push @tvars, $$value[$i];
      }
      elsif (/^R$/)
      {
        if (@tvars > 1)
        {
          $tmp .= '    @tlist = split(q( ),splice(@list,'.$next.',1),' . 
            scalar(@tvars) . ');'."\n";
          $tmp .= '    push @tlist, ("") x ('.scalar(@tvars).'-@tlist);' ."\n";
          $tmp .= '    splice @list,'.$next.',0,splice(@tlist,0);' . "\n";
          $next += $#tvars;
        }
        push @vars, @tvars;
        @tvars = ();
        if ($$value[$i] =~ /^[+]/)
        {
          unless ($i > 0) { $utemplate .= 'x' . eval $$value[$i] }
          else 
          { 
            $utemplate .= 'a' . eval $$value[$i];
          }
          $pos = $pos + eval $$value[$i];
          $next++;
        }
        else
        {
          if ($i > 0)
          {
            $pos = max(0,$pos + eval $$value[$i]);
            $utemplate .= 'a*X*x' . $pos;
            $next++;
          }
        }
        $cur += eval $$value[$i];
        $max= $cur if $cur > $max;
      }
      elsif (/^N$/)
      {
        if (@tvars > 1)
        {
          $tmp .= '    @tlist = split(q( ),splice(@list,'.$next.',1),' . 
             scalar(@tvars) . ');'."\n";
          $tmp .= '    push @tlist, ("") x ('.scalar(@tvars).'-@tlist);' ."\n";
          $tmp .= '    splice @list,'.$next.',0,splice(@tlist,0);' . "\n";
          $next += $#tvars;
        }
        push @vars, @tvars;
        @tvars = ();
        if ($pos < eval $$value[$i])
        {
          unless ($i > 0) { $utemplate .= 'x' . eval $$value[$i] }
          else 
          { 
            $utemplate .= 'a' . eval $$value[$i] - $pos;
          }
          $pos = eval $$value[$i];
          $next++;
        }
        else
        {
          if ($i > 0)
          {
            $pos = eval $$value[$i];
            $utemplate .= 'a*X*x' . $pos;
            $next++;
          }
        }
        $cur = eval $$value[$i];
        $max = $cur if $cur > $max;
      }
    }
  }
  if (@tvars) 
  { 
    $utemplate .= 'a*'; 
    push @vars,splice(@tvars,0); 
  }
  $parser .= 'unpack("' . $utemplate . '",sprintf("%-'.$max.'s",$source));'
     . "\n" . $tmp;
  for my $n (0..$#vars)
  {
    if (defined($vars[$n]) and $vars[$n] eq '.')
    {
      $parser .= '    splice @list,' . $n . ',1;' . "\n";
      splice @vars,$n,1;
      redo;
    }
  }
  $parser .= '    (' . join(',',@vars) . ') = @list;' . "\n";
  $parser .= "  };\n  croak \"String too short for pattern\" if \$@ =~ /x outside/;\n  croak \"\$@\" if \$@;\n  \@list;\n}\n";
  $parser .= "#MAX: $max\n";

  return $parser;
}







sub _anything (\@\$)
{
  my ($value,$type) = @_;
  my @vars = ();
  my @tvars = ();

  my $parser = "sub\n{\n  my \$source = shift;\n" .
    "  my \@list = (\$source);\n  my \@tlist = ();\n  my \$tmp = '';\n  my \$pos = 0;\n";
  for my $i (0..$#$value)
  {
    for (substr($$type,$i,1))
    {
      if (/^[Vv]$/)
      {
        push @tvars, $$value[$i];
      }
      else
      {
        if (/^[PL]$/)
        {
          my $regex;
          if (/L$/)
          {
            $regex = (substr($$type,$i+1) =~ /^[Vv]*[Rr]/) ? 
              q!'(?=! . $$value[$i] . q!)'!  :  
              q!'! . $$value[$i] . q!'!;
          }
          else
          {
            $regex = (substr($$type,$i+1) =~ /^[Vv]*[Rr]/) ? 
              q!'(?='.! . $$value[$i] . q!.')'!  :  $$value[$i];
          }
          $parser .= '  @tlist = split('.$regex.',pop @list,2);' . "\n";
          $parser .= '  push @tlist,("") x (2-@tlist);' . "\n";
          $parser .= '  push @list, splice(@tlist,0);' . "\n";
        }
        elsif (/^[Nn]$/)
        {
          $parser .= '  $pos = length($source) - length($list[-1]);' . "\n";
          $parser .= '  if ( '.$$value[$i].' > $pos )' . "\n";
          $parser .= '  {' . "\n";
          $parser .= '    $tmp = pop @list;' . "\n";
          $parser .= '    push @list, substr($tmp,0,max(0,'.$$value[$i].
            '-$pos)),substr($tmp,max(0,'.$$value[$i].'-$pos));' . "\n";
          $parser .= '  }' ."\n";
          $parser .= '  else' ."\n";
          $parser .= '  {' ."\n";
          $parser .= '    push @list, substr($source,'.$$value[$i].');' . "\n";
          $parser .= '  }' ."\n";
        }
        elsif (/^R$/)
        {
          if ( $$value[$i] > 0 )
          {
            $parser .= '  $tmp = pop @list;' . "\n";
            $parser .= '  push @list, substr($tmp,0,min(length($tmp),'.
              $$value[$i].')),substr($tmp,min(length($tmp),'.$$value[$i].
              '));' . "\n";
          }
          else
          {
            $parser .= '  $pos = length($source) - length($list[-1]);' . "\n";
            $parser .= '  push @list, substr($source,max(0,$pos + '.
              $$value[$i].'));' . "\n";
          }
        }
        elsif (/^r$/)
        {
          $parser .= '  if ( '.$$value[$i].' > 0 )' . "\n";
          $parser .= '  {' ."\n";
          $parser .= '    $tmp = pop @list;' . "\n";
          $parser .= '    push @list, substr($tmp,0,min(length($tmp),'.
            $$value[$i].')),substr($tmp,min(length($tmp),'.$$value[$i].
            '));' . "\n";
          $parser .= '  }' ."\n";
          $parser .= '  else' ."\n";
          $parser .= '  {' ."\n";
          $parser .= '    $pos = length($source) - length($list[-1]);' . "\n";
          $parser .= '    push @list, substr($source,max(0,$pos + '.
            $$value[$i].'));' . "\n";
          $parser .= '  }' ."\n";
        }

        if (@tvars > 1)
        {
          $parser .= '  @tlist = split(q( ),splice(@list,-2,1),'.
            scalar(@tvars).');' . "\n";
          $parser .= '  push @tlist, ("") x ('.scalar(@tvars).'-@tlist);' . "\n";
          $parser .= '  splice @list,-1,0, splice(@tlist,0);' . "\n";
        }
        elsif (@tvars == 0)
        {
          $parser .= '  splice @list,-2,1;' . "\n";
        }
        push @vars, splice(@tvars,0);
      }
    }
  }
  if (@tvars > 1) 
  {
    $parser .= '  @tlist = split(q( ),pop @list,'.scalar(@tvars).');' . "\n";
    $parser .= '  push @tlist, ("") x ('.scalar(@tvars).'-@tlist);' . "\n";
    $parser .= '  push @list, splice(@tlist,0);' . "\n";
  }
  push @vars,splice(@tvars,0);
  for my $n (0..$#vars)
  {
    
    if (defined($vars[$n]) and $vars[$n] eq '.' )
    {
      $parser .= '  splice @list,' . $n . ',1;' . "\n";
      splice @vars,$n,1;
      redo;
    }
  }
  $parser .= '  (' . join(',',@vars) . ') = @list;' . "\n";
  $parser .= "  \@list;\n}\n";

  return $parser;
}













sub _Vv (\@\$)
{
  my $value = shift;
  my $type = shift;

  my $parser = "sub\n{\n" ;
  $parser .= '  my @list = ' ."\n";
  $parser .= '  $_[0] =~  /^';
  for my $n (0..$#$value-1)
  {
    $parser .= $$value[$n] eq '.' ? '\s*\S*' : '\s*(\S*)';
  }
  if (@$value > 1)
  {
    $parser .= '\s*';
  }
  $parser .= $$value[-1] eq '.' ? '.*' : '(.*)';
  $parser .= '$/;' . "\n";
  $parser .= '  ('. join(',',grep { !/^\.$/ } @$value). ') = @list;' ."\n";
  $parser .= '  @list;' . "\n";
  $parser .= "}\n";
  return $parser;
}








sub _VvPL (\@\$)
{
  my ($value,$type) = @_;
  my @vars = ();
  my @tvars = ();
  my $tvars = "";
  my @patts = ();
  my $patts = "";
  my $re = "";

  my $parser = "sub\n{\n" ;
  for my $i (0..$#$value)
  {
    push @patts, $$value[$i] if substr($$type,$i,1) =~ /^[LP]$/;
  }
  for my $i (0..$#$value)
  {
    for (substr($$type,$i,1))
    {
      if (/^[Vv]$/)
      {
        push @tvars, $$value[$i];
        push @vars, $$value[$i] if /^[V]$/;
        $tvars .= substr($$type,$i,1);
      }
      else # (/^[PL]$/)
      {
        for my $nv (0..$#tvars-1)
        {
          $re .= '\s*';
          $re .= substr($tvars,$nv,1) eq 'v' 
            ? _Y($patts[0]).'*' : '('._Y($patts[0]).'*)'; 
        }
        $re .= '\s*' if @tvars > 1;
        $re .= substr($tvars,-1,1) eq 'v' 
          ? _K($patts[0]).'*' : '('._K($patts[0]).'*)';
        $re .= _X($patts[0]);
        shift @patts;
        @tvars = ();
        $tvars = "";
      }
    }
  }
  if (@tvars) 
  { 
    $patts = '$';
    for my $nv (0..$#tvars-1)
    {
      $re .= '\s*';
      $re .= (substr($tvars,$nv,1) eq 'v' ? '\S*' : '(\S*)' ) ; 
    }
    $re .= '\s*' if @tvars > 1;
    $re .= substr($tvars,-1,1) eq 'v' ? '.*' : '(.*)';
    @tvars = ();
    $tvars = "";
  }

  $parser .= '  my @list = ' ."\n";
  $parser .= '  $_[0] =~ /^' . $re;
  $parser .= "\$/;\n";
  $parser .= '  ('. join(',',@vars). ') = @list;' ."\n";
  $parser .= '  @list;' . "\n";
  $parser .= "}\n";

  return $parser;
}





sub _parser
{
  my $template = shift;
  my $callpkg = shift;
  my $parser = "";

  my ($type,@value) = _tokens($template,$callpkg);

  my @vars = ();
  my @tokens = ();
  my $regex = "";  

  for ($type)
  {

    # no variables to assign data
    /^[^V]+$/ and do
    {
      $parser = "sub {return};\n";
      last;
    };

    # only one variable to assign data
    /^[V]$/ and do
    {
      $parser = "sub\n{\n  " . $value[0] . 
        ' = $_[0];' . "\n};\n";
      last;
    };

    # only variables and placeholders
    /^[Vv]+$/ and do
    {
      $parser = _Vv(@value,$type);
      last;
    };
    
    # only variables and hard-coded numeric patterns
    /^[VvRN]+$/ and do
    {
      $parser = _VvRN(@value,$type);
      last;
    };

    # only variables and patterns (character or variable)
    /^[VvPL]+$/ and do
    {
      $parser = _VvPL(@value,$type);
      last;
    };

    # any valid template not caught by previous cases
    /^[VvNnRrPL]+$/ and do 
    { 
      $parser = _anything(@value,$type); 
      last; 
    };

    croak "This should never happen!\n($type)\n:" . join(":\n:",@value) . ":\n";

  }
  
  $parser = "# ($VERSION) Template: $template\n$parser";

  _debug("$parser\n") if $debug;

  my $parseref = eval $parser;
  if ($@) { die "$@" }
  return $parseref;
}


sub _debug
{
  my @list = @_;
  open(DEBUG,">>Parser.debug");
  for my $item (@list) 
  { 
    print DEBUG "$item";
  }
  close DEBUG;
}



sub new
{
  my $self = shift;
  my $template = shift;
  my $type = ref($self) || $self;
  my $obj = {};
  my $caller = 0;
  my $callpkg;

  $template =~ s/(?:^\s+|\s+$)//g;
  do { $callpkg = (caller($caller++))[0] } until $callpkg ne $type;

  $$obj{PARSER} = _parser($template,$callpkg);

  return bless $obj , $type;
}


{
  my %parser = ();


 sub parse ($$)
  {
    my $obj = shift;
    if (ref $obj )
    {
      return $obj->{PARSER}->(shift);
    }
    my $template = shift;
    $template =~ s/(?:^\s+|\s+$)//g;
    $parser{$template} ||= String::RexxParse->new($template);
    $parser{$template}->{PARSER}->($obj);
  }


  sub drop ($)
  {
    my $template = shift;
    if (exists $parser{$template})
    {
      $parser{$template} = "";
      delete($parser{$template});
    }
  }

}


sub _Y
{
  my $str = shift;
  return '@{[_Y('.$str.')]}' if $str =~ /^quotemeta\(.*\)$/;
  $str =~ s/\\(.)/$1/g;
  my ($first,$rest) = $str =~ /^(.)(.*)$/;
  $first = quotemeta($first) if $first =~ /\$|\\/;
  my $re;
  if ($rest)
  {
    $re = '(?:[^' . $first . '\s]|\S(?!' . quotemeta($rest) . '))';
  }
  else
  {
    $re = '[^' . $first . '\s]';
  }
  $re;
}

sub _K
{
  my $str = shift;
  return '@{[_K('.$str.')]}' if $str =~ /^quotemeta\(.*\)$/;
  $str =~ s/\\(.)/$1/g;
  my ($first,$rest) = $str =~ /^(.)(.*)$/;
  $first = quotemeta($first) if $first =~ /\$|\\/;
  my $re;
  if ($rest)
  {
    $re = '(?:[^' . $first . ']|.(?!' . quotemeta($rest) . '))';
  }
  else
  {
    $re = '[^' . $first . ']' ;
  }
  $re;
}

sub _X
{
  my $str = shift;
  return '@{[_X('.$str.')]}' if $str =~ /^quotemeta\(.*\)$/;
  $str =~ s/\\(.)/$1/g;
  my ($first,$rest) = $str =~ /^(.)(.*)$/;
  $first = quotemeta($first) if $first =~ /\$|\\/;
  my $re;
  $re = '(?:'. quotemeta($str) . ')?';
  $re;
}


1;


__END__


=head1 NAME

String::RexxParse - Perl implementation of REXX parse command

Download: 

http://www.danofsteel.com/Parser/String-RexxParse-1.10.tar.gz

ftp://www.danofsteel.com/pub/RexxParse/String-RexxParse-1.10.tar.gz


=head1 AUTHOR

Dan Campbell

=over 0

=item Copyright

Copyright (c) 1999, 2000 Dan Campbell. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=back

=head1 DESCRIPTION

Some long-time REXX programmers switching to Perl find it difficult 
to give up REXX's template-based parsing abilities.  This module is 
my attempt to provide such parsing in Perl.  
The documentation assumes a familiarity with REXX parse
statements.

=head1 CHANGES

=over 4

=item Version 1.10

=for html <br>

Put eval around processing of numeric patterns in order to set $@
in calling module when there is an error.

Added protection against errors for numeric patterns when string
to be parsed is shorter than the pattern calls for.

=for html <br><br>

=item Version 1.09

=for html <br>
 
General cleanup.  No functional changes.

=for html <br><br>

=item Version 1.08

=for html <br>

Fixed bug introduced in 1.07 and added j.t to test suite.

=for html <br><br>

=item Version 1.07

=for html <br>

Additional internal optimizations for the following templates special cases:

  Template only contains variables (or . )
  Template only contains variables (or . ) or patterns (literal or variable)

=for html <br><br>

=item Version 1.06

=for html <br>

Removed email address that only gets spam.

Added String::RexxParse->email which returns me email address.

Internal optimizations for the following templates special cases:

  Template is only a single lvalue
  Template only contains variables (or . )
  Template only contains variables (or . ) or patterns (literal or variable)

=for html <br><br>

=item Version 1.05

=for html <br>

Minor doc changes (README, mostly).

=for html <br><br>

=item Version 1.04

=for html <br>

Changed name String::Parser to String::RexxParse.

=for html <br><br>

=item Version 1.03

=for html <br>

Fixed incorrect handling of template when two or more
patterns are next to each other, or when last template
item is a pattern.

=for html <br><br>

=item Version 1.02

=for html <br>

Fixed incorrect handling of variable pattern in template when
variable's value contains regex meta characters.

=for html <br><br>

=item Version 1.01

=for html <br>

Fixed incorrect template parsing when a pattern is the first
template item.

=for html <br><br>

=item Version 1.00

=for html <br>

Consider this the starting point.  Any previous version should be replaced.

=back

=head1 SYNOPSIS

=over 4

=item use String::RexxParse qw(parse);

=item parse $source, q! $var1 $var2 '(' $var3 ')' $var4 ($var5) $var6 !;

=for html or<br>

=item use String::PexxParse;

=item $parse = String::RexxParse->new(q! $var1 $var2 '(' $var3 ')' $var4 ($var5) $var6 !);

=item $parse->parse($source);

=back

=head1 SYNTAX

=over 4

=item parse EXPR, EXPR

The first I<EXPR> is the source string to be parsed and must resolve to a scalar
value.

The second I<EXPR> is the template specification.  The first time
B<parse> is called with a particular template, the template is compiled,
then used to B<parse> the source expression.  Subsequent B<parse> calls with
the same template will use the previously compiled version of the template
rather than compile the template again.

The template is specified as a single expression, usually using 
some single-quotish type of quoting, like q!...! for instance.
The variable specifications, (or lvalue specifications) must 
not contain spaces.  If you want data assigned to B<$qq{$one}>, 
do not specify it as B<$qq{ $one }> but as B<$qq{$one}>.  Although 
both are valid in Perl, only the latter is valid in a B<String::RexxParse> 
template.  Likewise, 
B<substr( $b , pos( $source ) , length( $match ) )> is NOT 
valid, but B<substr($b,pos($source),length($match))> is.  Also, 
there must be white space following any lvalue specification 
(unless it's the last item in the template).
B<q/$b $c/> is OK, but B<q/$b$c/> is not.

If a variable's value is to be used as a pattern, it is enclosed 
in parentheses.  

Literal patterns are  enclosed in either single or double quotes.  
Patterns can contain spaces within the quotes or parentheses.

A period (.) is used as a placeholder to skip part of the source string.  

Numeric patterns (absolute or relative position) are supported.  
B<3>, B<=7>, B<+5>, B<-12>, B<=($n)>, B<+($x)>, B<-($somenumber)> 
are all numeric patterns (if you use variables
inside parentheses preceeded by =, +, or -, make sure they contain
numeric values).
Remember that Perl starts counting position at zero, so absolute 
numeric patterns should be one less than in REXX to identify the 
same character position.

All Perl variables used must either be in the package that called parse, 
or they must be explicitly referenced with their package name (i.e., if 
parse is called from package Pack, $a implies $Pack::a -- if you want $a 
in package Sack, you must specify $Sack::a ).  Lexical variables  can
not be used in the template.  To assign values to lexical variables
do somthing like this:

 my ($b, $c, $d, $e) = parse $a, q! $x . $x '(' $x ')' $x !;


If you're concerned about the compiled templates taking up memory after
you're done with them, you can add 'drop' to the import list
when you 'use String::RexxParse'.  Then pass the template to 'drop' when you're
done with it.  Or just call B<String::RexxParse::drop($template)>.  Or use the
object oriented flavor discussed below.


Consult your favorite REXX manual for more details on templates.

=for html <br><br><br>

=item $parse = String::RexxParse->new(EXPR);

=item $parse->parse(EXPR);

If you like, you can use String::RexxParse->new(EXPR) to create a 
B<String::RexxParse> object.
The EXPR passed to new is a template specification as described above.
When you want to parse an EXPR, you just pass the string to the 
B<String::RexxParse>
object like so: $parse->parse(EXPR);


=back

=head1 EXAMPLES


 REXX:
 parse var a b c '.' d '([' e '])' f qq.one

 Perl:
 parse $a, q! $b $c '.' $d '([' $e '])' $f $qq{one} !;
 # or
 $p = String::RexxParse->new(q! $b $c '.' $d '([' $e '])' $f $qq{one} !);
 $p->parse($a);

 ~~~~~~~~~~~~~~~

 REXX:
 parse var a b . '.' d '([' e '])' f qq.one

 Perl:
 parse $a, q!$b . '.' $d '([' $e '])' $f $qq{one}!;

 ~~~~~~~~~~~~~~~

 REXX:
 parse linein b c '.' d '([' e '])' f qq.one

 Perl:
 parse <>, q! $b $c '.' $d '([' $e '])' $f $qq{one} !;

 ~~~~~~~~~~~~~~~

 REXX:
 parse linein('filename') b c '.' d '([' e '])' f qq.one

 Perl:
 open FILE,"filename";
 parse <FILE>, q! $b $c '.' $d '([' $e '])' $f $qq{one}!;

 ~~~~~~~~~~~~~~~

 REXX:
 parse value(func(a)) with b c '.' d '([' e '])' f qq.one

 Perl:
 parse func($a), q! $b $c '.' $d '([' $e '])' $f $qq{one}!;

 ~~~~~~~~~~~~~~~

 REXX:
 variable = '.'
 parse a b c (variable) d 

 Perl:
 $variable = '.';
 parse $a, q/$b $c ($variable) $d/;

 ~~~~~~~~~~~~~~~

 REXX:
 variable = "abc"
 parse a b c (' 'variable' ') d 

 Perl:
 parse $a, q/$b $c (" $variable ") $d/;

 ~~~~~~~~~~~~~~~

 REXX:
 parse a b 12 c +8 d 

 Perl:
 parse $a, q! $b 11 $c +8 $d !;
 # position 12 in REXX is position 11 in Perl!


 ~~~~~~~~~~~~~~~
 
 REXX:
 parse var a b . d '([' e '])' f -13 g +(eight) qq.one

 Perl:
 @list = parse $a,  q!$b '.' $d '([' $e '])' $f -13 $g +($eight) $qq{one}!;
 # In addition to assiging values to the variables identified in the template,
 # @list will contain a list of corresponding values.

=head1 BUGS, QUESTIONS, COMMENTS

Please report any suspected bugs to Dan Campbell (String::RexxParse->email).  
Include the template and sample text that produces the incorrect results, 
along with a description of the problem.  Questions and comments are also 
welcome.

=cut

