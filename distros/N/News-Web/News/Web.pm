$VERSION = "0.51";
package News::Web;
our $VERSION = "0.51";

# -*- Perl -*- 		# Sun Oct 12 16:05:05 CDT 2003 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003, Tim
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

News::Web - a News<->Web gateway, for a web-based newsreader

=head1 SYNOPSIS

  use News::Web;
  [...]

See 'news.cgi', included with this distribution, to see how this actually
works.

=head1 DESCRIPTION

News::Web is the basis for web-based newsreaders.  It's essentially a
collection of functions called by CGI scripts appropriately.  

=head1 USAGE

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use Net::NNTP;
use News::Article;
use News::Article::Response;		# Newslib
use News::Article::Ref;			# Newslib
use IO::File;
use Carp;
use CGI;
use Date::Parse;
use News::Overview;

use vars qw( $DEBUG $TIMEOUT @ISA $NAME );
$DEBUG    = 0;
$TIMEOUT  = 120;
$NAME     = "News::Web v$VERSION";

use vars qw( @DEFAULTHEAD $MAXHEADLENGTH $COLUMNS $ROWS $SIGROWS );

@DEFAULTHEAD = qw( message-id newsgroups followup-to from subject date
		   references );
  						# References?  
$MAXHEADLENGTH = 1024;
$COLUMNS       = 80;
$ROWS          = 30;
$SIGROWS       =  4;

=head2 Basic Functions 

These functions create and deal with the object itself.

=over 4

=item new ( ITEM )

C<ITEM> is a reference to an object similar to Net::NNTP - that is, this
was designed to work directly with Net::NNTP, but will also work with
other similar classes such as News::Archive.  Returns a reference to the
new object.

=cut

sub new {
  my ($proto, $item) = @_;
  my $class = ref($proto) || $proto;
  my $self = { 'connection' => $item };
  bless $self, $class;
  $self;
}

=item connect ()

=item nntp ()

These functions return the actual NNTP connection (or whatever was passed
into new()), to be manipulated directly by other functions.

=cut

sub connection { shift->{connection} }
sub nntp       { shift->{connection} }

=back

=head2 HTML functions

These functions create the HTML tables used by the various CGI scripts.

=over 4

=item html_article ( ARGHASH )

Returns an HTML-formatted version of a news article, either by passing in
a full article, a message ID of an article to retrieve, or a newsgroup and
message number to pass.  Also includes several linkback()'d sets of actions 
we can perform on the article.  

Arguments we take from C<ARGHASH>:

  article	A full news article, read directly into the 
		News::Article object.  
  mid		The Message-ID of an article to read.
  group	   \	Together, the group and article number to read in
  number   /	from the NNTP connection to get the article.
  fullhead	Should we use full headers, or a limited set (as 
		specified in @News::Web::DEFAULTHEAD)?  Defaults to 0.
  clean		Just print the article, and not the linkbacks.  
		Defaults to 0.
  plaintext	Should we print this as plaintext or as HTML?  
		Defaults to 0 (HTML).
  default	A hashref of defaults; this isn't actually used here,
		but is passed on where necessary to other functions.

Current linkbacks (we'll work out a way to better format and select these
later).

  Follow Up	   Respond to this article (with html_makearticle()).
  Full Headers	   Show all of the headers, not just the limited set.
  Original Format  The message in its original format (only if we're 
		   not already doing so).
  First in Thread  The first article in the thread (only if there 
		   is one).
  Immediate Parent The article that this message responded to (if
		   there is one).

  Next Article     \  Links to the next/previous article in each 
  Previous Article /  group (not based on thread, sadly)

I'm not entirely happy with the format of this yet, but it works for now.
I would also to add "next/previous in thread", rot13, lists of children,
and so forth.  And the linkback list may at some point be more consistent
and available programmatically, which would let it be tied into other
functions, such as moderation 'bots.
		
=cut

