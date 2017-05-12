$VERSION = "0.13";
package News::Active;
our $VERSION = "0.13";

# -*- Perl -*-          Tue May 25 14:35:18 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003-2004,
# Tim Skirvin.  Redistribution terms are below.
###############################################################################

=head1 NAME

News::Active - keep track of news active file information 

=head1 SYNOPSIS

  use News::Active;
  my $active = News::Active->new( '/home/tskirvin/kiboze/active' );
  $active->subscribe("humanities.philosophy.objectivism");
  $active->add_article("humanities.philosophy.objectivism");
  $active->write;

See below for more information.

=head1 DESCRIPTION

News::Active is used to keep track of active newsgroup information in an
external file.  It contains many C<News::Active::Entry> objects, one for
each newsgroup we are subscribed to.  It should be a fairly simple module
to use and understand, as it is only a subsection of C<News::Archive>.

=head1 USAGE

=head2 Variables

=over 4

=item $News::Active::DEBUG - default value for C<debug()> in new objects.

=item $News::Active::READONLY - default value for C<readonly()> in new objects.

=back

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use warnings;
use News::Active::Entry;
use Net::NNTP::Functions;
use vars qw( $DEBUG $READONLY );

$DEBUG    = 0;
$READONLY = 0;

=head2 Basic Functions 

The following functions give us access to the object class

=over 4

=item new ( FILE [, HASH] )

Creates and returns a new News::Active object.  C<FILE> is the filename
(later accessed with C<filename()>) that we will load old information from
and save to when we close the object.  It will be created if it doesn't
already exist, and read (with C<read()>) from if it does.

If C<HASH> is offered, its possible values:

  debug			Print debugging information when using this 
			object.  Defaults to $DEBUG.
  readonly		Don't write anything back out with this object
			when we're done with it.  Defaults to $READONLY.

Returns undef on failure, or the object on success.

=cut

sub new {
  my ($proto, $file, %hash) = @_;
  return undef unless $file;
  my $class = ref($proto) || $proto;
  my $self = {
	Groups   => 	{ },
  	FileName =>     $file,
        Debug    =>     $hash{'debug'}    || $DEBUG    || 0,
        ReadOnly =>     $hash{'readonly'} || $READONLY || 0,
        Changed  =>     0,
  	     };
  bless $self, $class;
  $self->read($file);
  $self;
}

=item groups ()

Returns a hash reference containing all subscribed newsgroups; the keys
are the group names, and the values are B<News::Active::Entry> objects.  

=item filename ()

Returns the filename used for loading and saving our News::Active
information.  

=item debug ()

Returns true if we want to print debugging information, false otherwise.  

=item readonly ()

Returns true if we shouldn't write out the information later, false
otherwise.  

=cut

sub groups   { shift->{Groups}   || {} }
sub filename { shift->{FileName} || undef }
sub debug    { shift->{Debug}    || 0 }
sub readonly { shift->{ReadOnly} || 0 }

=item entry ( GROUP )

Returns the News::Active::Entry object for C<GROUP>, or undef if none exists.

=cut

sub entry    { 
  my ($self, $group) = @_;
  $self->groups->{$group} || undef 
}

=item entries ( PATTERN )

