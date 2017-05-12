$VERSION = "0.10";
package News::Active::Entry;
our $VERSION = "0.10";

# -*- Perl -*- 		# Wed Apr 28 08:59:14 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003-2004,
# Tim Skirvin.  Redistribution terms are below.
###############################################################################

=head1 NAME

News::Active::Entry - an object for storing specific active file information

=head1 SYNOPSIS

  use News::Active::Entry;
  use News::Active;

  my $item = new News::Active::Entry("humanities.philosophy.objectivism");
  $item->add_article(1);	
  my $string = $item->output;

See below for more specific information about related functions.

=head1 DESCRIPTION

News::Active::Entry contains the actual active file entries for
News::Active.  Each entry consists of a group name, flags, and information
about the article numbers in the group.  Within that, it is a very simple
module (significantly more lines dedicated to documentation than actual
code).

=head1 USAGE

News::Active::Entry is accessed through the following functions:

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;

=head2 Functions

=over 4

=item new ( STRING )

Creates and returns a new News::Active::Entry object.  C<STRING> is a
scalar containing the group name, first article, final article, group
flags, and article count for the given group, separated by '::'.  

Only the group name is really required; the rest will be worked on on
their own.  Therefore, just passing in the group name will work fine.

=cut

sub new {
  my ($proto, $string) = @_;
  my ($group, $first, $final, $flags, $count) = split('::', $string);
  return undef unless $group;
  my $class = ref($proto) || $proto;
  my $self = {
	'count' => $count || 0,
	'first'	=> $first || 0,
	'final'	=> $final || 0,
	'flags' => $flags || 'y',
	'name'  => $group || '',
 	     };
  bless $self, $class;
}

=item first ( [NUMBER] )

=item final ( [NUMBER] )

=item count ( [NUMBER] )

=item name ( [STRING] )

=item flags ( [STRING] )

Returns the relevant information from the object, as indicated above.  If
an argument is passed to these functions, then the value is set to that
value; otherwise, we just return the existing value.

=cut

sub first { defined $_[1] ? $_[0]->{first} = $_[1] : $_[0]->{first} || 0  }
sub final { defined $_[1] ? $_[0]->{final} = $_[1] : $_[0]->{final} || 0  }
sub count { defined $_[1] ? $_[0]->{count} = $_[1] : $_[0]->{count} || 0  }
sub name  { defined $_[1] ? $_[0]->{name}  = $_[1] : $_[0]->{name}  || "" }
sub flags { defined $_[1] ? $_[0]->{flags} = $_[1] : $_[0]->{flags} || "" }

=item arrayref ()

Returns an array reference containing C<final()>, C<first()>, and
C<flags()> (the same information stored by INN's active file).

=cut

sub arrayref {
  my ($self) = @_;
  [ $self->final, $self->first, $self->flags ];
}

=item print ()

Makes a human-readable string containing the information from name(),
first(), final(), flags(), and count().  

=cut

sub print { 
  my ($self) = @_;
  sprintf("%-41s %010d %010d %5s %010d", 
  	$self->name, $self->first, $self->final, $self->flags, $self->count);
}

=item add_article ( [COUNT] )

Indicates that we've added a single article to the given newsgroup, by
incrementing both final() and count() by C<COUNT> (defaults to 1).
first() is set to one if it was not set.  Returns the number of articles
we added.

=cut

sub add_article {
  my ($self, $count) = @_; $count ||= 1;
  $$self{final} += $count;  $$self{count} += $count;
  $$self{first} ||= 1;	
  $count;
}

=item next_number ()

Returns the next article number that we will be saving to. 

=cut

sub next_number { shift->{final} + 1 }

=item output ()

Returns the string that is needed by new() - ie, a string containing
name(), first(), final(), flags(), and count() separated by '::'.  

=cut

sub output { join("::", $_[0]->name, $_[0]->first, $_[0]->final, 
				     $_[0]->flags, $_[0]->count ); }

=back

=cut

1;

=head1 REQUIREMENTS

B<News::Active>

=head1 SEE ALSO

B<News::Active>

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 HOMEPAGE

B<http://www.killfile.org/~tskirvin/software/news-archive/>

B<http://www.killfile.org/~tskirvin/software/newslib/>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2003-2004, Tim Skirvin.

=cut

###############################################################################
##### Version History #########################################################
###############################################################################
# v0.10		Wed Apr 28 09:03:05 CDT 2004 
### First documented version; it's been working since last year, though.
