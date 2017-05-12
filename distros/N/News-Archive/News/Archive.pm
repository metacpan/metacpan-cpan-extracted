$VERSION = "0.13";
package News::Archive;
our $VERSION = "0.13";

# -*- Perl -*- 		Tue May 25 14:37:47 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003-2004,
# Tim Skirvin.  Redistribution terms are below.
###############################################################################

=head1 NAME

News::Archive - archive news articles for later use

=head1 SYNOPSIS

  use News::Archive;
  my $archive = new News::Archive 
		( 'basedir' => '/home/tskirvin/kiboze' );
 
  # Get a news article
  my $article = News::Article->new(\*STDIN);
  my $msgid = article->header('message-id');

  die "Already processed '$msgid'\n" 
		if ($archive->article( $messageid ));

  # Get the list of groups we're supposed to be saving the article into
  my @groups = split('\s*,\s*', $article->header('newsgroups') );
  map { s/\s+//g } @groups;

  # Make sure we're subscribed to these groups
  foreach (@groups) { $archive->subscribe($_) }

  # Actually save the article.
  my $ret = $archive->save_article( 
        [ @{$article->rawheaders}, '', @{$article->body} ], @groups );
  $ret ? print "Accepted article $messageid\n"
       : print "Couldn't save article $messageid\n";

See below for more options.

=head1 DESCRIPTION

News::Archive is a package for storing news articles in an accessible
form.  Articles are stored one-per-file, and are accessible by either
message-ID or overview information.  The files are then accessible with a
Net::NNTP compatible interface, for easy access by other packages.

News::Archive keeps several files to keep track of its archives:

=over 4

=item active file

Keeps track of all newsgroups we are "subscribed" to and all of the
information that changes regularly - the number of articles we have
archived, the current first and last article numbers, etc.  

Watched over with News::Active.

=item history database

A simple database keeping track of articles by Message-ID.  Makes access
by ID easy, and ensures that we don't save the same article twice.  The
database chosen to maintain these is user-determined.

=item newsgroup file

Keeps track of more static information about the newsgroups we are
subscribed to - descriptions, creation dates, etc. 

Watched over with News::GroupInfo.

=item archive directory

Directory structure of all articles, with each article saved as a single
textfile within a directory structure laid out at one section of the group
name per directory, such as "rec/games/mecha".  Crossposts are hardlinked
to other directory structures.

Articles are actually divided into sub-directories containing up to 500
articles, to avoid Unix directory size performance limitations.
Individual files are thus stored in a file such as
"rec/games/mecha/1.500/1".

Each newsgroup also contains overview information, watched over with
News::Overview.  This overview file goes in the top of the structure, such
as "rec/games/mecha/.overview".

=back

You may note that these files are very similar to how INN does its work.
This is intentional - this package is meant to act in many ways like a
lighter-weight INN.

=head1 USAGE

=cut

###############################################################################
### Variables #################################################################
###############################################################################
use vars qw( $DEBUG $HOSTNAME $ERROR $HASH $READONLY );

=head2 Global Variables

The following variables are set within News::Archive, and are global
throughout all invocations.

=over 4

=item $News::Active::DEBUG

Default value for C<debug()> in new objects. 

=cut

$DEBUG      = 0;	  

=item $News::Active::HOSTNAME

Default value for C<hostname()> in new objects.  Obtained using
C<Sys::Hostname::hostname()>.

=cut

$HOSTNAME   = hostname();

=item $News::Active::HASH

The number of articles to keep in each directory.  Default is 500; change
this at your own peril, since things may get screwed up later if you
change it after archiving any articles!

=cut

$HASH       = 500;	  # How many articles should we hash directories off at?

## Internal only - default error string.  We're not currently using this
## well, and may never be, so let's not talk about it in the docs much.

$ERROR 	    = "";	  

## Should we open things read-only by default?

$READONLY = 0;

=back

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use warnings;
use News::Article;
use News::Overview;
use News::Active;
use News::GroupInfo;
use Net::NNTP::Functions;
use Sys::Hostname;
use Fcntl;

###############################################################################
### Basic Functions ###########################################################
###############################################################################

=head2 Basic Functions 

These functions create and deal with the object itself.

=over 4

=item new ( HASHREF ) 

Creates the News::Archive object.  C<HASHREF> contains initialization
information for this object; currently supported options:

  basedir	Base directory for this object to work with.  
		Required; we will fail without this.
  archives	Location of the post archives.  Defaults to 
		$basedir/archives
  historyfile	Location of the history database.  Defaults to
		$basedir/historyfile
  activefile	Location of the active file.  Defaults to
		$basedir/active
  overfilename  File name for the overview database files in each
		newsgroup hierarchy.  Defaults to ".overview".
  db_type	The type of perl database we will use to store 
		files that need that level of service.  Defaults
		to 'DB_File' 
  groupinfofile Location of the groupinfo file.  Defaults to
		$basedir/newsgroups.
  hostname	String to use when a local hostname is required.  
		Defaults to $News::Archive::HOSTNAME.
  debug		Should we print debugging information?  Defaults to
		$News::Archive::DEBUG.
  readonly	Should we open this read-only?  

Returns the blessed object on success, or undef on failure.

=cut

sub new          { 
  my ($proto, %hash) = @_;
  unless ( $hash{'basedir'} ) { 
    _set_error("No 'basedir' value offered (is your config file set up?)");
    return undef; 
  }
  my $basedir  = $hash{'basedir'} or return undef;
  my $class = ref($proto) || $proto;
  my $self = {
	'group'	         => undef,
	'pointer'        => 0,
	'readonly'	 => $hash{'readonly'}    || $READONLY || 0,
	'archives'       => $hash{'archives'}    || "$basedir/archives",
	'historyfile'    => $hash{'historyfile'} || "$basedir/history",
	'activefile'     => $hash{'activefile'}  || "$basedir/active",
	'overfilename'   => $hash{'overfile'}  || ".overview",
	'db_type'        => $hash{'db_type'}   || "DB_File",
	'groupinfofile'  => $hash{'groupinfofile'} || "$basedir/newsgroups",
	'hostname'       => $hash{'hostname'}  || $HOSTNAME || 'localhost',
	'debug'          => defined $hash{'debug'} ? $hash{'debug'} : $DEBUG,
	     };
  bless $self, $class;
  $$self{'history'}   = $self->history    || return undef;
  $$self{'active'}    = $self->activefile || return undef;
  $$self{'groupinfo'} = $self->groupinfo  || return undef;
  $self;
}

=item activefile ()

Returns the News::Active object based on C<activefile>, set in new().  If
this object has not already been opened and created, creates it;
otherwise, just returns the existing object.  Passes on the 'readonly'
flag.

=cut

sub activefile { 
  my ($self) = @_;
  $$self{'active'} ||= new News::Active($$self{activefile}, 
					'readonly' => $$self{readonly});
  $$self{'active'};
}

=item activeclose ()

Writes out and closes the News::GroupInfo object.

=cut

sub activeclose {
  my ($self) = @_;
  return 1 unless $$self{'active'};
  $self->activefile->write; 
  delete $$self{'active'};
  1;
}

=item groupinfo ()

Returns the News::GroupInfo object based on C<groupinfofile>, set in
new().  If this object has not already been opened and created, creates
it; otherwise, just returns the existing object.  Passes on the 'readonly'
flag.

=cut

sub groupinfo {
  my ($self) = @_;
  $$self{'groupinfo'} ||= new News::GroupInfo($$self{groupinfofile},
					'readonly' => $$self{readonly});
  $$self{'groupinfo'};
}

=item groupclose ()

Writes out and closes the News::GroupInfo object.

=cut

sub groupclose {
  my ($self) = @_;
  return 1 unless $$self{'groupinfo'};
  $self->groupinfo->write;
  $$self{'groupinfo'} = undef;
  1;
}

=item history ()

Returns a tied hashref based on C<historyfile>, set in new().  If this
object has not already been opened and created, creates it; otherwise,
just returns the existing object.

=cut

sub history {
  my ($self) = @_;
  $$self{'history'} ||= $self->_tie($$self{historyfile}, $$self{db_type});
  $$self{'history'};
}

=item debug ()

Returns true if we want to print debugging information, false otherwise.
Used a lot internally, may also be used externally.

=cut

sub debug { shift->{debug} }

=item activeentry ( GROUP )

Returns the News::Active::Entry information for the given C<GROUP>.

=cut

sub activeentry { shift->activefile->entry(shift) }

=item groupentry ( GROUP )

Returns the News::GroupInfo::Entry information for the given C<GROUP>.

=cut

sub groupentry  { shift->groupinfo->entry(shift) }

=item close ()

Close all open files.

=cut

sub close { 
  my $self = shift;
  $self->groupclose;
  $self->activeclose;
  untie %{$self->{history}};
}

=back

=cut

###############################################################################
### Internal Functions - Basic ################################################
###############################################################################

## _tie ( FILE [, CLASS] )
# Ties a database file to a hash.  CLASS defaults to the normal internal 
# database type.  Currently only works with DB_File and SDBM_File
sub _tie {
  my ($self, $file, $class, @args) = @_;
  return "" unless $file;
  $class ||= $self->{db_type};
  my %tie;
  if ($class eq 'DB_File' || $class eq 'SDBM_File') { 
    require "$class.pm";
    my $opentype = $$self{readonly} ? O_RDONLY : O_CREAT|O_RDWR;
    tie %tie, $class, $file, $opentype, 0755
	  or ( warn "Couldn't tie $file: $!\n" & return ()); 
  } else { %tie = () }
  \%tie;
}

## _isnumeric ( STRING )
# Returns 1 if STRING is purely numeric (no negative numbers!), 0 otherwise.
sub _isnumeric { shift =~ m/^[\d\.]+$/ ? 1 : 0 }

## _mkdir_full ( DIR )
# Make a full directory structure.  Not exactly what I want, but it'll do 
# for now.
sub _mkdir_full {
  my ($self, $dir) = @_;
  return 1 if -d $dir;
  warn "Making directory $dir\n" if $self->debug;
  system("mkdir -p $dir");
} 

## DESTROY ()
# Item destructor.  Untie the active and history information.
sub DESTROY {
  my $self = shift;
  $self->close;
}

###############################################################################
### Error Functions ###########################################################
###############################################################################

=head2 Error Functions 

These functions deal with the global error variable, which is currently
not being used very effectively.

=over 4

=item error ( [ERROR] )

Returns the text (a scalar) describing the last error message.  If
C<ERROR> is offered, then it sets the error message to this first.  

=cut

sub error       { $ERROR = $_[1] if defined $_[1]; $ERROR }

=item clear_error ()

Clears the error message.

=cut

sub clear_error { $ERROR = "" }

=back

=cut

###############################################################################
### Internal Functions - Error ################################################
###############################################################################

## _set_error ( ERROR )
# Set the $ERROR variable internally.
sub _set_error  { $ERROR = shift; $ERROR }

###############################################################################
### NNTP Functions ############################################################
###############################################################################

=head2 Net::NNTP Equivalents

The following functions are the equivalent of the Net::NNTP commands; they
are provided for compatibility with News::Web and other news functions.
More information on their use is available in those manual pages.

=over 4

=item article ( [ MSGID|MSGNUM ], [FH] )

Retrives the article indicated by C<MSGID> or C<MSGNUM> (B<Net::NNTP>) as
the headers, a blank line, and then the body of the article.  Either
prints it to C<FH> (if offered) or returns an array reference containing
the text.  

Returns undef if the article is not found.

=cut

sub article   { 
  my ($self, $id, $fh) = @_;
  my $article = $self->_article($id || 0);
  return undef unless $article;
  $fh ? print $fh join("\n", $article->rawheaders(), "", @{$article->body}, "")
      : [ $article->rawheaders(), '', $article->body(), '' ];
}

=item head ( [ MSGID|MSGNUM ], [FH] )

As with C<article()>, but only returns the header of the article.

=cut

sub head { 
  my ($self, $id, $fh) = @_;
  my $article = $self->_article($id || 0);
  return undef unless $article;
  $fh ? print $fh join("\n", $article->rawheaders())
      : [ $article->rawheaders() ];
}

=item body ( [ MSGID|MSGNUM ], [FH] )

As with C<article()>, but only returns the body of the article.

=cut

sub body{ 
  my ($self, $id, $fh) = @_;
  my $article = $self->_article($id || 0);
  return undef unless $article;
  $fh ? print $fh join("\n", @{$article->body})
      : [ $article->body() ];
}

=item nntpstat ( [ MSGID|MSGNUM ] )

As with C<article()>, but only returns the article's message-id.  Returns
undef if not set or the article didn't exist.

=cut

sub nntpstat { 
  my ($self, $id) = @_;
  my $article = $self->_article($id || 0);
  return undef unless $article;
  $article->header('message-id') || undef; 
}

=item group ( [GROUP] )

Sets the current group pointer; necessary if we want to use C<article()>
or its ilk by message number and not message-ID.  In array context,
returns the active information of the group as a list (number of articles,
first article number, last article number, group name).  In scalar
context, just returns the group name.

=cut

sub group {
  my ($self, $group) = @_;
  defined $group ? $$self{'group'} = $group
    	         : $group = $$self{'group'};
  return ( wantarray ? [] : "" ) unless $$self{'group'};
  return "" unless $$self{'group'};
  wantarray ? @{$self->_groupinfo($group)} : $group;
}

=item ihave ( MSGID, MESSAGE )

Writes an article to the archive with Message-ID C<MSGID>.  C<MESSAGE> is
the actual message.  Invokes C<save_article()>.

(Note that this is preferred to C<post()>, at least here, because it lets
us tell much earlier if we don't want the article.)

=cut

sub ihave {
  my ($self, $msgid, @message) = @_;
  return 0 if $self->history->{$msgid};	# We already have it
  $self->save_article(\@message);
}

=item last ()

Unimplemented.

=cut

sub last { _unsupported() }

=item date ()

Returns the local time (in seconds since the epoch).

=cut

sub date { time }

=item postok ()

Returns 0; we don't want anything to get the idea that it can post.

=cut

sub postok { 0 }	

=item authinfo ()

Unimplemented.

=cut

sub authinfo { _unsupported() } 

=item list ()

Same as C<active('*')>, listing all active groups. 

=cut

sub list { shift->active("*") }

=item newgroups ()

Unimplemented.

=cut

sub newgroups { _unsupported() } 

=item newnews ()

Unimplemented.

=cut

sub newnews { _unsupported() } 

=item newnews ()

Unimplemented.

=cut

sub next { _unsupported() } 

=item post ( MESSAGE )

Writes an article to the archive.  C<MESSAGE> is the actual message.
Invokes C<save_article()>.

=cut

sub post {
  my ($self, @message) = @_;
  $self->save_article(\@message);
}

=item slave ()

Unimplemented.

=cut

sub slave         { _unsupported() }

=item quit ()

Close the current connection; clear the current group, and reset the
pointer.  Returns 1.

=cut

sub quit         { 
  my ($self) = @_;
  $self->{group}   = undef;
  $self->{pointer} = 0;
  1;
}

=item newsgroups ( [PATTERN] )

Returns a hashref where the keys are the newsgroups that match the pattern
C<PATTERN> (uses C<active()>), and the values are descriptiion text for
the newsgroup.

=cut

sub newsgroups {
  my ($self, $pattern) = @_;
  my $hash = $self->active($pattern);
  foreach (keys %{$hash}) { 
    my $group = $self->groupinfo->entry($_);
    $$hash{$_} = $group ? $group->desc : $_ ;
  }
  $hash;
}

=item distributions 

Not implemented.

=cut

sub distributions { _unsupported() }

=item subscriptions ()

Returns a listref to all groups that we are subscribed to.  This is not
ideal; we may only want the ones that we have descriptions for, or a
specific flag set in News::GroupInfo, or something.  It works for now,
though.

=cut

sub subscriptions { # [ keys %{active(@_)} ] }	
  my ($self, $pattern) = @_;
  $pattern ||= '*';
  my %return;
  foreach my $item ($self->groupinfo->entries($pattern)) {
    next unless wildmat($pattern, $item->name);	# Is this necessary?
    $return{$item->name} = $item->arrayref;
  }
  [ keys %return ];
  # \%return; 
}

=item overview_fmt ()

Returns the overview format information from News::Overview, since that's
what we're currently using.

=cut

sub overview_fmt { News::Overview::overview_fmt }

=item active_times ( [PATTERN] )

Returns a hashref where the keys are the group names, and the values are
the results from C<News::GroupInfo::Entry->arrayref()>.  

=cut

sub active_times { 
  my ($self, $pattern) = @_;
  my %return;
  foreach my $item ($self->groupinfo->entries($pattern)) {
    $return{$item->name} = $item->arrayref;
  }
  \%return;
}

=item active ( [PATTERN] )

Returns a hashref where the keys are the group names, and the values are
the results from C<News::Active::Entry->arrayref()>.  

=cut

sub active { 
  my ($self, $pattern) = @_;
  $pattern ||= '*';
  my %return;
  foreach my $item ($self->activefile->entries($pattern)) {
    next unless wildmat($pattern, $item->name);	# Is this necessary?
    $return{$item->name} = $item->arrayref;
  }
  \%return; 
}

=item xgtitle ( [PATTERN] )

Same as C<newsgroups()>

=cut

sub xgtitle { newsgroups(@_) }

=item xhdr ( HEADER, SPEC [, PATTERN] )

=cut

sub xhdr {
  my ($self, $hdr, $spec, $pattern) = @_; 
  $pattern ||= '*';
  my $xover = $self->xover($spec, $hdr);
  my %return;
  foreach (keys %{$xover}) { 
    my $string = join(' ', @{$$xover{$_}}); 
    next unless wildmat($pattern, $string);
    $return{$_} = $string;
  }
  \%return;
}

=item xover ( MATCH, HDR )

Gets information from the stored overview database.  See B<News::Overview>
for more information on how this works.

=cut

sub xover { 
  my ($self, $match, $hdr) = @_;
  my $group = $self->group; return [] unless $group;
  $self->overview_read($group, $match, $hdr);
}

=item xpath ( MID )

Returns the full path name on the server of the location of the given
article.

=cut

sub xpath {
  my ($self, $mid) = @_;
  my $history = $self->history->{$mid};  return undef unless $history;
  my ($group, $number) = split('/', $history);
  my $dir  = $self->_dirname($group);
  my $file = $self->_filename($number);
  "$dir/$file";
}

=item xpat ( HEADER, SPEC [, PATTERN] )

Same as C<xhdr()>.

=cut

sub xpat { xhdr(@_) }

=item xrover ( SPEC )

Same as $self->xhdr('References', SPEC)

=cut

sub xrover {
  my ($self, $spec) = @_;
  $self->xhdr('References', $spec);
}

=item listgroup

Unimplemented.

=cut

sub listgroup { _unsupported() }

=item reader ()

Unimplemented.

=cut

sub reader    { _unsupported() }

=back

=cut

###############################################################################
### Internal Functions - NNTP #################################################
###############################################################################

## _group () 
# Returns the current value of 'group' that we're working with.
sub _group { shift->{'group'} }

## _article ( ID )
# Loads the article indicated with ID.  Returns a News::Article object
# if successful.
sub _article {
  my ($self, $id) = @_; 
  
  # If the given ID is numeric or not given, then try to find and 
  # load the appropriate message-ID.  If that doesn't work, then it 
  # was a bad number.
  return undef unless $id;

  my ($group, $number);
  if ( _isnumeric($id) ) {         # Just a number -> we need the group
    return undef if ($id eq 0);
    $group = $self->_group() || return undef;
    $number = $id;
  } else { 			   # Get the group from the ID
    my $history = $self->history->{$id};  return undef unless $history;
    ($group, $number) = split('/', $history);
  }

  my $dir  = $self->_dirname($group);
  my $file = $self->_filename($number);

  print "Looking for article $id at $dir/$file\n" if $self->debug;
  
  my $article = new News::Article;  $article->read("$dir/$file");
  $article || undef;
}

## _groupinfo ( GROUP )
# Pulls out activefile information on the given group - # of articles, 
# # of first article, # of last article, group name.  Returns an arrayref
# with this information.
sub _groupinfo {
  my ($self, $group, @args) = @_;
  my $active = $self->activefile->entry($group);
  return [] unless ($active && ref $active);
  [ $active->count, $active->first, $active->final, $active->name ];
}


## _unsupported ()
# Used for unsupported NNTP functions.  Not particularly interesting, but 
# it might be better later.
sub _unsupported { undef }

###############################################################################
### Archive Functions #########################################################
###############################################################################

=head2 Archive Functions

The following functions actually deal with the archive itself.

=over 4

=item save_article ( LINES [, GROUPS] ) 

Saves an article into the archive.  C<LINEREF> is an arrayref that is
passed to News::Article; C<GROUPS> is an array of groups that we want to
save the article to, if not those listed in the Newsgroups: header.

The article is modified by adding C<hostname()> onto the Path: header and 
creating a new Xref: header to match where we will save the article.  The
file is primarily linked to a single location, and hardlinks are made to
the other locations.  Overview information is generated for each group,
history information is saved to ensure that we don't save the same article
twice, and directories are created as needed.  

Note that there are currently some race conditions possible with this
function, which should be partially solved be adding file and directory
locking.  

=cut

sub save_article {
  my ($self, $lines, @groups) = @_;
  my $article = new News::Article(\@$lines); 

  my $messageid = $article->header('message-id');
     $messageid =~ s/\s+//g;

  unless ( scalar @groups ) { 
    @groups = split('\s*,\s*', $article->header('newsgroups'))
  }
  
  # Create a new Path header to reflect the new server
  my $newpath = join('!', $self->{'hostname'} || 'localhost', 
			$article->header('Path'));
  $article->set_headers('Path', $newpath);

  my ($maingroup, %files);
  foreach my $group (@groups) { 
    next unless $self->subscribed($group);
    my $actentry = $self->activeentry($group);
    next unless $actentry;
    $files{$group} = $actentry->next_number;
    $maingroup = $group unless $maingroup;
  }

  # Make a new Xref header
  my $newxref = $self->{'hostname'} || 'localhost';
  foreach (@groups) { 
    next unless $files{$_};
    $newxref = join(' ', $newxref, "$_:$files{$_}" );
  }
  $article->set_headers('Xref', $newxref);

  # Create the files
  my $file;
  foreach my $group (@groups) { 
    next unless $files{$group};
    my $active = $self->activefile->entry($group);
    next unless $active;
    my $dir = $self->_dirname($group);
    my $filename = $self->_filename($files{$group});

    # Making the directory if it's necessary
    my $path = $filename;  $path =~ s%^(.*)/[^/]+$%$1%;
    unless (-d "$dir/$path") { $self->_mkdir_full( "$dir/$path" ); }

    if ($file) { 
      my $link = "$dir/$filename";
      print "Linking $link to $file\n" if $self->debug;
      link ( $file, $link ) && $active->add_article();
    } else { 
      $file = "$dir/$filename";
      print "Writing $messageid to $file\n" if $self->debug;
      open(FILE, ">$file") or return undef;
      $article->write(\*FILE);
      CORE::close FILE;
      $active->add_article;
    }

    # Populate the overview files
    $self->overview_add($files{$group}, $group, $article);
  }

  # Populate the history file
  my $history = "$maingroup/$files{$maingroup}";
  print "$messageid is saved as '$history'\n" if $self->debug;
  $self->history->{$messageid} = $history;

  1;
}

=item subscribe ( GROUP )

Subscribe to the given C<GROUP>, by adding information about the group to
the active and groupinfo files and starting the directory tree.  

=cut

sub subscribe {
  my ($self, $group) = @_;
  return 1 if $self->subscribed($group);
  $self->activefile->subscribe($group);
  $self->groupinfo->subscribe($group, time, 'generic', 'No Description');
  $self->_mkdir_full( $self->_dirname($group) );
  1;
}

=item unsubscribe ( GROUP )

Unsubscribe from C<GROUP>, by removing information about it from the
active and groupinfo files.

=cut

sub unsubscribe { 
  my $self = shift;
  $self->activefile->unsubscribe(@_)
	&&  
  $self->groupinfo->unsubscribe(@_);
}

=item subscribed ( GROUP )

Returns 1 if we are subscribed to C<GROUP>, 0 otherwise.

=cut

sub subscribed  { shift->activefile->subscribed(shift) ? 1 : 0 }

=item overview_add ( NUMBER, GROUP, ARTICLE )

Add information to C<GROUP>'s overview information regarding article
C<NUMBER>, which is C<ARTICLE>.  Just appends the information to the
overview database; we don't need to do anything more at this point.

=cut

sub overview_add { 
  my ($self, $number, $group, $article) = @_; 

  # Get the proper overfiew info - this is too convoluted
  my $over = new News::Overview;
  my $artinfo = $over->add_from_article($number, $article);
  
  # Write out the information
  my $dir = $self->_dirname($group); next unless -d $dir;
  my $filename = join('/', $dir, $$self{overfilename});
  open(OVER, ">>$filename") or next;
  print OVER $over->print, "\n";
  CORE::close OVER;

  1;
}

=item overview_read ( GROUP, MESSAGE-SPEC [, HDR ] )

Get the overview information from C<GROUP> for the articles specified by
C<MESSAGE-SPEC> (see B<Net::NNTP>).  If C<HDR> is offered, only return
that header information.  Mostly invokes C<xover()>. 

=cut

sub overview_read {
  my ($self, $group, $match, $hdr) = @_;
  return {} unless $group;

  my ($first, $last) = messagespec($match);
  
  my $dir = $self->_dirname($group);
  my $filename = join('/', $dir, $$self{overfilename});
  my $over = new News::Overview;
  open(OVER, $filename) or (warn "Couldn't open $filename: $!\n" && return {} );
  foreach (<OVER>) { 
    next if $_ < $first;  next if ($last > $first and $_ > $last);
    $over->add_xover($_) 
  }
  CORE::close OVER;

  $hdr ?  $over->xover($match, $hdr) : $over->xover($match);
}

=back

=cut

###############################################################################
### Internal Functions - Archive ##############################################
###############################################################################

## _dirname( GROUPNAME )
# Makes the base directory name out of the group name and the 'archives'
# value (which is where the files are stored).  '.'s are replaced with '/'.
sub _dirname  { join('/', shift->{archives}, split('\.', shift)) }

## _filename( NUMBER )
# Returns the filename of the individual message based on the number of
# the message.  This is a longer directory name based on $HASH - we only
# want so many messages per directory.  This could be more complicated,
# and probably will have to be some day, but it works for now.
sub _filename { 	
  my ($self, $number) = @_;
  my $floor   = int ( ( $number - 1 ) / $HASH ) * $HASH + 1;
  my $ceiling = $floor + $HASH - 1;
  sprintf("%d.%d/%d", $floor, $ceiling, $number);
}

1;

=head1 NOTES

This module has grown out of my original kiboze.pl scripts, which
accomplished essentially the same writing functions but none of the
reading ones.  While a write-only interface has been somewhat beneficial,
this should be much more helpful.

=head1 TODO

Start using the AutoLoader (or something like it)

File locking across the board, along with read-only opens.

Close and re-open the databases periodically, to write stuff out while in
the middle of an operation.

While we currently have basic hashing taking place on the newsgroups to
prevent the directories from getting too large, it would be nice if this
were instead done as a time-hash - that is, if the article was from 28 Apr
2004, we could make directories that looked like 2004.01.01 (yearly
hashing), 2004.04.01 (monthly), or 2004.04.28 (daily).  

More News::Web changes to better connect with News::Archive would be nice.

Using a different Overview format may make sense.

Offer some functions to rebuild overview information later.

Offer something to make default ~/.kibozerc files.

=cut

=head1 REQUIREMENTS

C<Net::NNTP::Functions>, B<News::Article>, B<News::Overview>,
B<News::Active>, B<News::GroupInfo>, B<DB_File>

=head1 SEE ALSO

Modules: B<News::Active>, B<News::GroupInfo>, B<News::Article>,
B<News::Web>, B<newslib>, B<newsrecurse.pl>

Scripts: B<kiboze.pl>, B<newsarchive.pl>, B<mbox2news.pl>

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
# v0.10		Wed Apr 28 16:59:53 CDT 2004 
### First documented version.
# v0.11		Thu Apr 29 10:15:51 CDT 2004 
### Using '1.500' instead of '1-500', to make sure there's no collisions
### with actual groupnames.  groupclose() and activeclose().
# v0.12		Tue May 25 11:03:36 CDT 2004 
### Trying to add a 'read-only' aspect to this.
# v0.13		Tue May 25 14:37:13 CDT 2004 
### Some changes in how it writes stuff out.  DESTROY isn't the default
### now, close() is.  Also, added 'use warnings'.
