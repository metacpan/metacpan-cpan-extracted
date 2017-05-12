#
# WuManber.pm
#
# Copyright (c) 2007-2011, Juergen Weigert, openSUSE.org
# This module is free software. It may be used, redistributed
# and/or modified under the same terms as Perl (version 5.8.8) itself.
#
# This used to have a first() / next() iterator interface, which turned out to be 
# incompatible with the chaotic state machine of wu manber mgrep implementation.
# Deprecated if favour of a simpler but more memory hungry find_all().

package Search::WuManber;

use strict;
use warnings;

require Exporter;
require DynaLoader;

use base qw(Exporter DynaLoader);
our @EXPORT_OK = qw();          # exportable
our $VERSION = '0.25';

bootstrap Search::WuManber $VERSION;

sub new
{
  my ($self, $list, $opts) = @_;
  my $class = ref($self) || $self;
  die "new: patterns parameter not an ARRAY-ref\n" unless ref $list eq 'ARRAY';
  my $this = { patterns => $list };

  my %opt = 
    (
      return_string => 0,
      case_sensitive => 1,
    );

  for my $o (keys %opt)
    {
      $this->{$o} = ($opts && defined($opts->{$o})) ? $opts->{$o} : $opt{$o};
      delete $opts->{$o} if $opts;
    }

  die "new: unknown options: ". join(',', keys %$opts) . "\n try these: " . join(',', keys %opt) . "\n" if keys %$opts;

  my $time = time();
  init_tables($this) or die "internal error: init_tables failed.\n";
  $this->{init_time_sec} = time() - $time;

  return bless $this, $class;
}

sub first
{
  my ($self, $text) = @_;
  delete $self->{result};
  return $self->next($text);
}

# This is a method, not a bare subroutine.
sub next             ## no critic (ProhibitBuiltinHomonyms)
{
  my ($self,$text) = @_;
  $self->{result} = $self->all($text) unless $self->{result};

#  my $o = shift @{$self->{result}};
#  my $i = shift @{$self->{result}};
#  return [$o, $i];
  return shift @{$self->{result}};
}

sub all
{
  my ($self, $text) = @_;
  my $m = find_all($self, $text);
  if ($m && $self->{return_string})
    {
      for my $p (@$m)
        { 
	  push @$p, $self->{patterns}[$p->[1]];
	}
    }
  return $m;
}

1;
__END__

=head1 NAME

Search::WuManber -- A fast algorithm for multi-pattern searching

=head1 SYNOPSIS

  use Search::WuManber;

  my $search = Search::WuManber->new([qw(tribute reserved serve distribute)]);
  my @matches = $search->all(  lc "All rights reserved. Distribute freely.");
  my $match =   $search->first(lc "All rights reserved. Distribute freely.");
  $match = $search->next();

=head1 DESCRIPTION

This module implements the Wu-Manber multi-pattern parallel search algorithm.

The list of search patterns passed to C<new()> are prepared for parallel lookup.
A perl reference pointing to all internal data is returned. Treat this reference
as opaque. C<first()> and C<next()> iterate over all text positions where matches occur.
Pattern matches in this context are substring matches.
Each match is returned as a reference to a two-element array representing text
offset and list index of the matching pattern. Options for C<new()>:
 * C<< return_string => 1 >> make the return value of the iterator a 
three-element array, containing also the search string itself.
 * C<< case_sensitive => 0 >> run the search in case insensitive mode (slightly slower).

The matches are returned roughly sorted by offset. Offset usually increments, but may
jump backwards by the length difference of neighbouring search strings. 

C<New()> allocates a constant amount of memory (between ca. 130k and 2MB).
This memory can be returned by C<undef $search;>



=head1 BUGS

The iterator is inefficient. C<first()> just calls C<all()> ..., 

This implementation uses internal hash-functions, which may not be optimal. 

Efficiency of WuManber depends on the minimum length of search strings.
Suggested minimum length is 5. C<new()> switches to a slower algorithm if one of 
the strings has less than 3 characters.

Changes in the list of search patterns are not seen by the search algorithm after
C<new()> was called. Changes in the text are undefined. Call C<first()> to restart with 
a new text.

=head1 REFERENCES

Sun Wu and Udi Manber (1994) A fast algorithm for multi-pattern searching.
Technical Report TR-94-17, University of Arizona.
http://webglimpse.net/pubs/TR94-17.pdf

ftp://ftp.cs.arizona.edu/agrep/agrep-2.04.tar.Z

www.snort.org

Rolf Stiebe, Textalgorithmen, WS 2005/6


=head1 SEE ALSO

C<Text::Scan>, C<Algorithm::AhoCorasick>, C<Algorithm::RabinKarp>

=head1 AUTHOR

Juergen Weigert <jw@cs.fau.de>

=head1 COPYRIGHT AND LEGALESE

Copyright (c) 2007-2011, Juergen Weigert, openSUSE.org
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

