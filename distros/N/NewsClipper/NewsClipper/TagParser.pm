# -*- mode: Perl; -*-

# This is a small parser for the newsclipper tags. The main parser is below.

package NewsClipper::TagParser;

use strict;
use HTML::Parser;

use vars qw( @ISA $VERSION );
@ISA = qw(HTML::Parser);

use NewsClipper::Globals;

# ------------------------------------------------------------------------------

# Stores News Clipper commands as they are parsed
my @_commandList;

# ------------------------------------------------------------------------------

sub parse
{
  my $self = shift;
  my $text = shift;

  undef @_commandList;

  $self->SUPER::parse($text);

  return @_commandList;
}

# ------------------------------------------------------------------------------

sub start
{
  my $self = shift @_;
  my $originalText = pop @_;

  my ($tag, $attributeList) = @_;

  # Make sure all the attributes are lower case
  foreach my $attribute (keys %$attributeList)
  {
    if (lc($attribute) ne $attribute)
    {
      $attributeList->{lc($attribute)} = $attributeList->{$attribute};
      delete $attributeList->{$attribute};
    }
  }

  $errors{'tagparser'} .= 
   "A News Clipper command must have a \"name\" attribute.\n" and return
      unless defined $attributeList->{name};

  if ($tag =~ /(input|filter|output)/)
  {
    push @_commandList,[$tag,$attributeList];
  }
  else
  {
    $errors{'tagparser'} .= 
      "Invalid News Clipper command \"$tag\" seen in input file.\n";
  }
}

1;
