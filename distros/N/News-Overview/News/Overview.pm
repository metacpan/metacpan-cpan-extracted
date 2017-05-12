$VERSION = "0.12";
package News::Overview;
our $VERSION = "0.12";

# -*- Perl -*-          # Fri Oct 10 11:29:51 CDT 2003 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003, Tim
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

News::Overview - an object to store condensed information about Usenet posts 

=head1 SYNOPSIS

  use News::Overview;
  use Net::NNTP;
  
  my $overview = News::Overview->new();
  my $nntp = new Net::NNTP;

  $nntp->group("killfile.test");
  $overview->add_from_nntp($nntp->xover);

  foreach my $entry ( $overview->sort ('thread', $overview->entries) ) {
    print $overview->print_entry($entry), "\n";
  }

=head1 DESCRIPTION

News::Overview objects store combined information about many messages, as
generally done in INN's overview format and semi-codified in the XOVER
extentions to RFC1036.   Each object is meant to store a single
newsgroup's worth of basic header information - by default the message
number, subject, poster, date of posting, message identifier, references
to the article's parents, size of the body, number of lines in the body,
and information on where this message is stored within the server.
This information is then used to offer summartes of messages in the group, 
sort the messages, and so forth.

The main unit of storage within News::Overview is the object
News::Overview::Entry; each one of these contains information on a single
article.  News::Overview itself is dedicated to creating, storing, and
manipulating these Entries.

=head1 USAGE 

All of this object's usage is contained within its functions.

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use News::Article;
use News::Overview::Entry;
use Net::NNTP::Functions;

use vars qw( @DEFAULT );
@DEFAULT = qw( Subject: From: Date: Message-ID: References: 
		   	Bytes: Lines: Xref:full );

=head2 Basic Functions 

=over 4

=item new ( [ DEFAULT_ARRAY_REF ] ) 

Creates a new News::Overview object.  

If C<DEFAULT_ARRAY_REF> is offered, we will use this to define which
fields are stored in all the associated Entries; otherwise, we default to
the fields in C<@News::Overview::DEFAULT>.  The 'Number:' field is added
as well, to store the "article number" that each entry is associated with.

Returns the new blessed object, or undef if unsuccessful.

=cut

sub new {
  my ($proto, $default) = @_;
     $default ||= "";
  my $class = ref($proto) || $proto;
  my $self = {
 	Defaults => 	[ ref $default ? @{$default} : @DEFAULT ],
#       Count    =>     0,		# Number of articles currently in here
        Articles =>     {},		# Actual article information
        Article_By_ID =>  {},		# Actual article information
  	     };
  unshift @{$$self{Defaults}}, "Number:";
  $$self{'Fields'} = [ _fields($$self{'Defaults'}) ];
  bless $self, $class;
  $self;
}

=item default ()

In array context, returns the full list of default information associated
with each Entry.  In scalar context, returns the same as an arrayref.

=item defaults ( )