sub html_article   { 
  my ($self, %args) = @_;

  # Get the article, one way or the other
  my ($article, @return, %linkback);
  if ($args{'article'}) { $article = $args{'article'}; } 
  elsif (my $mid = $self->clean('Message-ID', $args{'mid'})) { 
    (carp "Bad Message-ID" && return '') unless $mid;
    $article = $self->nntp->article($mid);
    unless ($article) {
      my $clean = $args{'plaintext'} ? $mid : $self->html_clean($mid);
      return "No such article: $clean";   
    }
    $mid =~ s/^<//g;  $mid =~ s/>$//g;
    $linkback{'mid'} = $mid;
  } elsif ($args{'group'} && $args{'number'}) { 
    $self->nntp->group($args{'group'}) || return "No such group '$args{group}'";
    $article = $self->nntp->article($args{'number'})
	|| return "No such message '$args{number}' in '$args{group}'";
    $linkback{'group'} = $args{'group'};  $linkback{'number'} = $args{'number'};
  } else { return "No message specified" }

  # Read in the article into a News::Article object
  my $art = News::Article->new($article);  
  return "No article" unless $art;

  # Actually print the article
  if ($args{'plaintext'}) { 
    push @return, join('', join("\n", $art->headers, '', $art->body, ''));
  } else { push @return, $self->_html_article($art, $args{'fullhead'} || 0) }
  
  # If we're just getting the article with 'clean' or 'plaintext', don't 
  # offer the linkbacks.
  return @return if $args{'clean'} || $args{'plaintext'};

  # Additional linkbacks for the article
  my @linkback;
  my $mid = $art->header('message-id');  $mid =~ s/(^<|>$)//g;
  push @linkback, $self->linkback( "Follow Up", { 'post' => 1, 'mid' => $mid })
		  if $self->nntp->postok;	# Should look at something else
  push @linkback, $self->linkback( "Full Headers", 
			{ 'fullhead'  => 1, %linkback } );
  push @linkback, $self->linkback( "Normal Format", { %linkback } )
		if ($args{'fullhead'} || $args{'plaintext'});

  my @ids = split(/\s+/, $art->header('references'));
  my %linkarts = ( "First in Thread" => $ids[0],
		   "Immediate Parent" => $ids[scalar @ids - 1] );
  foreach my $desc (sort keys %linkarts) { 
    my $id = $linkarts{$desc};  $id =~ s/^<|>$//g;
    push @linkback, $self->linkback( $desc, { 'mid' => $id } ) if $id;
  }

  push @return, join(" ", "<p>Article actions: [ ", 
		join(" | ", @linkback), " ]</p>") if scalar @linkback;

  # Determine which groups we will use the 'next' and 'previous' article 
  # options on.  We use Xref for the list; this isn't really ideal, IMO,
  # but it's a good start.
  my %grouplist;
  if (my $group = $args{'group'} and my $number = $args{'number'}) { 
    $grouplist{$group} = $number;
  } else { 
    my ($server, @grouplist) = split(/\s+/, $art->header('xref'));  
    foreach (@grouplist) {
      my ($group, $number) = split(':', $_);  
      $grouplist{$group} = $number;
    }
  }

  foreach my $group (sort keys %grouplist) { 
    my $number = $grouplist{$group};

    # We really want a 'next in thread' option, sadly.  Or whatever sorting
    # method we used.  This will be *TRICKY* to accomplish.
    my ($count, $first, $last, $name) = $self->nntp->group($group);
    my @linkback2; 
    
    push @linkback2, $number <= $first ? "<i>Previous</i>" 
		: $self->linkback( "Previous", 
		  { 'group' => $group, 'number' => $number - 1 } );
    push @linkback2, $number >= $last ? "<i>Next</i>" 
		: $self->linkback( "Next", 
		  { 'group' => $group, 'number' => $number + 1 } );
  
    push @return, join("", "<p> Articles in $group: [ ", 
			join(" | ", @linkback2), " ]</p>") if scalar @linkback2;
  }

  join("\n", @return);
}


=item html_makearticle ( ARGHASH )

Creates an HTML form to write new articles, based on a previous article if
the proper information is passed in with C<ARGHASH>.  This is put into a
table that has three major sections - the header section, the body, and
the signature.  

If a previous article is indicated (with 'mid'), then we base the new
message off of that article with News::Article::Response.  

Arguments we take from C<ARGHASH>:
  mid		The Message-ID of a message we're responding to; 
  group		The newsgroup we're posting to
  prefix	A prefix to the new message-ID (see News::Article)
  domain	The domain of the new message-ID (see News::Article).
  columns	The number of columns to format the body and
		signature.  Defaults to $News::Web::COLUMNS or 80.
  rows		The number of rows for the textarea box of the body; 
		defaults to $News::Web::ROWS or 30. 
  sigrows	The number of rows for the textarea box of the 		
		signature box; defaults to $News::Web::SIGROWS or 30. 
  nosignature	Don't offer use the signature box.
  wraptype	How should we wrap the quoted material?  See
		News::Article::Reference.  Defaults to 'overflow'.
  params	A hashref of extra parameters to pass into html_post()
  default	A hashref of defaults; this isn't actually used here,
		but is passed on where necessary to other functions.

Current linkbacks:

  Post		Meant to invoke html_post()
  Preview	Meant to invoke html_post() with the preview flag 

We're not really using CSS at all yet, which is a mistake.

=cut

