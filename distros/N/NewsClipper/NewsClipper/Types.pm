# -*- mode: Perl; -*-
package NewsClipper::Types;

# This package declares a set of built-in data types for News Clipper. It also
# defines a function MakeSubtype which can be used to create the right subtype
# relationship between existing data types and new ones.

use strict;
# For exporting of functions
use Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );

@ISA = qw( Exporter );
@EXPORT = qw( MakeSubtype Link URL Image Table Thread TypesMatch );
@EXPORT_OK = qw( ValidateTypeSignature GetTypeSignature ConvertTypeToEnglish
                 NormalizeSignature);

$VERSION = 0.12;

use NewsClipper::Globals;

# ------------------------------------------------------------------------------

# Used a lot in this package
*isa = \&UNIVERSAL::isa;

# ------------------------------------------------------------------------------

# This routine can be used to make a type a subtype of another

sub MakeSubtype($$)
{
  my $subType = shift @_;
  my $baseType = shift @_;

  die "You have to specify both a base type and a subtype for MakeSubtype.\n"
    unless defined $subType && defined $baseType;

  eval "package $subType; use vars qw(\@ISA); \@ISA = \"$baseType\";"
    unless $baseType =~ /^(SCALAR|HASH|ARRAY)$/;
}

# ------------------------------------------------------------------------------

NewsClipper::Types::MakeSubtype('Link','SCALAR');
NewsClipper::Types::MakeSubtype('Image','SCALAR');
NewsClipper::Types::MakeSubtype('URL','SCALAR');

package Table;

package Thread;

# ------------------------------------------------------------------------------

package NewsClipper::Types;

# Checks a type signature for well-formed-ness

sub ValidateTypeSignature($)
{
  my $typeSignature = shift;

  my $errors = '';

  # Ignore spaces
  $typeSignature =~ s/ //g;

  # Check matching parens
  # Thanks Abigail!
  # (Re: Match Parens - More Perlish? 2/2/99 comp.lang.perl.misc)
  {
    my $balanced = 1;
    my $i;
    foreach ($i = 0; $typeSignature =~ /([()])/g;)
    {
      $balanced = 0 if (($i += $1 eq '(' ? 1 : -1) < 0);
    }
    $balanced = 0 if $i;

    $errors .= "Parentheses don't match.\n" unless $balanced;
  }

  # Check description immediately follows $, @, or %
  $errors .= "Description \"$2\" can only follow a \$, \@, or \%.\n"
    if $typeSignature =~ /(^|.)([^\@\%\$\&\|\(\)]+)/ &&
      $1 ne '@' && $1 ne '$' && $1 ne '%';

  # Check @, %, or $ doesn't follow the same
  $errors .=<<"  EOF"
"$2$3" can not follow "$1". You should probably put "$2$3" in parentheses.
  EOF
    if $typeSignature =~ /([\@\%\$])([\@\%\$])([^\@\%\$\|\(\)]*)/;

  return $errors;
}

# ------------------------------------------------------------------------------

# Makes implicit structure types explicit, and replaces () with <1< >1> to
# make matching parens apparent.