Same as default(), except this information is instead based on
@News::Overview::DEFAULT (ie doesn't include Number:).  

=item fields () 

In array context, returns the list of fields stored in each associated
Entry.  In scalar context, returns this as an arrayref.

This differs from default() only in as much as everything after the ':' is
trimmed; these are meant to be used as 

=cut

sub default { wantarray ? @{shift->{'Defaults'}} : shift->{'Defaults'} ; }
sub defaults { _fields(@DEFAULT) }
sub fields  { wantarray ? @{shift->{'Fields'}}   : shift->{'Fields'}   ; }

# =item value ( KEY [, VALUE ])
# 
# Returns the ...hey, wait a second, we're not doing anything with this!
# 
# =cut
# 
# sub value {
#   my ($self, $key, $value) = @_; 
#   return undef unless $key;
#   $self->values->{$key} = $value if defined $value;
#   $self->values->{$key};
# }
# 
# =item values ( ) 
# 
# =cut
# 
# sub values  { shift->{'Values'} }
 
=item entries ()

Returns the (unsorted) array of News::Overview::Entry objects within the
object.

=cut

sub entries { values %{shift->{Articles}} }

=item count ()

Returns the number of News::Overview::Entry objects associated with this
object.

=cut

sub count { scalar values %{shift->{Articles}} || 0 }

=back

=head2 Adding Entries

These functions add new News::Overview::Entry items to the object, as
parsed from several sources.

=over 4

=item insert_entry ( NUMBER, INFOARRAY )

Actually does the work of inserting an Entry into the object.  C<NUMBER>
is the article number, which is used as they key for this Entry;
C<INFOARRAY> is the list of information necessary for each Entry, sorted
by whatever function called this one.

Returns undef if there's already an entry matching the given C<NUMBER>,
otherwise returns the new entry.

=cut

sub insert_entry {
  my ($self, @info) = @_;
  my %hash;
  foreach ($self->fields) { $hash{$_} = shift @info || ""; }
  my $msgid = $hash{'Message-ID'};

  # Don't do anything more if there's already an entry for this
  return undef if $self->{'Articles_By_ID'}->{$msgid};

  my @refs = split(/\s+/, $hash{'References'} || "");
  my $item = new News::Overview::Entry($msgid, \@refs, %hash); 
  foreach (@refs) { 
    my $artbyid = $self->{'Article_By_ID'}->{$_} || undef;
    if ($artbyid) { $artbyid->add_child($item) }
  } 
  $self->{'Article_By_ID'}->{$msgid} = $item;

  my $number = $hash{'Number'};	# Ought to abort if we don't have this
  $self->{'Articles'}->{$number} = $item;
  $item;
}

=item add_xover ( LINES )

Reads in raw xover C<LINES> (such as those created by print()) and creates
entries for each, using insert_entry().  Returns the number of Entries
that were succesfully added.

=cut

sub add_xover { 
  my ($self, @lines) = @_;
  my $count = 0;
  foreach my $line (@lines) { 
    chomp; my ($art, @info) = split(/\t/, $line); 
    $self->insert_entry( $art, @info ) and $count++
  }
  $$self{Count} += $count; $count;
}

=item add_from_nntp ( LINEHASH ) 

Reads in the information returned by Net::NNTP's xover() function, and and
creates entries for each, using insert_entry().  Returns the number of
Entries that were succesfully added.

=cut

sub add_from_nntp {
  my ($self, %lines) = @_;
  my $count = 0;
  foreach my $art (keys %lines) { 
    next unless ref $lines{$art};
    my @info = @{$lines{$art}};
    $self->insert_entry( $art, @info ) and $count++
  } 

  $$self{Count} += $count; $count;
}

=item add_from_article ( NUMBER, ARTICLE )

Takes C<ARTICLE>, a News::Article object, and generates the necessary
information to populate an Entry from it.  C<NUMBER> is the key that will
be associated with the article; we need it separately because we can't
really get it from the article directly.  Returns 1 if successful, 0 if
not (roughly the same as add_xover() and add_from_nntp()).

=cut

sub add_from_article {
  my ($self, $num, $article) = @_;
  return undef unless ($num && $article && ref $article);

  my @info;
  my @defaults = ref $self ? $self->default : @DEFAULT;
  foreach my $field (@defaults) {
    $field =~ s/:.*//;
    next if $field eq 'Number';
    # next unless $field;
    if    (lc $field eq 'lines') { push @info, $article->lines; } 
    elsif (lc $field eq 'bytes') { push @info, $article->bytes; } 
    elsif ($article->header($field)) { 
      push @info, $article->header($field);
    } else { push @info, '' } 
  }
  $self->insert_entry( $num, @info ) ? 1 : 0;
}


=head2 Sorting Functions

These functions are used to sort the Entries within the News::Overview
object.

=over 4

=item sort ( SORTTYPE, ENTRIES )

Sort array C<ENTRIES> based on C<SORTTYPE>.  Possible sorting types (case
insensitive):
  
  thread	Uses thread() to sort the messages
  date		Sort (numerically) by the article time
  time		Sort (numerically) by the article time
  lines		Sort (numerically) by lines, then by time
  (other)	Sort (with 'cmp') based on the value of the specified
		field, ie sort by 'From' or 'Subject', then by time
  
If C<SORTTYPE> is prefixed with a '-', then we will return the entries in
revere order.

Returns the sorted array.  

=cut

sub sort {
  my ($self, $sort, @entries) = @_; $sort ||= "";
  my ($reverse, $type) = $sort =~ m/^(\-?)(.*)$/;
  $type ||= 'Number';
  my @return;
  if (lc $type eq 'thread') { 	# thread them
    @return = $self->thread(@entries);
  } elsif (lc $type eq 'lines') { 
    @return = sort { 
	( $a->values->{ucfirst lc $type} <=> $b->values->{ucfirst lc $type} )
     || ( $a->time <=> $b->time ) } @entries; 
  } elsif ( lc $type eq 'date' || lc $type eq 'time' ) { 
    @return = sort { ( $a->time <=> $b->time ) } @entries;
  } elsif ( grep { lc $_ eq lc $type } $self->fields ) { 
    @return = sort { 
	( $a->values->{ucfirst lc $type} cmp $b->values->{ucfirst lc $type} )
     || ( $a->time <=> $b->time ) } @entries; 
  } else { 
    @return = sort { $a->values->{Number} <=> $b->values->{Number} } @entries; 
  }
  $reverse ? reverse @return : @return;
}

=item thread ( ENTRIES )

Sort C<ENTRIES> by thread - that is, with articles that directly follow up 
to a given article following the first article.  The general algorithm:

  Sort ENTRIES by depth and time of posting.
  For each entry, return the entry and its sorted children.
  No article is returned twice.

This doesn't quite work the way you'd expect it to; if the original parent
isn't there, any number of children may appear elsewhere, because there
was no common parent C<ENTRY> to hold things together.  The only solution
I can see is to look at parents as well, sorting them but not printing
them, which isn't currently being done; I may do this in a future version
of this package.

This function is fairly computationally intensive.  It might be nice to
cache this information somehow in some applications; I suspect that this
would be a job for a different module, however.  There's probably also
some computational cruft that I haven't looked for yet.

=cut

sub thread {
  my ($self, @entries) = @_;

  my %added;

  my @return;
  foreach my $ent ( sort News::Overview::_bythread @entries ) { 
    next unless ref $ent;
    my $parent = $ent->id;
    push @return, $ent unless ($added{$ent->id}++);
    my @children = $ent->children;   my @tosort;
    foreach (@children) { push @tosort, $_ unless $added{$_->id} }
    next unless @tosort;
    foreach my $item ( $self->thread(@tosort) ) {
      next unless ref $item;
      # my $item = $$self{Article_By_ID}->{$_};
      push @return, $item unless ($added{$item->id}++); 
    }
  }
  
  @return;
}


=back

=head2 NNTP Functions

These functions perform functions similar to those requested by Net::NNTP,
and are therefore useful for creating modules dedicated to getting this
information in other ways.

=over 4

=item overview_fmt () 

Returns an array reference to the field names, in order, that are stored
in the Entries.  

=cut

sub overview_fmt { my ($self) = @_; ref $self ? $self->default : \@DEFAULT; }

=item xover ( MESSAGESPEC [, FIELDS ] )

Returns a hash reference where the keys are the message numbers and the
values are array references containing the overview fields for that
message.  C<MESSAGESPEC> is parsed with B<Net::NNTP::Function>'s
messagespec() function to decide wich articles to get; C<FIELDS> is an
array of fields to retrieve, which (if not offered) will default to the
value of fields().

We aren't currently dealing with the response if C<MESSAGESPEC> is a
message-ID (or empty); we're assuming that it's just numbers.  This is
wrong.

=cut

sub xover { 
  my ($self, $spec, @fields) = @_;
  @fields = $self->fields unless scalar @fields;
  my ($first, $last) = messagespec($spec);
  # my ($first, $last) = split('-', $spec);
  $first ||= 0;  
  my %entries;
  foreach my $key (keys %{$self->{Articles}}) {
    next if $key < $first;  
    next unless ($last > 0 && $key <= $last);	

    my $entry = $$self{Articles}->{$key};
		# Should be able to get the article by ID too
    next unless $entry;

    my @over;
    foreach (@fields) { 
      next if $_ eq 'Number'; 	# Skip the 'Number' field
      push @over, $entry->values->{$_} 
    }

    $entries{$key} = \@over;
  }
  \%entries;
}

=back

=head2 Printing Functions

These functions offer printable versions of the overview information,
which can be used for long-term storage.

=over 4

=item print ( SORT [, FIELDS] )

Makes a printable version of all of the Entries in the object.  Sorts the
entries based on C<SORT>; C<FIELDS> describes which fields to output;
defaults to fields().  The saved fields are separated with tabs, with all
other whitespace trimmed.  This is suitable for saving out to a file and
later reading back in with add_xover().

Returns an array of lines of text containing the information in array
context, or in scalar context returns these lines joined with newlines.

=cut

sub print {
  my ($self, $sort, @fields) = @_;
  @fields = $self->fields unless scalar @fields;
  my @return;
  my @entries = $self->sort($sort, values %{$self->{Articles}});
  foreach my $art (@entries) { 
    push @return, $self->print_entry($art, @fields);
  }
  wantarray ? @return : join("\n", @return);
}

=item print_entry ( ENTRY )

Print a specific entry's worth of information, as described above.

=cut

sub print_entry {
  my ($self, $entry, @fields) = @_;
  return "" unless ($entry && ref $entry);
  @fields = $self->fields unless scalar @fields;
  my @over;
  foreach (@fields) { push @over, $entry->value($_) }
  map { s/\s/ /g; } @over;	# Trim all whitespace
  join("\t", @over);
}

=back

=cut

###############################################################################
### Internal Functions ########################################################
###############################################################################

### _fields ( ${@heads} )
# Retuns canonical names for the fields header.  Takes an arrayref,
# returns an array.
sub _fields {
  my $heads = shift; 
  my @heads = @{$heads};
  map { s/:.*//g; lc $_ } @heads; 
  @heads;
}

### _bythread ( $a, $b )
# Sort function, to do sorts by thread - this means depth first, then 
# number.  The actual "do children first" part is in thread().  
sub _bythread { 
  $a->depth <=> $b->depth 
    ||
  $a->time <=> $b->time 
  # $a->values->{Number} <=> $b->values->{Number}
}

### _bythread_basic ( $a, $b )
# More basic, depth-only search. 
sub _bythread_basic { $a->depth <=> $b->depth }

=head1 REQUIREMENTS

News::Overview::Entry, News::Article, Net::NNTP::Functions

=head1 SEE ALSO

B<News::Overview::Entry>, B<News::Article>, B<Net::NNTP::Functions>

=head1 NOTES

This was originally designed to be used with News::Archive and kiboze.pl;
it eventually got dragged into News::Web as well, and so it became worth
making into a separate function.  It also didn't quite fit into my newslib
project, since it might be worth optimizing this specifically in the
future.  Aah, well.

=head1 TODO

We should build xhdr(), xpat(), and other Net::NNTP functions into here,
just like xover() and overview_fmt().  

It would be nice if there was a way to say "return 500 entries" in an
xover-type context, instead of "return 1 through 500"; sadly, since
Net::NNTP->xover() doesn't have this, so I'll have to work out some other
way to implement it.

We should be able to limit what we're returning in some more logical
manner, ie with an SQL-type select() function - "return all entries posted
between x and y dates", or "return all entries posted by user z", or
whatever.  

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 COPYRIGHT

Copyright 2003 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
distributed under the same terms as Perl itself.

=cut

1;

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.01b 	Fri Oct 10 11:32:39 CDT 2003 
### First commented version (above date indicates the start of the comments)
# v0.10b	Fri Oct 10 15:25:43 CDT 2003 
### Took out some unnecessary code where necessary.  Made a print_entry()
### function.  
# v0.11b	Fri Oct 10 15:36:45 CDT 2003 
### Very minor documentation changes
# v0.12		Thu Apr 22 13:19:25 CDT 2004 
### No real changes; internal code layout.