sub html_makearticle {
  my ($self, %args) = @_;
  my $cgi = new CGI;

  my $default = $args{'default'} || {};
  my $params  = $args{'params'}  || {};

  # Get defaults out of %args or from the module
  my $cols    = $args{'columns'} || $COLUMNS || 80;
  my $rows    = $args{'rows'}    || $ROWS    || 30;
  my $sigrows = $args{'sigrows'} || $SIGROWS || 4;

  # Get the article that we're starting from
  my $oldart;
  if (my $mid = $args{'mid'}) { 
    my $clean = $self->clean('Message-ID', $mid);
    my $message = $self->nntp->article($clean) || [];
    $oldart = News::Article->new( $message );
  } else { $oldart = new News::Article }
  my $art = $args{'article'} ? $args{'article'}
    	: News::Article->response($oldart, 
		{ 'From'   => $args{'author'} || "",
		  'Newsgroups' => $args{'group'} || undef }, 

		'prefix'   => $args{'prefix'} || "",
		'domain'   => $args{'domain'} || "",
		'colwrap'  => $cols,
       	 	'wraptype' => $args{'wraptype'} || 'overflow',
		'nodate'   => 1, 
				 );
 
  my @return = "<h2> Composing Article </h2>";
  push @return, $cgi->start_form('post');

  push @return, $cgi->start_table({ -cellpadding => 0,
				    -cellspacing => 0 });
  
  # User-modifiable headers
  foreach ( qw( Newsgroups From Subject ) ) { 
    next unless $art->header($_);
    push @return, $cgi->Tr({-align=>'left', -valign=>'CENTER'},
	[ $cgi->td( [$_, $cgi->textfield(-name => "header_$_", 
	       -default => $art->header($_) || "",
	   -size => $cols - length $_, -maxlength => $MAXHEADLENGTH) ]) ]);
  }
  # Headers that are already set
  foreach ( qw( Message-ID References ) ) {
    next unless $art->header($_);
    push @return, $cgi->Tr({-align=>'left', -valign=>'CENTER'},
	[ $cgi->td( [$_, join("\n", 
		$self->html_clean($art->header($_) || ""), 
		$cgi->hidden(-name => "header_$_", 
			  -default => $art->header($_) || "" )) ]) ]);
  }

  # Body of the message - this will be in its own textarea box.
  my @body = $art->body;

  # Put headers beyond the ones we've already processed into the body of
  # the message, so they can be looked at and all.  
  my %extrahead;
 BODYHEAD:
  foreach my $head ($art->header_names) { 
    foreach ( qw( Message-ID References Newsgroups From Subject ) ) { 
      next BODYHEAD if lc $_ eq lc $head;
    }
    $extrahead{News::Article::canonical($head)} = $art->header($head);
  }
  unshift @body, '' if scalar keys %extrahead;
  foreach (keys %extrahead) { unshift @body, "$_: $extrahead{$_}" }
  my $body = join("\n", @body);

  # Blank line between the headers and body
  push @return, $cgi->Tr( [ $cgi->td( "&nbsp;" ) ] );	
  push @return, $cgi->Tr({-align=>'left', -valign=>'CENTER'},
	[ $cgi->td( { -colspan => 2, -nowrap => 1 }, 
	  [ $cgi->textarea( -name => 'body', -default => $body, 
		            -rows => $rows, -cols => $cols, -wrap => 'hard') ]
						 ) ]);

  # Signature field, if so desired (with '-- ')
  unless ($args{'nosignature'}) { 
    push @return, $cgi->Tr({-align=>'left', -valign=>'CENTER'},
	[ $cgi->td( { -align=>'left', -colspan=>2}, "-- ") ] );

    push @return, $cgi->Tr({-align=>'left', -valign=>'CENTER'},
	[ $cgi->td( { -colspan=>2, -nowrap=>1 }, [ 
		$cgi->textarea(-name => 'signature', -wrap => 'hard',  
		    -default => $args{signature} || "",
		    -rows => $sigrows, -cols => $cols) ] ) ]);
  }

  # Submit/preview the article
  push @return, $cgi->Tr({},
	[ $cgi->td({-colspan=>2, -align=>'right'}, 
	     [ join(" ", $cgi->submit(-name=>'preview', -value=>'Preview'), 
		         $cgi->submit(-name=>'post', -value=>'Post') ) ]) ]);

  foreach (keys %{$params}) { 
    next if lc $_ eq 'preview';
    next if lc $_ eq 'post';
    push @return, $cgi->hidden($_, $$params{$_});
  }

  push @return, $cgi->end_table;
  push @return, $cgi->end_form;

  join("\n", @return);
}

=item html_post ( ARGHASH )

Actually posts the message.  Gets the article from passed in arguments
through C<ARGHASH>, adds some headers, and does the work.

Arguments we take from C<ARGHASH>:

  params	CGI parameters that were passed in
    header_*	The headers of the message
    body	The body of the message, separated by newlines
    signature	The signature of the message

  trace		The content to set 'X-Local-Trace' to, which is 
		currently set by the CGI (but should probably be 
		done locally).
  default	A hashref of defaults; this isn't actually used here,
		but is passed on where necessary to other functions.

Extra headers are pulled out of the first lines of the body of the
message.  Adds 'X-Newsreader' and 'X-Local-Trace', drops 'Approved' and
'Date'.  Runs html_makearticle() if necessary because the article didn't,
or wouldn't, post.

=cut

sub html_post {
  my ($self, %args) = @_; 
  return "Can't post to this server" unless $self->nntp->postok;	
  
  my $article = new News::Article;
  my $params = $args{'params'} || {};

  # Get headers out of the $params hashref; all headers are preceded with 
  # header_.
  foreach (sort %{$params}) { 
    next unless /^header_(.*)$/;
    my $header = $1;
    $article->set_headers($header, $$params{$_});
  }

  my $body = $$params{'body'};  
  my $signature = $$params{'signature'};
  $signature =~ s/\s*$//; 	# Trim out trailing whitespace

  $article->set_body($body);
  $article->trim_blank_lines;
  if ($signature) { $article->add_body("-- ", $signature); }

  # Get headers out of the body
  my (@body, $headers);
  foreach my $line ($article->body) { 
    if (!$headers && $line =~ /^([\w-]+):\s+(.*)$/) { 
      $article->set_headers($1, $2);
    } elsif (!$headers && /^\s+/) { $headers++ }
      else { push @body, $line }
  }
  $article->set_body(@body);

  $article->drop_headers('approved', 'date', 'x-newsreader');
  $article->add_date;
  $article->set_headers('x-newsreader', $NAME );
  $article->set_headers('x-local-trace', $args{'trace'});

  # Abort if we don't have all of the necessary headers
  my @problems;
  foreach ( qw( Newsgroups Date Message-ID From Subject ) ) {
    push @problems, "Missing the '$_' header" unless $article->header($_);
  }

  if (scalar @problems) { 
    my @return;
    push @return, "<h2> Problems Posting </h2>", "<ul>";
    foreach (@problems) {  push @return, "<li> $_"; }
    push @return, "</ul>"; 
    push @return, $self->html_makearticle( 'article' => $article, %args);
    return @return;
  }

  # Here's the actual posting
  my $messageid = $article->header('message-id');
  my $nntp = $self->nntp;   
  my @return;
  my $preview = $$params{'preview'};
  if ($preview) { 
    push @return, "<h2> Preview </h2>"; 
    push @return, $self->_html_article($article, 1);
    push @return, $self->html_makearticle( 'article' => $article, %args);
  } else { 
    my $ret =  eval { $article->post( $nntp ) };
    if ($@) { 
      my $error = $@;
      chomp $error;		# Remove trailing whitespace
      warn "Error in posting $messageid: $error\n";
      push @return, "<h2> Problems Posting </h2>", "<ul>";
      push @return, "<li> $error";
      push @return, "</ul>"; 
      push @return, $self->html_makearticle( 'article' => $article, %args);
    } else { 
      my $id = $article->header('message-id');
      push @return, "Message $id posted successfully <br /> <br />\n";
      
      push @return, $self->_html_article($article, 1);
    }
  }

  @return;
}