Returns an array of News::Active::Entry objects whose newsgroup names
match the given pattern C<PATTERN> (using C<Net::NNTP::Function::wildmat()>.

=cut

sub entries { 
  my ($self, $pattern) = @_;
  my @return;
  foreach (sort keys %{$self->groups}) { 
    next unless wildmat($pattern || "*", $_);
    push @return, $self->entry($_);
  }
  @return;
}

=back

=head2 Newsgroup Functions

The following functions implement the functions that we actually want to
use this module for, ie adding groups and articles to the active file.

=over 4

=item subscribe ( GROUP )

Adds a News::Active::Entry entry for the given C<GROUP>, thus adding it to
our subscription list.  Returns 1 on success, undef otherwise.

=cut

sub subscribe { 
  my ($self, $group) = @_;
  return undef unless $group;
  return 1 if $self->subscribed($group); 
  print "Subscribing to $group\n" if $self->debug;
  $self->{Changed}++;
  $self->groups->{$group} = new News::Active::Entry($group);
  # warn "G2: $group ", $self->groups->{$group}, "\n";
  # foreach (keys %{$self->groups}) { warn "G3: $_\n"; }
  1;
}

=item unsubscribe ( GROUP )

Unsubscribe from C<GROUP> by making sure there is no News::Active::Entry
entry for that groupname.  Returns 1 on success or if we were already
unsubscribed, undef otherwise.

=cut

sub unsubscribe { 
  my ($self, $group) = @_;
  return undef unless $group;
  return 1 unless $self->groups->{$group};
  print "Unsubscribing from $group\n" if $self->debug;
  delete $self->groups->{$group};
  $self->{Changed}++;
  1;
}

=item subscribed ( GROUP )

Returns 1 if we are subscribed to C<GROUP>, 0 otherwise.

=cut

sub subscribed { 
  my ($self, $group) = @_;
  return 0 unless $group;
  $self->groups->{$group} ? 1 : 0; 
}

=item add_article ( GROUP [, ARGS] )

Invokes C<News::Active::add_article()> on the entry for C<GROUP>.  

=cut

sub add_article {
  my ($self, $group, @args) = @_;
  my $entry = $self->entry($group) || return undef;
  $self->{Changed}++;
  $entry->add_article(@args);
}

=back

=head2 Input/Output Functions 

The following functions are used for reading, displaying, and saving
information from News::Active and News::Active::Entry.

=over 4

=item read ( [FILE] )

Reads News::Active::Entry information from C<FILE> (or the value of
C<file()>), populating the News::Active object.  This file contains lines
that each contain the output from a single C<News::Active::Entry::output()>
call.  Returns 1 on success, undef otherwise.

=cut

sub read {
  my ($self, $file) = @_;
  $file ||= $self->filename;  
  return undef unless $file;
  $$self{Groups} = {};
  print "Reading from $file\n" if $self->debug;
  open(FILE, $file) or (warn "Couldn't read from $file: $!\n" && return undef);
  foreach (<FILE>) { 
    chomp;
    my $entry = new News::Active::Entry($_) or next;
    $self->groups->{$entry->name} = $entry;
  }  
  close FILE;  
  $self->{Changed}++;
  1;
}

=item printable ()

Returns an array (or arrayref, depending on invocation) containing the
value of C<News::Active::Entry::print()> on each entry within the
News::Active object.  These are then suitable for printing.

=cut

sub printable { 
  my ($self) = @_;
  my @return;
  foreach (sort keys %{$self->groups}) { 
    push @return, $self->entry($_)->print; 
  }
  wantarray ? @return : join("\n", @return); 
}

=item output ()

Returns an array (or arrayref, depending on invocation) containing the
value of C<News::Active::Entry::output()> on each entry within the
News::Active object.  These are then suitable for saving to a database and
later reloading.

=cut

sub output {
  my ($self) = @_;
  my @return;
  foreach (sort keys %{$self->groups}) { 
    push @return, $self->entry($_)->output; 
  }
  wantarray ? @return : join("\n", @return); 
}

=item write ( [FILE] )

Using the information from output(), writes out to C<FILE> (or the value
of C<file()>).  Returns 1 on success, undef otherwise.  If the readonly 
flag is set, we don't actually write anything back out.

Note that this function is called when the object is destroyed as well.

=cut

sub write {
  my ($self, $file) = @_;
  if ( !$self->{Changed} ) { 
    warn "Nothing changed, not writing\n" if $self->debug;  
    return 1;
  } 
  if ( $self->readonly ) { 
    warn "Not writing output, readonly!\n" if $self->debug; 
    return 1; 
  }
  $file ||= $self->filename;  
  return undef unless $file;
  print "Writing to $file\n" if $self->debug;
  open(FILE, ">$file") 
	or (warn "Couldn't write to $file: $!\n" && return undef);
  print FILE join("\n", $self->output);
  close FILE;
  $self->{Changed} = 0;
  1;
}

=back

=cut

###############################################################################
### Internal Functions ########################################################
###############################################################################

### DESTROY
# Item destructor.  Make sure the file is written back out.
# sub DESTROY { shift->write }

1;

=head1 NOTES

This and C<News::Active> are fairly similar, but are meant to take care of
different types of information.  The News::Active file is meant to be
modified regularly, every time a new article is added; in INN terms this
is the equivalent of the active file.  The information in News::GroupInfo
is meant to only be modified occasionally, when something major changes; 
in INN terms this is the equivalent of the newsgroups and active.times
files.

=head1 TODO

File locking would be nice.

=head1 REQUIREMENTS

C<Net::NNTP::Functions>

=head1 SEE ALSO

B<News::Archive>, B<News::GroupInfo>

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
### Version History ###########################################################
###############################################################################
# v0.10         Wed Apr 28 10:12:40 CDT 2004 
### First documented version; it's been working since last year, though.
# v0.11		Wed Apr 28 11:06:26 CDT 2004 
### Added the matching stuff from Net::NNTP::Functions.
# v0.12		Tue May 25 11:21:03 CDT 2004 
### Added read-only stuff.
# v0.13		Tue May 25 14:34:25 CDT 2004 
### Doesn't automatically write on close anymore.