sub NormalizeSignature($)
{
  my $typeSignature = shift;

  # Make matching parens
  {
    my $i = 0;
    while ($typeSignature =~ /\(([^()]*)\)/)
    {
      $i++;
      $typeSignature = $` . "<$i<" . $1 . ">$i>" . $';
    }
  }

  # Make implicit structure names explicit
  while ($typeSignature =~ /([\@\%\$])([^a-z]|$)/i)
  {
    my $tempString;
    $tempString = "ARRAY" if $1 eq '@';
    $tempString = "HASH" if $1 eq '%';
    $tempString = "SCALAR" if $1 eq '$';
    $typeSignature = $` .  $1 . $tempString . $2 . $';
  }

  # Remove spaces
  $typeSignature =~ s/ *([\@\$\%])/$1/g;
  $typeSignature =~ s/ *\| */|/g;

  return $typeSignature;
}

# ------------------------------------------------------------------------------

# Undoes the work of NormalizeSignature, almost. (Spaces are lost.)

sub UnNormalizeSignature($)
{
  my $typeSignature = shift;

  # Remove matching parens
  $typeSignature =~ s/<\d+</\(/g;
  $typeSignature =~ s/>\d+>/\)/g;

  # Make explicit structure names implicit
  $typeSignature =~ s/\@ARRAY/\@/g;
  $typeSignature =~ s/\%HASH/\%/g;
  $typeSignature =~ s/\$SCALAR/\$/g;

  return $typeSignature;
}

# ------------------------------------------------------------------------------

# Given a reference to data, returns the type signature for it. The optional
# second argument tells the subroutine whether it should recurse deeper into
# the structure. Returns the empty string if the type signature can not be
# determined.

sub GetTypeSignature ($;$);
sub GetTypeSignature ($;$)
{
  my $data = shift;
  my $recurse = shift || 1;

  my $signature = '';

  if (isa($data,'ARRAY'))
  {
    $signature .= '@';
    $signature .= ref $data unless ref $data eq 'ARRAY';

    if ($recurse)
    {
      my @containedTypes;
      foreach my $item (@$data)
      {
        push @containedTypes, GetTypeSignature($item) if ref $item;
      }

      # Compress the types to the unique ones.
      my %seen;
      foreach my $type (@containedTypes)
      {
        $seen{$type} = 1;
      }
      @containedTypes = keys %seen;

      local $" = '&';
      $signature .= "(@containedTypes)" if $#containedTypes != -1;
    }
  }

  if (isa($data,'HASH'))
  {
    $signature .= '%';
    $signature .= ref $data unless ref $data eq 'HASH';

    if ($recurse)
    {
      my @containedTypes;
      foreach my $item (keys %$data)
      {
        push @containedTypes, GetTypeSignature($data->{$item})
          if ref $data->{$item};
      }

      # Compress the types to the unique ones.
      my %seen;
      foreach my $type (@containedTypes)
      {
        $seen{$type} = 1;
      }
      @containedTypes = keys %seen;

      local $" = '&';
      $signature .= "(@containedTypes)" if $#containedTypes != -1;
    }
  }

  if (isa($data,'SCALAR'))
  {
    $signature .= '$';
    $signature .= ref $data unless ref $data eq 'SCALAR';
  }

  return $signature;
}

# ------------------------------------------------------------------------------

# Converts a type signature to human-readable format. (Well, sort of.)

sub ConvertTypeToEnglish($)
{
  my $typeSignature = shift;

  return '<UNKNOWN>' unless defined $typeSignature;

  # Change "@ARRAY" to "ARRAY", "$SCALAR" to "SCALAR", and
  # "%HASH" to "HASH"
  $typeSignature =~ s/\@ARRAY/'ARRAY'/g;
  $typeSignature =~ s/\%HASH/'HASH'/g;
  $typeSignature =~ s/\$SCALAR/'SCALAR'/g;

  # Change "@thread" to "thread array", "$URL" to "URL scalar", and
  # "%Slashdot" to "Slashdot hash"
  $typeSignature =~ s/\@(\w+)/'$1 array'/g;
  $typeSignature =~ s/\$(\w+)/'$1 scalar'/g;
  $typeSignature =~ s/\%(\w+)/'$1 hash'/g;

  # Change "@" to "array", "$" to "scalar", and "%" to "hash"
  $typeSignature =~ s/\@/array/g;
  $typeSignature =~ s/\$/scalar/g;
  $typeSignature =~ s/\%/hash/g;

  # Change "(" to " of ("
  $typeSignature =~ s/\(/ of \(/g;

  # Remove parens when they aren't needed
  $typeSignature =~ s/\(([^\)\|\&]+)\)/$1/g;

  # Change "|" to "or", and "&" to "and"
  $typeSignature =~ s/ *\| */ or /g;
  $typeSignature =~ s/ *& */ and /g;

  return $typeSignature;
}

# ------------------------------------------------------------------------------

# Determines if a given data item matches the given type signature. You have
# to normalize the type signature before calling this.

sub TypesMatch
{
  my $data = shift;
  my $typeSignature = shift;

  $typeSignature = NormalizeSignature($typeSignature);

#print "Entering TypesMatch to compare the data structure ",
#GetTypeSignature($data)," against $typeSignature\n";

  # First check for ors
  {
#print "Checking ors...\n";
    my $simplifiedSignature = $typeSignature;

    while ($simplifiedSignature =~ /<(\d+)</)
    {
      $simplifiedSignature =~ s/<$1<.*>$1>//;
    }

    # Skip all this if there are no ors...
    if ($simplifiedSignature =~ /\|/)
    {
      my @orStructures = split /\|/, $simplifiedSignature;

      my $tempSignature = $typeSignature;

      foreach my $orStructure (@orStructures)
      {
#print "Extracting $orStructure from signature $tempSignature\n";
        my $orSignature;
        $orStructure =~ s/([\$\%\@])/\\$1/g;
        if ($tempSignature =~ /^$orStructure<(\d+)</)
        {
          my $level = $1;
          ($orSignature) = $tempSignature =~ /^($orStructure<$level<.*>$level>)/;
          $tempSignature =~ s/^$orStructure<$level<.*>$level>\|//;
        }
        else
        {
          ($orSignature) = $tempSignature =~ /^($orStructure)/;
          $tempSignature =~ s/^$orStructure\|//;
        }
#print "Extraction done. New signature: $tempSignature\n";

#print "Checking data type ", GetTypeSignature($data), " against $orSignature ",
#"\n";
        if (TypesMatch($data,$orSignature))
        {
#print "Types ", GetTypeSignature($data)," and $typeSignature match!\n";
          return 1;
        }
      }

#print "Types don't match\n";
      return 0;
    }
  }

  # Then check for ands
  {
#print "Checking ands...\n";
    my $simplifiedSignature = $typeSignature;

    while ($simplifiedSignature =~ /<(\d+)</)
    {
      $simplifiedSignature =~ s/<$1<.*>$1>//;
    }

    if ($simplifiedSignature =~ /\&/)
    {
      my @andStructures = split /\&/, $simplifiedSignature;

      my $tempSignature = $typeSignature;

      foreach my $andStructure (@andStructures)
      {
#print "looking for $andStructure in $tempSignature\n";
        my $andSignature;
        $andStructure =~ s/([\$\%\@])/\\$1/g;
        if ($tempSignature =~ /^$andStructure<(\d+)</)
        {
          my $level = $1;
          ($andSignature) =
            $tempSignature =~ /^($andStructure<$level<.*>$level>)/;
          $tempSignature =~ s/^$andStructure<$level<.*>$level>\&//;
        }
        else
        {
          ($andSignature) = $tempSignature =~ /^($andStructure)/;
          $tempSignature =~ s/^$andStructure\&//;
        }

        unless (TypesMatch($data,$andSignature))
        {
#print "Types don't match\n";
          return 0;
        }
      }

#print "Types ", GetTypeSignature($data)," and $typeSignature match!\n";
      return 1;
    }
  }
 
  # Finally deal with type signatures with no ors or ands
  {
    # First check that the top-level type matches
    {
      my ($topLevelType) = $typeSignature =~ /^.([\w\s]+)/;
#print "Checking toplevel types ",
#GetTypeSignature($data)," and $topLevelType\n";
      unless (isa($data, $topLevelType))
      {
#print "Types don't match\n";
        return 0;
      }
    }

#print "Toplevel types match. Checking internal structure...\n";

    # Now check that the internal structure matches
    if ($typeSignature =~ /<(\d+)</)
    {
      # Do each array element if it's an array
      if (isa($data,'ARRAY'))
      {
        my ($internalTypeSignature) = $typeSignature =~ /<$1<(.*)>$1>/;
  
        foreach my $internalData (@$data)
        {
          unless (TypesMatch($internalData,$internalTypeSignature))
          {
#print "Types don't match\n";
            return 0;
          }
        }

#print "Types ", GetTypeSignature($data)," and $typeSignature match!\n";
        return 1;
      }

      # Do each hash value if it's a hash
      if (isa($data,'HASH'))
      {
        my ($internalTypeSignature) = $typeSignature =~ /<$1<(.*)>$1>/;
  
        foreach my $internalData (keys %$data)
        {
          unless (TypesMatch($data->{$internalData},$internalTypeSignature))
          {
#print "Types don't match\n";
            return 0;
          }
        }

#print "Types ", GetTypeSignature($data)," and $typeSignature match!\n";
        return 1;
      }
    }

    # If the structure at this level matches, and all the internal structure
    # matches, we win!
#print "Types ", GetTypeSignature($data)," and $typeSignature match!\n";
    return 1;
  }
}

1;