=item html_overview ( ARGHASH )

Generate an HTML-formatted table of the overview entries of a given
newsgroup (see News::Overview).  This table consists of nexttable(),
tableheaders(), lines for each entry, then nexttable() again.

COUNT is the number of articles we should get; it should be the number of
articles that we actually return, but this isn't done yet.  The subject is
linkback()'d to the actual message.  

Arguments we take in C<ARGHASH>:

  count		The number of articles that we should return.  
		Currently, this is actually the number that we ask 
		for.  
  last		The last article we should get.  With 'count', FIRST =
		COUNT - LAST + 1.  
  first		The first article we should get.  With 'count' and no 
		'last', LAST = first + count - 1
  sort 		The sorting method for the articles, as set in 
		News::Overview.
  fields	The fields from the overview DB to add columns for; 
		defaults to News::Overview's defaults.  These
  default	A hashref of defaults; this isn't actually used here,
		but is passed on where necessary to other functions.

=cut

sub html_overview  { 
  my ($self, %args) = @_; 
  my $group = $args{'group'} || "";
  my ($count, $first, $last, $name) = $self->nntp->group($group)
        or ( carp "Couldn't connect to $group: $!\n" && return '');

  # If we actually set count in args, then we should base things off of it
  if (defined $args{count}) { 
    if ($args{first}) { 
      $first = $args{first};
      $last  = $first + $args{count} - 1;
    } elsif ($args{last} && $args{last} >= $first ) { 
      $first = $args{last} - $args{count} + 1;
      $last = $args{last};
    } else {	# We always take the last batch of articles; good idea?
      $first = $last - $args{count} + 1;
    }
    $count = $args{count};
  } else {
    # Figure out where to start and stop with this overview information
    $first = $args{first} if (defined $args{first} && $args{first} >= $first); 
    $last  = $args{last}  if (defined $args{last}  && $args{last}  <= $last );
  }

  $first = 1 if ($first <= 1);

  my $default = $args{'default'} || \%args;
  my $sort    = $args{'sort'} || 'thread';

  # Get the overview format information
  my $fmt = $self->nntp->overview_fmt || undef;

  # Start the overview object
  my $overview = News::Overview->new( ref $fmt ? $fmt : "" );

  # Request and parse the overview information
  my $xover= $self->nntp->xover("$first-$last")
                or ( carp "Couldn't get xover info: $!\n" && return '' );
  foreach my $msg (sort keys %{$xover}) {
    $overview->add_from_nntp($msg, $$xover{$msg});
  }

  # return '' unless scalar keys %{$xover};
  unless (scalar keys %{$xover}) { 
    return $self->nntp->postok ? 
    	join("", "<p align=center>", $self->linkback( "Post a New Message", 
				{ 'post' => 1, 'group' => $group }), "</p>")
			       : "";
  }

  # If we didn't get a fields list, default to the default overview ones
  my $fields = $args{'fields'} || $overview->fields();

  my @return;

  # Not ideal, but it'll do briefly; we should have it only pass those 
  # values that we absolutely need.
  my %passargs; 
  $passargs{'group'} = $group if $group;
  $passargs{'first'} = $first;
  $passargs{'last'}  = $last;
  $passargs{'count'} = $count;
  $passargs{'sort'}  = $args{'sort'};

  push @return, $self->nexttable ( \%passargs, [ $self->nntp->group($group) ],
						$default );

  push @return, "<table cellpadding=0 width=100%>", "<tr>";
  push @return, $self->tableheaders( $fields, \%passargs, $default);
  push @return, "</tr>";

  my $even = '0';

  foreach my $entry ( $overview->sort( $sort, $overview->entries ) ) {
    my $mid = $entry->values->{'Message-ID'};
    $mid =~ s/^<//g;  $mid =~ s/>$//g;
    my $number = $entry->values->{'Number'};

    push @return, "<tr>";
    foreach (@{$fields}) {
      my $nowrap = "nowrap";
      my $value = $self->html_clean(
			$self->clean($_, $entry->values->{$_}, $entry));
      $value = $self->linkback($value, 
		{ 'group' => $group, 'number' => $number })
		# { 'mid' => $mid }) 
				if lc $_ eq 'subject';
      if (lc $_ eq 'newsgroups') { 
        $nowrap = "";
        my @groups = split(',', $value);
        @groups = grep { $_ !~ /archive\..*/ } @groups;	# Drop archive.* groups
        map { $_ = $self->linkback($_, { 'group' => $_ }) } @groups;
        $value = join(', ', @groups);
      }
      
      push @return, defined $value 
		? "<td class='overview_$even' $nowrap>$value</td>"
                : "<td class='overview_$even' $nowrap> &nbsp </td>";
    }
    push @return, "</tr>";
    if ($even == 0) { $even++ } else { $even = 0 }
  }

  push @return, "</tr>", "</table>";
  my ($self, $params, $groupinfo, $defaults) = @_;
  push @return, $self->nexttable ( \%passargs, [ $self->nntp->group($group) ],
						$default );

  push @return, join("", "<p align=center>", 
     $self->linkback( "Post a New Message", { 'post' => 1, 'group' => $group }),
  			 "</p>") if $self->nntp->postok;
  join("\n", @return);
}

