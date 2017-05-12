#! /usr/bin/perl -w
#
# (c) 2007, jw
# Distributable under the well known terms of GPLv2.

use ExtUtils::testlib;
use Search::WuManber;
use Data::Dumper;
$Data::Dumper::Indent = 0;

my $text = qq( 
		Linux kernel management style

		This is a short document describing the preferred (or made up, depending
		on who you ask) management style for the linux kernel.  It's meant to
		mirror the CodingStyle document to some degree, and mainly written to
		avoid answering (*) the same (or similar) questions over and over again. 

		Management style is very personal and much harder to quantify than
		simple coding style rules, so this document may or may not have anything
		to do with reality.  It started as a lark, but that doesn't mean that it
		might not actually be true. You'll have to decide for yourself.

		Btw, when talking about "kernel manager", it's all about the technical
		lead persons, not the people who do traditional management inside
		companies.  If you sign purchase orders or you have any clue about the
		budget of your group, you're almost certainly not a kernel manager. 
		These suggestions may or may not apply to you. 
);

# if (open IN, "<", "/usr/src/linux/Documentation/ManagementStyle")
#   {
#     $text = join '', <IN>;
#     close IN;
#   }

my $tln = Text::LineNumber->new($text);

my @list = qw(Management DISTRIBUTIVE Algorithm equation Persons emEnt somebody suddenly dangerous preemptive decision person style);

# @list = qw(1032104 2010321041 2032104 032104 22412430);
# $text = qq(100221201032104213044210);

my $search = Search::WuManber->new(\@list, { case_sensitive => 0 });
$search->{return_string}++;

warn Dumper $search->all($text);
# delete $search->{wm}; warn Dumper $search;

while (defined (my $match = $search->next($text)))
  {
    push @$match, $list[$match->[1]], $tln->off2lnr($match->[0]);
    print Dumper $match;
    print "\n";
  }


## this demo.pl contains a builtin copy of Text::LineNumber module.
## so that it is independant.
package Text::LineNumber;

sub new
{
  my ($self, $text) = @_;
  my $class = ref($self) || $self;
  my $lnr_off = [ 0 ];
  while ($text =~ m{(\r\n|\n|\r)}gs)
    {
      # pos() returns the offset of the next character 
      # after the match -- exactly what we need here.
      push @$lnr_off, pos $text;
    }
  return bless $lnr_off, $self; 
}

## the first byte has offset 0
sub lnr2off
{
  my ($self, $lnr) = @_;
  my $l = 0;
  return 0 if $lnr < 0;
  return $self->[$lnr] || $self->[-1];
}


## the first line has lnr 1,
## the first byte in a line has column 1.
sub off2lnr
{
  my ($self, $offset) = @_;
  my $l = 0;
  my $h = $#$self;
  while ($h - $l > 1)
    {
      my $n = ($l + $h) >> 1;
      if ($self->[$n] <= $offset)
        {
	  $l = $n;
          $h = $n if $self->[$l] == $offset;
	}
      else
        {
	  $h = $n;
	}
    }
  
  return $h unless wantarray;
  return ($h, $offset - $self->[$l] + 1);
}

# end package Text::LineNumber
