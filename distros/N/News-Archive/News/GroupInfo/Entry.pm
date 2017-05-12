$VERSION = "0.10";
package News::GroupInfo::Entry;
our $VERSION = "0.10";

# -*- Perl -*- 		# Wed Apr 28 09:38:34 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003-2004,
# Tim Skirvin.  Redistribution terms are below.
###############################################################################

=head1 NAME

News::GroupInfo::Entry - an object for storing specific group information

=head1 SYNOPSIS

  use News::GroupInfo::Entry;

See News::GroupInfo and below for more specific information about related
functions.

=head1 DESCRIPTION

News::GroupInfo::Entry contains the actual newsgroup entries for
News::GroupInfo.  Each entry consists of a group name, timestamp of
creation, creator name, and group description.  Within that, it is a very
simple module (significantly more lines dedicated to documentation than
actual code).

=head1 USAGE

News::GroupInfo::Entry is accessed through the following functions:

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;

=head2 Functions

=over 4

=item new ( STRING )

Creates and returns a new News::GroupInfo::Entry object.  C<STRING> is a
scalar containing the group name, timestamp of creation, creator name, and
group description, separated by '::'.  

Only the group name is really required; the rest will be worked on on
their own.  Therefore, just passing in the group name will work fine.

=cut

sub new {
  my ($proto, $string) = @_;
  my ($group, $time, $creator, $desc) = split('::', $string);
  return undef unless $group;
  my $class = ref($proto) || $proto;
  my $self = {
	'name'    => $group    || '',
	'desc'	  => $desc     || '',
	'creator' => $creator  || '',
	'time'	  => $time     || 0,
 	     };
  bless $self, $class;
}

=item name ( [STRING] )

=item desc ( [STRING] )

=item creator ( [STRING] )

=item time ( [STRING] )

Returns the relevant information from the object, as indicated above.  If
an argument is passed to these functions, then the value is set to that
value; otherwise, we just return the existing value.

=cut

sub name    { defined $_[1] ? $_[0]->{name}   = $_[1] : $_[0]->{name}   || "" }
sub desc    { defined $_[1] ? $_[0]->{desc}   = $_[1] : $_[0]->{desc}   || "" }
sub creator { defined $_[1] ? $_[0]->{creator} = $_[1] : $_[0]->{creator} || ""}
sub time    { defined $_[1] ? $_[0]->{'time'} = $_[1] : $_[0]->{'time'} || 0  }

=item arrayref ()

Returns an array reference containing C<time()>, C<creator()>, and
C<desc()> (the same information stored by INN's various newsgroup files).

=cut

sub arrayref { my ($self) = @_; [ $self->time, $self->creator, $self->desc ]; }

=item print ()

Makes a human-readable string containing the information from arrayref().

=cut

sub print    { join("\t", @{shift->arrayref}) }

=item output ()

Returns the string that is needed by new() - ie, a string containing
name() and arrayref(), separated by '::'.  

=cut

sub output   { my $self = shift; join("::", $self->name, @{$self->arrayref}) }

=back

=cut

1;

=head1 REQUIREMENTS

B<News::GroupInfo>

=head1 SEE ALSO

B<News::GroupInfo>

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 HOMEPAGE

B<http://www.killfile.org/~tskirvin/software/news-archive/>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2003-2004, Tim Skirvin.

=cut

###############################################################################
##### Version History #########################################################
###############################################################################
# v0.10         Wed Apr 28 09:44:47 CDT 2004 
### First documented version; it's been working since last year, though.