=item nexttable ( PARAMHASH, GROUPINFO, DEFAULTHASH ) 

Creates the 'next table' bits for html_overview().  C<GROUPINFO> is an
arrayref that is the response of Net::NNTP->group(), and is used to
determine what articles exist so we know what to link to.

C<PARAMHASH> and C<DEFAULTHASH> are passed to linkback() (with different
'sort' options).  

We don't have any CSS hooks right now, again a mistake.

Returns as an array of HTML lines.

=cut

sub nexttable {
  my ($self, $params, $groupinfo, $defaults) = @_;
  return "" unless ($params && ref $params);
  my $count = $$params{count};  return "" unless $count;
  my $first = $$params{first};  my $last = $$params{last};

  $defaults ||= {};

  $last = @{$groupinfo}[2] if $last >= @{$groupinfo}[2];

  $first ||= 1;  
  my @return = "<table width=100%>";
  push @return, "<tr>";

  # Initialize hashes
  my %prev;  foreach (keys %{$params}) { $prev{$_} = $$params{$_} };
  my %next;  foreach (keys %{$params}) { $next{$_} = $$params{$_} };

  $prev{last}  = $first - 1;      delete $prev{first};
  $next{first} = $first + $count; delete $next{last};

  my %sort1;  foreach (keys %{$params}) { $sort1{$_} = $$params{$_} };
  $sort1{'sort'} ||= "thread"; 
  my %sort2;  foreach (keys %{$params}) { $sort2{$_} = $$params{$_} };
  $sort2{'sort'} ||= "-thread"; 

  my $prev = $first < @{$groupinfo}[1] 
	? "<i>Previous</i"
	: $self->linkback("Previous", \%prev, $defaults) ;
  push @return, "<th align=left>$prev</th>\n";
  push @return, "<th width=100%>", "Articles $first - $last", 
	( $$params{sort} eq 'thread' ? "" : 
	      "<br />" . $self->linkback( "Sort by Thread", \%sort1, $defaults ) ),
	"</th>";
  my $next = $last >= @{$groupinfo}[2]
	? "<i>Next</i>"
	:  $self->linkback("Next", \%next, $defaults) ;
  push @return, "<th align=right>$next</th>\n";
  
  push @return, "</tr>", "</table>";
  @return;
}

=item tableheaders ( FIELDARRAYREF, PARAMHASH, DEFAULTHASH )

Creates the table headers for html_overview().  C<FIELDARRAYREF> is the
list of fields that will be printed in the table body.  Each of these is
printed as two linkback()s, one to sort based on this field and the other
to sort the same but backwards.  These links are parsed by
html_overview().  C<PARAMHASH> and C<DEFAULTHASH> are passed to linkback()
(with different 'sort' options).  

Stylesheet hooks: 

  groupinfo	TH style to describe the headers

Returns as an array of <th> lines.

=cut

sub tableheaders {
  my ($self, $fields, $params, $default) = @_;
  my @return;
  foreach my $field (@{$fields}) { 
    my %local; foreach (keys %{$params}) { $local{$_} = $$params{$_} }
    $local{'sort'} = ucfirst lc $field;
    my $field1 = $self->linkback($field, \%local, $default);
    $local{'sort'} = join('-', '', ucfirst lc $field);
    my $field2 = $self->linkback('-', \%local, $default);
    push @return, "<th class='groupinfo'>$field1 <br /> ($field2)</th>" 
  };
  @return;
}

=item html_grouplist ( [PATTERN] )

Lists all of the active newsgroups, based on C<PATTERN> (defaults to '*'),
with descriptions.  Returns the text to be printed, joined by newlines.

If C<PATTERN> is not passed in, then we will instead get the default list
of groups out of 'subscriptions'.  

Possible refinements: should we list the number of messages (estimated or
real)?  The posting status of the group (moderated, no-posting, etc)?

Stylesheet hooks: 

  grouplist_head	TR and TD style, for the headers of the table.
  grouplist		TR style, for the actual table content lines.
  grouplist_1		TD style, alternating between the two styles, 
  grouplist_2		to allow the lines to look different (and 
			and therefore be easier to follow).

=cut

sub html_grouplist { 
  my ($self, $pattern, $newsrc, $print) = @_; 	# Not using the last two
  my ($groups, $descs);
  if ($pattern) { 
    $groups = $self->nntp->active($pattern)
         or ( carp "Couldn't get newsgroups: $!\n" && return '');
  } else { 
    $groups = {};
    foreach ( @{$self->nntp->subscriptions()} ) { 
      my $value = [ $self->nntp->active($_) ];
      next unless $value;
      $$groups{$_} = [ $value ];
    }
    $pattern = "*";
  }
  $descs  = $self->nntp->newsgroups('*')
        or ( carp "Couldn't get group descriptions: $!\n" && return '');

  return "" unless scalar keys %{$groups};

  my (@return);
  my $even = 0;
  
  push @return, "<table cellpadding=0 width=100%>";
  push @return, "<tr class='grouplist_head'>", 
			"<th class='grouplist_head'>Group</th>", 
			"<th class='grouplist_head'>Description</th>", "</tr>";
  foreach my $group (sort keys %{$groups}) { 
    my ($last, $first, $flags) = @{$$groups{$group}};
    push @return, "<tr class='grouplist'>";
    my $link = $self->linkback($group, { 'group' => $group });
    push @return, 
      "<td class='grouplist_$even'> $link </td>";
    push @return, $$descs{$group} 
          ? "<td class='grouplist_$even'>$$descs{$group}</td>"
          : "<td class='grouplist_$even'> &nbsp; </td>";
    push @return, "</tr>";
    if ($even == 0) { $even++ } else { $even = 0 }
  } 

  push @return, "</table>";
  join("\n", @return, '');
}

=item html_hierarchies ( LEVELS, PATTERN )

Gives a set of linkback()'d group listings, based on the newsgroups
available on the server.  C<PATTERN> is the WILDMAT pattern to decide
which groups to match; C<LEVELS> defines how many levels down to go down
when matching the pattern ('news' would be one level, 'news.admin' would
be two, etc).  Doesn't match actual newsgroups, just hierarchies.

Returns the list of linkbacks in an array context, or a line of them
combined with ' | ' as a scalar.

=cut

sub html_hierarchies {
  my ($self, $levels, $pattern) = @_;
  $levels ||= 1;  $pattern ||= "*";

  my $groups = $self->nntp->active($pattern)
        or ( carp "Couldn't get newsgroups: $!\n" && return '');

  my %hiers;
  foreach (sort keys %{$groups}) { 
    my @array = split('\.', $_); 
    $hiers{$array[0]}++;        
    for (my $i = 1; ( $i < scalar @array ) && ( $i < $levels ); $i++) {
      my $string = $i eq 0 ? $array[0] : join('.', @array[0..$i]);
      $hiers{$string}++;
    }
  }
  my @return;
  foreach (sort keys %hiers) { 
    push @return, $self->linkback($_, { 'pattern' => "$_.*" });
  } 
  wantarray ? @return : join(" | ", @return);
}

=item linkback( TEXT, HASHREF, DEFAULT ) 

Returns an HTML link back to the same program, based on the hash
references C<HASHREF> and C<DEFAULT>.  C<TEXT> is the string that appears
in the link.  The key/value pairs in C<HASHREF> are the options passed in
the URL; however, if the C<DEFAULT> hash matching value matches
C<HASHREF>, then we assume that we don't need that argument (and we should
try to keep the URL short anyway).

This probably needs more refinement, but it more or less works.  

=cut

sub linkback {
  my ($self, $text, $hash, $default) = @_;
  $hash ||= {};  $default ||= {};
  my $url = $0;  $url =~ s%.*/%%g;	# Should be something better
  my @opts;
  foreach (sort keys %{$hash}) { 
    push @opts, "$_=$$hash{$_}" unless $$default{$_} eq $$hash{$_};
  }
  my $opts = join('&', @opts);
  my $text = "<a href='$url?$opts'>$text</a>";
  $text;
}

=item clean ( HEADER, INFO, ENTRY, ARGS )

Cleans up the news information for the best distribution.  Mostly useful
for creating new articles and parsing article inforation properly; not so
useful for actually printing articles, where the original formatting may
have been generally useful.  C<HEADER> choices that are currently
supported:

  subject	Formats the Subject: line to have quote characters 
		at the start (based on the number of entries in 
		References: within C<ENTRY>) and trim the total
		length of the string.
  from 		Formats the From: line consistently; by default it 
		gets the actual author and drops the email address.
		Also trims the total length of the string (see 
		the arguments section).
  date		Format the date consistently with Format::Date's
		str2time() command.  
  message-id	Make sure that the passed ID is properly formatted
		with '<' and '>' characters.

Arguments we take:
  
  subjwidth	Width to trim the Subject: line to; if less than 0, 
		then we don't trim the header at all.  Defaults to 55.
  fromwidth	Width to trim the From: line to; if less than 0, then 
		we don't trim the header at all.  Defaults to 25.
  fromtype	The formatting method for the From: line.  Possible
		options: 'name', 'nameemail', 'email', 'emailname'.
		Defaults to 'name'.

This should be replaced with something from News::Article::Ref, or moved
into there.

=cut

sub clean {
  my ($self, $header, $info, $entry, %args) = @_;
  my @return;  
  if    (lc $header eq 'subject') { 
    @return = $self->_subject($info, $entry ? $entry->depth : 0, 
				     $args{'subjwidth'} || 55 ) 
  } 
  elsif (lc $header eq 'from')       { 
    @return = $self->_author($info, $args{'fromwidth'} || 25,
				    $args{'fromtype'}  || 'name' ) 
  } 
  elsif (lc $header eq 'date')       { @return = $self->_date($info, %args)   } 
  elsif (lc $header eq 'message-id') { @return = $self->_mid($info, %args)    } 
  else                               { @return = $info                        }
  wantarray ? @return : join("\n", @return);
}


=item html_clean ( LINE [, LINE [...]] )

Cleans up C<LINE>(s) for the web - ie, fixes special HTML characters, and
sets up links for http:// and ftp:// links.  Returns a string containing
the modified lines, joined with newlines.

There's probably a lot more that can be done here.  

=cut

sub html_clean {
  my ($self, @return) = @_;
  map { s/\</\&lt;/g } @return;   
  map { s/\>/\&gt;/g } @return;
  map { s%((?:http|ftp):\/\/[^\s&]+)%<a href="$1">$1</a>%g } @return;
  join("\n", @return);
} 

=item html_markup ( HEADER, TEXT [, ARGS] )

Marks up C<HEADER> and C<TEXT> to be printed in HTML.  C<TEXT> is put
through html_clean() and an additional set of fixes:
 
  newsgroups		linkback() to the given group

C<HEADER> is bolded.  The final layout - "HEADER: TEXT".

=cut

sub html_markup {
  my ($self, $header, $text, %args) = @_;
  $text = $self->html_clean($text);  
  if (lc $header eq 'newsgroups') { 
    $text = $self->_html_newsgroups($text, %args); 
  }
  $header = News::Article::canonical($header);  
  $text =~ s/(\r?\n)/<br \/>$1&nbsp;&nbsp;&nbsp;/g; 
  $text ? "<b>$header</b>: $text" : "";
}

###############################################################################
### Internal Functions ########################################################
###############################################################################

### _subject ( STRING, DEPTH, WIDTH )
# Update the subject with an appropriate number of '>' marks (based on
# DEPTH), and to a certain text width (based on WIDTH).
sub _subject {
  my ($self, $string, $depth, $width) = @_;
  $width ||= 55;  $depth ||= 0;  $string ||= "";

  # This should be more general-purpose, but it'll do for now
  $string =~ s/^Re:\s*//i if $depth;

  my $quotestring = "";
  if ($depth < 10) {
    for (my $i = 0; $i < $depth; $i++) {
      $quotestring = join('', '>', $quotestring);
    }
  } 
  elsif ($depth < 100) { $quotestring = ">>> $depth >>"; } 
  else                 { $quotestring = ">> lots >"; }
  $string = $depth ? "$quotestring $string" : $string;

  my $real = $width - 5;
  $string =~ s%^(.{0,$real})(.{5})(.*)$%join('', $1, $3 ? '[...]' : $2)%egx
	unless ( $width <= 0 && length $string <= $real );

  $string;
}

### _author ( STRING, WIDTH, TYPE )
# Get the actual writer out of a From: line, dropping the email address
# and trimming it down to WIDTH characters, and canonicalizes the format
# based on TYPE ('name', 'email', 'namemail', or 'emailname').  
#
# Note that this is *far* too complicated, and based on old code that I
# wrote a long time ago and never bothered to make into a real module; I
# should really write that module.  Should also do something better than
# 'unknown.site.invalid' and such.
sub _author  {
  my ($self, $string, $width, $type) = @_; return undef unless $string;
  $width ||= 25;  $type  ||= 'nameemail';  $string ||= "";
  my $address = ""; my $comment = "";

  # Information from News::Article::Ref
  my $PLAIN_PHRASE = $News::Article::Ref::PLAIN_PHRASE;
  my $ADDRESS      = $News::Article::Ref::ADDRESS;
  my $PAREN_PHRASE = $News::Article::Ref::PAREN_PHRASE;
  my $LOCAL_PART   = $News::Article::Ref::LOCAL_PART;
  my $DOMAIN       = $News::Article::Ref::DOMAIN;

  # RFC 1036 standard From: formats
  if ($string =~ /^\s*(?:\"?($PLAIN_PHRASE)?\"?\s*<($ADDRESS)>|
                         ($ADDRESS)\s*(?:\(($PAREN_PHRASE)\))?)\s*$/x) {
    $address = $2 || $3;
    $comment = $1 || $4;

  # No sitename was attached to the address - either append the local one if 
  # appropriate or set something saying that there wasn't one at all.
  } elsif ($string =~ /^\s*(?:\"?($PLAIN_PHRASE)?\"?\s*<($LOCAL_PART)>|
                       ($LOCAL_PART)\s*(?:\(($PAREN_PHRASE)\))?)\s*$/x) {
    $address = $2 || $3;
    $comment = $1 || $4; 
    
    my $host = "unknown.site.invalid";
    $address = join('@', $address, $host);

  # The phrases had a bad part to them - scrap those parts.
  } elsif ($string =~ /^\s*(?:(.*)\s*<($LOCAL_PART\@?$DOMAIN?)>|
                        ($LOCAL_PART\@?$DOMAIN?)\s*(.*))\s*$/x) {
    $address = $2 || $3;
    $comment = $1 || $4;
    
    unless ($address =~ /\@\S+$/) {
      $address =~ s/\@$//g;
      my $host = "unknown.site.invalid";
      $address = join('@', $address, $host);
    }

  # There's no way we're getting a valid address out of this, so let's see
  # if we can find something *invalid*
  } else {
    if ($string =~ /^\s*(.*)\s*<(.*\@.*)>\s*$/)  { $comment= $1; $address = $2 }
    elsif ($string =~ /^\s*(\S+\@\S+)\s*(.*)\s*$/) { 
      if ($2) { $address = $1; $comment= $2 }
    }
    else { $string =~ s/^\s+|\s+$//g; }
    map { s/^\s*|\s*//g } $comment, $string, $address;
    $comment =~ s/[\"\(\)]//g;

    $comment ||= $string;
    $address ||= 'unknown@unknown.site.invalid';
  }

  $address ||= "";  $comment ||= "";
  map { s%(^\s*|\s*$)%%g } ($address, $comment);

  $comment =~ s/[\"\(\)]//g;

  my $retstring;
  if    (lc $type eq 'email')     { $retstring = $address; }
  elsif (lc $type eq 'nameemail') { $retstring = "$comment <$address>" }
  elsif (lc $type eq 'name')      { $retstring = $comment } 
  elsif (lc $type eq 'emailname') { $retstring = "$address ($comment)" }
  else                            { $retstring = "$comment <$address>" }

  # We always want *something*
  $retstring ||= $address;

  my $real = $width - 5;
  $retstring =~ s%^(.{0,$real})(.{5})(.*)$%join('', $1, $3 ? '[...]' : $2)%ex
	unless ( $width <= 0 && length $retstring <= $real );
  $retstring;
}

### _date ( [DATE] )
# Print the date in a consistent format; this really ought to be the
# consistent news format, though.  If DATE isn't passed, we just use the
# current time.  We should use the stuff from News::Article's add_date().
sub _date {
  my $self = shift;
  my $time = str2time(shift);
  my @MONTHS = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  sprintf("%03s %02d %04d %02d:%02d:%02d",
     @MONTHS[(localtime($time))[4]], (localtime($time))[3], 
     (localtime($time))[5] + 1900, # (localtime($time))[4] + 1,
     (localtime($time))[2], (localtime($time))[1], (localtime($time))[0] );
          }

### _mid ( ID )
# Make sure the '<' and '>' are on the ID, if the ID exists.  Probably
# ought to make sure the ID is good first.
sub _mid {
  my ($self, $mid) = @_;
  return "" unless $mid;
  $mid = join('', '<', $mid, '>');
  $mid =~ s/^<</</g;  $mid =~ s/>>$/>/g;
  $mid;
}

### _html_newsgroups ( LINE )
# html-ify the Newsgroups: header, with linkback().
sub _html_newsgroups {
  my ($self, $line) = @_;
  my @groups = split(',', $line);
  map { $_ = $self->linkback($_, { 'group' => $_ }) } @groups;
  join(',', @groups);
}

### _html_article ( ARTICLE, FULLHEAD )
# Actually does the work of returning the article in HTML form.  If
# FULLHEAD is set, returns all headers; otherwise, only uses DEFAULTHEAD.
sub _html_article {
  my ($self, $article, $fullhead) = @_;
  my @return;
  my @headers = $fullhead ? sort $article->header_names : @DEFAULTHEAD;
  foreach my $header ( @headers ) {
    my $value = $self->html_markup($header, $article->header($header));
    push @return, "$value<br />" if $value;
  }
  my @body; 
  foreach ($article->body) { push @body, $self->html_clean($_) }
  push @return, join('', "<pre>", join("\n", @body), "</pre>");
  @return;
}

=head1 REQUIREMENTS

News::Overview, Net::NNTP, News::Article, News::Article::Response and
News::Article::Ref (both part of NewsLib), IO::File, CGI.pm, Date::Parse

=head1 SEE ALSO

B<News::Overview>, B<News::Web::CookieAuth>, B<News::Article::Ref>,
B<News::Article::Response>

=head1 NOTES

I'm not really done with this thing yet.  This is just something that
generally *works*, and has something resembling documentation.  I've got a
lot of work to do to make this what I really want to do, but I'm happy
with the start.

=head1 TODO

Still have a ways to go with stylesheets.

Should really use the Tr() type functions for making tables.

Various user interface improvements in html_article(), as well as backend
improvements.

$count should really offer the number of articles we asked for, no matter
what, rather than estimating things.  

mod_perl-ify this stuff.

It'd be nice if the documentation were a bit more transparent, enough so
that someone could recreate the actual gateway .cgi files without having
to refer to them.  

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
# v0.1 		Thu Sep 25 16:??:?? CDT 2003
### First working version.
# v0.2	
### Allows for arbitrary NNTP-like connections.
### Formatting in _subject() and _author() works more like it should
# v0.3
### We're still very far away from being releasable, but this version allows
### posting and is getting closer to set up in a reasoanable manner
### code-wide.
# v0.40b	Fri Oct 10 16:18:48 CDT 2003 
### Starting the proper commenting.  
# v0.50b	Sun Oct 12 16:05:05 CDT 2003 
### Changed html_overview() to do linkbacks to group/number pairs, instead
###   of the Message-ID directly
# v0.50.01	Mon Oct 13 17:32:30 CDT 2003 
### 'Articles in xxx:' weren't getting the group from the right place.  
# v0.50.02	Mon Oct 13 19:29:56 CDT 2003 
### Wasn't offering 'post a new article' if the group was empty.  Fixed.
# v0.50.03	Fri Nov 07 15:44:46 CST 2003 
### Gets information out of 'subscriptions' if there's no PATTERN passed
###   html_grouplist()
# v0.50.04	Sun Mar 28 23:52:23 CST 2004 
### Small fixes in printing article info in html_makearticle().
# v0.51		Thu Apr 22 14:12:31 CDT 2004 
### Code cleanup.
