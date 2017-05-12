# -*- Perl -*-
###########################################################################
# Written and maintained by Andrew Gierth <andrew@erlenstar.demon.co.uk>
# Thanks to Russ Allbery <rra@stanford.edu> for comment and significant
# contributions.
#
# Copyright 1997 Andrew Gierth. Redistribution terms at end of file.
#
# $Id: Article.pm 1.27 2002/08/11 22:51:38 andrew Exp $
#
# TODO:
#   - better way of handling the system-dependent configuration
#   - reformat source for 80 columns :-)
#
###########################################################################
#
# Envelope, n. The coffin of a document; the scabbard of a bill; the husk
#              of a remittance; the bed-gown of a love-letter.
#                                                         -- Ambrose Bierce
#

=head1 NAME

News::Article - Object for handling Usenet articles in mail or news form.

=head1 SYNOPSIS

  use News::Article;

See below for functions available.

=head1 DESCRIPTION

An object for representing a Usenet article (or a mail
message). Primarily written for use with mail2news and/or moderation
programs. (Not really intended for transit use.)

=head1 USAGE

  use News::Article;

Article exports nothing.

Article objects must be created with the I<new> method.

=cut

package News::Article;

use strict;
use SelfLoader;

use vars qw($VERSION @SENDMAIL %SPECIAL %UNIQUE);
use subs qw(canonical fix_envelope source_init);

($VERSION = (split (' ', q$Revision: 1.27 $ ))[1]) =~ s/\.(\d)$/.0$1/;

###########################################################################
# System-dependent configuration
#
# How to mail an article. The code assumes that this is a
# sendmail-workalike; i.e. can accept envelope recipients as arguments
# or -t to parse the headers for recipients. Also uses -f to set the
# envelope sender (this may cause problems on pre-V8 sendmails if
# used by an untrusted user).

@SENDMAIL = ((grep { -x $_ } 
	      qw(/usr/sbin/sendmail /usr/lib/sendmail /bin/false))[0],
	     qw(-oi -oem));

# End of system-dependent configuration
###########################################################################
# Constant data
#
# Words to treat specially when canonifying header names

%SPECIAL = map { lc $_ => $_ }
           qw(- _ ID PGP UIDL MIME NNTP SMTP IP URL HTTP WWW MimeOLE);

# RFC1036 (and news generally) is much less tolerant of multiple
# fields than RFC822. 822 allows for multiple message-ids, which is
# arguably seriously broken, so we ignore that. We list here only the
# most significant news fields; handling the rest sensibly is up to
# the caller.

%UNIQUE = map { $_ => 1 }
          qw(date followup-to from message-id newsgroups path reply-to
             subject sender);

# Description of internal storage:
#
# $self->{Headers}
#
#   A hash of header names to values. The value stored 
#   is always a reference to an array of values. The value stored
#   always includes embedded newlines and whitespace, but not the
#   header name or leading whitespace after the colon. There is no
#   trailing newline on the value.
#
# $self->{RawHeaders}
#
#   Array of headers as read from external source. One header per
#   element, with embedded newlines preserved (but trailing ones
#   removed).
#
# $self->{HeaderSeq}
#
#   Only set if headers have been read in; array of canonical header
#   names, in the order they were read in. Used to derive this from
#   RawHeaders, but that's wrong if read_headers has been called more
#   than once.
#
# $self->{Envelope}
#
#   Envelope From address. Set from a Unix-style "From " header on
#   read. When sending mail, the value here is used (unless undefined)
#   as the envelope sender.
#
# $self->{Body}
#
#   Array of text lines forming the body. Never contains embedded
#   newlines.
#
# $self->{Sendmail}
#
#   What to use to send mail.
#
# $self->{HdrsFirst}, $self->{HdrsEnd}, $self->{HdrsLast}
#
#   settings of headers_first, headers_next and headers_last
#

###########################################################################
# CONSTRUCTION
###########################################################################

=head2 Article Methods

=over 4

=item new ()

=item new ( SOURCE [,MAXSIZE [,MAXHEADS]] )

Use this to create a new Article object. Makes an empty article if no
parameters are specified, otherwise reads in an article from C<SOURCE>
as for C<read>.

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { 
	Headers    => {},
	RawHeaders => [],
	Envelope   => undef,
	Sendmail   => [ @SENDMAIL ],
	Body       => [],
    };
    bless $self,$class;

    if (@_) 
    {
	return undef unless defined ($_[0]);
	$self->read(@_) or return undef; 
    }

    $self;
}

# this shouldn't be needed. But SelfLoader tries to load it in derived
# modules if it's not found here, and those modules may not have __DATA__
# tokens, leading to rude error messages.

sub DESTROY {}

SelfLoader->load_stubs();

1;

__DATA__

#--------------------------------------------------------------------------

=item clone ()

Create a new Article as an exact clone of the current one.
Returns a ref to the new object.

=cut

sub clone
{
    my $src = shift;
    my $class = ref($src);
    my $headers = {};
    my $obj = {
	Headers    => $headers,
	RawHeaders => [ @{$src->{RawHeaders}} ],
	HeaderSeq  => [ defined($src->{HeaderSeq}) ? @{$src->{HeaderSeq}} : () ],
	Envelope   => $src->{Envelope},
	Sendmail   => [ @{$src->{Sendmail}} ],
	Body       => [ @{$src->{Body}} ],
    };

    # must deep-copy the headers hash elements, otherwise they
    # get shared with rather messy results.

    for (keys %{$src->{Headers}})
    {
	$headers->{$_} = [ @{$src->{Headers}{$_}} ];
    }

    # copy default header sequence info too

    for (qw(HdrsFirst HdrsEnd HdrsLast))
    {
	$obj->{$_} = [ @{$src->{$_}} ] if defined($src->{$_});
    }

    return bless $obj,$class;
}

###########################################################################
# HEADER MANIPULATION
###########################################################################

=item envelope ( [SENDER] )

If C<SENDER> is specified, sets the envelope sender to the specified
value (which will then subsequently be used if the article is mailed).
Returns the (new or current) envelope sender in any case.

=cut

sub envelope
{
    my $self = shift;
    return $self->{Envelope} = shift if (@_);
    $self->{Envelope};
}

#--------------------------------------------------------------------------

=item rawheaders ()

Returns a list (or a reference to an array if in scalar context) of
the original header lines of the article, as read from the input
source. Terminating newlines are not included. (Continued headers are
returned as single strings with embedded newlines.)

=cut

sub rawheaders
{
    my $self = shift;
    wantarray ? @{$self->{RawHeaders}} : $self->{RawHeaders};
}

#--------------------------------------------------------------------------

=item header_names ()

Returns a list of the names of all headers currently present
in the article.

=cut

sub header_names
{
    my $self = shift;
    keys %{$self->{Headers}};
}

#--------------------------------------------------------------------------

=item headers ([FIRST [,NEXT [,LAST]]])

Returns a list of all header strings with no terminating
newlines. Continued headers will have embedded newlines.

FIRST, NEXT and LAST are optional references to arrays of header
names. The order of the returned headers is as follows:

 - headers specified by FIRST (one value only per name)
 - headers in the order originally read in (if any)
 - headers specified by NEXT (one value only per name)
 - any remaining headers not named in LAST, sorted by name
 - headers named in LAST (all values)

LAST overrides the original order of headers, but NEXT does not.
Headers named in LAST will also be grouped together by header name.

=cut

sub headers
{
    my $self = shift;
    my $hdrs = $self->{Headers};
    my @preseq = map { canonical $_ } @{shift || $self->{HdrsFirst} || []};
    my @addseq = map { canonical $_ } @{shift || $self->{HdrsEnd} || []};
    my @postseq = map { canonical $_ } @{shift || $self->{HdrsLast} || []};
    my %postseq = map { $_ => 1 } @postseq;

    # this hash gets all the headers in the form that we will use to
    # output them. Each value is an array of strings of the form
    # "Header-Name: value". The keys are in canonical rather than
    # internal form.
    my %tmph = map { my $h = canonical($_);
		     ($h, [ map { $h.": ".$_ } @{$hdrs->{$_}} ])
		     } keys %$hdrs;

    # original sequence of headers (if any) excluding those we wish
    # to force to the end.
    my @seq = grep { !$postseq{$_} } @{$self->{HeaderSeq} || []};

    # build the required list
    ((map { my $v = $tmph{$_}; $v && @$v ? shift(@$v) : (); } @preseq),
     (map { my $v = $tmph{$_}; $v && @$v ? shift(@$v) : (); } @seq),
     (map { my $v = $tmph{$_}; $v && @$v ? shift(@$v) : (); } @addseq),
     (map { my $v = $tmph{$_}; $v && @$v ? (@{$tmph{$_}}) : () }
          sort grep { !$postseq{$_} } keys %tmph),
     (map { my $v = $tmph{$_}; $v && @$v ? (@{$tmph{$_}}) : () } @postseq));
}

# the above is admittedly somewhat hairy.

#sub headers
#{
#    my $headers = $_[0]{Headers};
#    map {
#	my $header = canonical($_);
#	map { $header.": ".$_ } @{$headers->{$_}};
#    } keys %$headers;
#}

=item headers_first (HDR...)

Set default ordering for headers().

=cut

sub headers_first
{
    shift->{HdrsFirst} = [ @_ ];
}

=item headers_next (HDR...)

Set default ordering for headers().

=cut

sub headers_next
{
    shift->{HdrsEnd} = [ @_ ];
}

=item headers_last (HDR...)

Set default ordering for headers().

=cut

sub headers_last
{
    shift->{HdrsLast} = [ @_ ];
}

#--------------------------------------------------------------------------

=item set_headers ( NAME, VALUE [, NAME, VALUE [...]] )

For each header name supplied, replace any current occurences of the
header with the specified value(s). Each value may be a single scalar,
or a reference to an array of values. Returns undef without completing
the assignments if any attempt is made to supply multiple values for a
unique header. Undef or empty values cause the header to be deleted.
(If an array is supplied, it is not copied. This is probably a mistake
and should not be relied on.)

=cut

sub set_headers
{
    my $self = shift;

    while (@_)
    {
	my $name = lc shift;
	my $val = shift;

	delete $self->{Headers}{$name} and next
	    if !defined($val) || (ref($val) && @$val < 1);

	$val = [ $val ] unless ref($val);

	return undef if $UNIQUE{$name} && @$val > 1;

	$self->{Headers}{$name} = $val;
    }

    1;
}

#--------------------------------------------------------------------------

=item add_headers ( NAME, VALUE [, NAME, VALUE [...]] )

Add new header values without affecting existing ones. Each value is
either a single scalar, or a reference to an array of values. Returns
undef without completing if any attempt is made to supply duplicate
values for a unique header. (If an array reference is supplied, the
array is copied.)

=cut

sub add_headers
{
    my $self = shift;

    while (@_)
    {
	my $name = lc shift;
	my $val = shift;
	next unless defined($val);

	$val = [ $val ] unless ref($val);
	my $curval = \@{$self->{Headers}{$name}};     # magic

	return undef if ($UNIQUE{$name} && (@$val + @$curval > 1));

	push @$curval,@$val;
    }
}

# explanation of 'magic': $curval gets a reference to an array which
# is also referred to by $self->{Headers}{$name} - *even* if there was
# no previous value for $self->{Headers}{$name} (if necessary, a new
# anon array springs into existence)

#--------------------------------------------------------------------------

=item drop_headers ( NAME [, NAME [...]] )

Delete all values of the specified header(s).

=cut

sub drop_headers
{
    my $self = shift;
    for (@_)
    {
	delete $self->{Headers}{lc $_};
    }
}

#--------------------------------------------------------------------------

=item header ( NAME )

Returns a list of values for the specified header. Returns a null list
if the header does not exist. In scalar context, returns the first
value found or undef.

=cut

sub header
{
    my $self = shift;
    my $name = lc shift;
    my $val = $self->{Headers}{$name};

    return defined($val) ? @$val : () if wantarray;
    return $val->[0];
}

#--------------------------------------------------------------------------

=item rename_header ( SRC, DEST [, ACTION] )

Transform the name of a header without touching the value. Fails
if the source header does not exist. Returns undef on failure,
true on success.

Optional ACTION (may be "drop", "clobber", "add", or "fail"
(default)), specifies what to do if both source and destination exist:

  ACTION     PREVIOUS DEST
  drop       unchanged      (SRC dropped)
  clobber    dropped        (SRC replaces DEST)
  add        preserved      (SRC added to DEST)
  fail       unchanged      (operation fails)

=cut

sub rename_header
{
    my $self = shift;
    my $oldname = lc shift;
    my $newname = lc shift;
    my $action = shift || 'fail';

    return undef unless exists($self->{Headers}{$oldname});

    if (exists($self->{Headers}{$newname}))
    {
	return undef if $action eq 'fail';
    }
    else
    {
	$action = 'clobber';
    }

    my $oldval = delete $self->{Headers}{$oldname};

    if    ($action eq 'clobber') { $self->{Headers}{$newname} = $oldval; }
    elsif ($action eq 'add')     { $self->add_headers($newname, $oldval); }

    1;
}

###########################################################################
# ARTICLE BODY
###########################################################################

=item body ()

Return the body of the article as a list of lines (no newlines),
or a reference to an array in scalar context (the array may be
modified in this case).

=cut

sub body
{
    wantarray ? @{$_[0]->{Body}} : $_[0]->{Body};
}

#--------------------------------------------------------------------------

=item lines ()

Returns the number of lines in the article body.

=cut

sub lines
{
    my $self = shift;
    scalar(@{$self->{Body}});
}

#--------------------------------------------------------------------------

=item bytes ()

Returns the total size of the article body, not counting newlines.

=cut

sub bytes
{
    my $self = shift;
    my $total = 0;
    for (@{$self->{Body}})
    {
	$total += length($_);
    }
    $total;
}

#--------------------------------------------------------------------------

=item set_body ( BODY )

Replace the current article body with the specified text.  Expects a
list, each item of which is either one line, or multiple lines
separated by newlines. (Trailing newlines on the values are ignored.)

=cut

sub set_body
{
    my $self = shift;
    $self->{Body} = [];
    $self->add_body(@_);
}

#--------------------------------------------------------------------------

=item add_body ( BODY )

Append the specified text to the current article body.  Expects a
list, each item of which is either one line, or multiple lines
separated by newlines, or a reference to an array of lines. (Trailing
newlines on the values are ignored.)

=cut

sub add_body
{
    my $self = shift;
    my $body = $self->{Body};

    for (@_)
    {
	if (ref($_))
	{
	    $self->add_body(@$_);
	}
	else 
	{
	    my @lines = split(/\n/);
	    push @$body,@lines ? @lines : "";
	}
    }
}

#--------------------------------------------------------------------------

=item trim_blank_lines ()

Remove any trailing blank lines from the article body. Returns the
number of lines removed.

=cut

sub trim_blank_lines
{
    my $body = shift->{Body};
    my $n = 0;
    while (@$body && $body->[$#$body] =~ /^\s*$/) { pop @$body; ++$n; }
    return $n;
}

###########################################################################
# INPUT FUNCTIONS
###########################################################################

=item read_headers ( SOURCE, MAXSIZE )

Read article headers (terminated by an empty line) from the specified
source (see C<read> for defintion of allowed sources).

Gives up (returning undef) if more than MAXSIZE bytes are read. Returns
the amount read.

=cut

sub read_headers
{
    my ($self, $source, $maxsz) = @_;
    my $last = undef;
    my $first = 1;
    my $hhead = {};
    my $name;
    my $val;
    my $size = 0;

    # Nuke the body and hashed headers - always.

    $self->{Body} = [];
    $self->{Headers} = $hhead;

    my $hseq = $self->{HeaderSeq} = [];

    # If we have read some raw headers already, append a marker.  This
    # is partly to cope with C-news/ANU-news moderator mail, where the
    # news article is encapsulated in a mail message rather than
    # simply mailed, but we don't want to lose the mail path.

    my $head = $self->{RawHeaders};
    push @$head,"X-More-Headers: ----" if @$head;

    # Set up the data source.

    $source = source_init($source);
    return undef unless defined($source);

    my $line;

    while (defined($line = &$source()))
    {
	# size limit

	return undef if ($size += length($line)) > $maxsz;

	chomp $line;
	last if $line eq '';

	for (split(/\n/,$line))
	{
	    # lines of whitespace only are allowed in continuations - but
	    # we drop them as they serve no useful purpose
	    # XXX - what about signatures? not an issue for pgpmoose or
	    #       signcontrol, neither of which allow continuations in
	    #       signed headers at all, but could become an issue in the
	    #       future - in which case this behaviour would have to be
	    #       removed
	    next if /^\s*$/;

	    # Envelope From (unix-style). Must be the first line, and we trim
	    # off the timestamp if present

	    if (!$last && /^From (.*)$/)
	    {
		$self->{Envelope} = fix_envelope($1);
		next;
	    }

	    # Ignore bogus extra >From lines (procmail has a bad habit of adding
	    # these, unpredictably, unless you recompile it to trust everybody)
	    next if /^>From /;

	    # continuation line? If so, append to most recent data
	    if (/^\s/)
	    {
		if (ref($last))
		{
		    $head->[$#$head] .= "\n".$_;
		    $last->[$#$last] .= "\n".$_;
		}
		next;
	    }

	    # Extract header name and value. If the name looks
	    # unreasonable, hack around it to make the problem easily
	    # visible. We are deliberately over-strict in the allowed
	    # format of names (the RFCs allow any printable ASCII char
	    # other than whitespace or ':' in header names, but in
	    # practice only alphanumerics, '-' and (rarely) '_' are
	    # found). We lose any superfluous whitespace after the ':'
	    # here (only likely to be noticable for Subject lines).
	    
	    if (/^([\w-]+):\s+(.*)$/)
	    {
		$val = $2;
		$name = lc $1;
	    }
	    else
	    {
		$val = $_;
		$name = "x-broken-header";
	    }
	    
	    # Tack raw header onto array of raw headers

	    push @$hseq,canonical($name);
	    push @$head,$_;
	    
	    # Add header to hash. Roughly equivalent to add_header, but
	    # handles duplicate unique headers silently

	    $last = \@{$hhead->{$name}};
	    push @$last,$val unless $UNIQUE{$name} && @$last;
	}
    }

    $size;
}   

#--------------------------------------------------------------------------

=item read_body ( SOURCE, MAXSIZE )

Read an article body from the specified source (see C<read>). Stops at
end of file; fails (returning undef) if MAXSIZE is reached prior to
that point.  Returns the number of bytes read (may be 0 if the body is
null).

Trailing blank lines are NOT removed (an incompatible, but regrettably
necessary, change from previous versions); see trim_blank_lines if you
need to do that.

=cut
	
sub read_body
{
    my ($self, $source, $maxsize) = @_;
    my $size = 0;

    # Set up the data source.

    $source = source_init($source);
    return undef unless defined($source);

    my $body = $self->{Body} = [];
    my $line;

    while (defined($line = &$source()))
    {
	return undef if ($size += length($line)) > $maxsize;
	chomp $line;
	push @$body,"" unless $line;

	for (split(/\n/,$line,-1))
	{
	    push @$body,$_;
	}
    }

    # return the article size
    $size;
}

#--------------------------------------------------------------------------

=item read ( SOURCE [,MAXSIZE [,MAXHEADS]] )

Reads in an article from C<SOURCE>.

C<SOURCE> may be any of the following:

- a CODE ref, which is called to return lines or chunks of data

- an ARRAY ref, assumed to contain a list of lines with optional
line terminators

- a SCALAR ref, assumed to contain text with embedded newlines

- a scalar, assumed to be a filename, which is opened and read

- anything else is assumed to be a glob, reference to a glob,
or reference to a filehandle, and is read from accordingly

When reading in articles, C<MAXHEADS> is the maximum header size to
read (default 8k), and C<MAXSIZE> is the maximum article body size
(default 256k). If C<MAXSIZE> is explicitly specified as 0, then no
attempt at reading the body is made. Returns the total number of bytes
read, or undef if either limit is reached or no headers were found.

=cut

sub read
{
    my ($self, $source, $maxsize, $maxhead) = @_;
    my $hsize = 0;
    my $bsize = 0;

    $maxhead = 8192 unless $maxhead;
    $maxsize = 262144 unless defined($maxsize);

    # Set up the data source.

    $source = source_init($source);
    return undef unless defined($source);

    $hsize = $self->read_headers($source,$maxhead)
	or return undef;

    if ($maxsize)
    {
	$bsize = $self->read_body($source,$maxsize);
	return undef unless defined($bsize);
    }

    $hsize + $bsize;
}

###########################################################################
# OUTPUT FUNCTIONS
###########################################################################

=item write ( FILE )

Write the entire article to the specified filehandle reference.

=cut

sub write
{
    my ($self, $fh) = @_;
    print $fh join("\n", $self->headers(), "", @{$self->{Body}}, "");
}

=item write_unique_file ( DIR [,MODE] )

Write the article to a (hopefully) uniquely-named file in the
specified directory.  The file is written under a temporary name (with
a leading period) and relinked when complete. Returns 1 if successful,
otherwise undef.

MODE is the access mode to use for the created file (default 644);
this will be modified in turn by the current umask.

The implementation is careful to avoid losing the file or clobbering
existing files even in the case of a name collision, but relies on
POSIX link() semantics and may fail on lesser operating systems
(or buggy NFS implementations).

=cut

sub write_unique_file;

use POSIX qw(:errno_h);
use Fcntl;
use FileHandle ();

; sub write_unique_file
{
    my ($self, $dir, $mode) = @_;

    return undef unless defined($dir) and length($dir);
    $mode = 0644 unless defined($mode);

    my ($name,$tname,$fh);

    do 
    {
	$tname = $name = $self->_unique_name();
	$tname =~ s/^././;
	$fh = FileHandle->new("$dir/$tname", O_CREAT|O_EXCL|O_WRONLY, $mode);
    } 
    while (!$fh && $! == &EEXIST);
    return undef unless $fh;

    my $success;

    if ($self->write($fh) && $fh->close())
    {
	while (!link("$dir/$tname","$dir/$name") && $! == &EEXIST)
	{
	    $name = $self->_unique_name();
	}
	$success = 1;
    }

    unlink("$dir/$tname");
    return $success;
}

#--------------------------------------------------------------------------

=item write_original ( FILE )

Write the original headers followed by the article body to the
specified filehandle reference.

=cut

sub write_original
{
    my ($self, $fh) = @_;
    print $fh join("\n", @{$self->{RawHeaders}}, "", @{$self->{Body}}, "");
}

###########################################################################
# MAIL FUNCTIONS
###########################################################################

=item sendmail ( [COMMAND] )

Get or set the command and options that will be used to mail the
article. Defaults to a system dependent value such as
  /usr/sbin/sendmail -oi -oem

=cut

sub sendmail
{
    my $self = shift;
    $self->{Sendmail} = [ @_ ] if (@_);
    @{$self->{Sendmail}};
}

#--------------------------------------------------------------------------

=item mail ( [RECIPIENTS...] )

Mails the article to the specified list of recipients, or to the
addressed recipients in the header (To, Cc, Bcc) if none are supplied.
Attempts to set the envelope sender to the stored envelope sender, if
set, so unset that before mailing if you do not want this behavior.

=cut

sub mail;

use FileHandle ();
use IPC::Open3 qw(open3);

; sub mail 
{
    my ($self, @recipients) = @_;
    my @command = @{$self->{Sendmail}};
    push @command,'-f',$self->{Envelope} if (defined($self->{Envelope}));
    push @command, @recipients ? @recipients : '-t';

    my $sendmail = FileHandle->new();
    my $errors = FileHandle->new();

    eval { open3 ($sendmail, $errors, $errors, @command) };
    if ($@) { return undef }

    local $SIG{PIPE} = 'IGNORE';

    $self->write($sendmail);
    close $sendmail;

    # Check the return status of sendmail to see if we were successful.
    $? == 0;
}

###########################################################################
# NEWS FUNCTIONS
###########################################################################

=item post ( [CONN] )

Post the article. Avoids inews due to undesirable header munging and
unwarranted complaints to stderr. Takes an optional parameter which is
a Net::NNTP reference.  If supplied, posts the article to it;
otherwise opens a new reader connection and posts to that.

Throws an exception containing the error message on failure.

=cut

sub post;

use Net::NNTP ();

; sub post
{
    my $self = shift;
    my $server = shift;

    if (!$server)
    {
	$server = Net::NNTP->new();
	die "Unable to connect to server" unless $server;
	$server->reader();
    }

    $server->post(join("\n", $self->headers(), "", @{$self->{Body}}))
	or die $server->code().' '.($server->message())[-1];

    1;
}

=item ihave ( [CONN] )

Inject the article. Takes an optional parameter which is a Net::NNTP
reference.  If supplied, posts the article to it; otherwise opens a
new transport connection and posts to that. All required headers must
already be present, including Path and Message-ID.

Throws an exception containing the error message on failure.

=cut

sub ihave;

use Net::NNTP ();

; sub ihave
{
    my $self = shift;
    my $server = shift;

    my $msgid = $self->header('message-id');
    die "Article contains no message-id" unless $msgid;

    if (!$server)
    {
	$server = Net::NNTP->new();
	die "Unable to connect to server" unless $server;
    }

    $server->ihave($msgid, join("\n", $self->headers(), "", @{$self->{Body}}))
	or die $server->code().' '.($server->message())[-1];

    1;
}

#--------------------------------------------------------------------------

=item add_message_id ( [PREFIX [, DOMAIN] ] )

If the current article lacks a message-id, then create one.

=cut

sub add_message_id;

use Net::Domain qw(hostfqdn);

; sub add_message_id
{
    my $self = shift;
    return undef if $self->{Headers}{'message-id'};

    my $prefix = shift || '';
    my $domain = shift || hostfqdn() || 'broken-configuration';
    my ($sec,$min,$hr,$mday,$mon,$year) = gmtime(time);
    ++$mon;
    $self->set_headers('message-id', 
		       sprintf('<%s%04d%02d%02d%02d%02d%02d$%04x@%s>',
			       $prefix, 
			       $year+1900, $mon, $mday, $hr, $min, $sec,
			       0xFFFF & (rand(32768) ^ $$), $domain));
}

#--------------------------------------------------------------------------

=item add_date ( [TIME] )

If the current article lacks a date, then add one (in local time).
If TIME is specified (numerical Unix time), it is used instead of the
current time.

=cut

sub add_date
{
    my $self = shift;
    return undef if $self->{Headers}{'date'};

    my $now = shift || time;
    my ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($now);
    my ($gsec,$gmin,$ghr,$gmday) = gmtime($now);

    # mystic incantations to calculate zone offset from difference
    # between UTC and local time. Assumes that difference is not more
    # than a full day (saves having to take months into consideration).
    # ANSI is apparently going to add a spec to strftime() to do this,
    # but that isn't yet commonly available.

    use integer;
    $gmday = $mday + ($mday <=> $gmday) if (abs($mday-$gmday) > 1);
    my $tzdiff = 24*60*($mday-$gmday) + 60*($hr-$ghr) + ($min-$gmin);
    my $tz = sprintf("%+04.4d", $tzdiff + ($tzdiff/60*40));

    $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
    $wday = (qw(Sun Mon Tue Wed Thu Fri Sat Sun))[$wday];
    $year += 1900;
    $self->set_headers('date',
		       sprintf("%s, %02d %s %d %02d:%02d:%02d %s",
			       $wday,$mday,$mon,$year,$hr,$min,$sec,$tz));
}
   

###########################################################################
# AUTHENTICATION FUNCTIONS
###########################################################################

# Internal function used by PGPMoose sign/verify code

sub pgpmoose_canon_headers
{
    my ($self, $bug_compatible) = @_;

    # Now, put together all of the stuff we need to sign.  First, we need a
    # list of newsgroups, sorted.

    my $headers = $self->header('newsgroups');
    $headers =~ s/\s//g;
    $headers = join("\n", (sort split(/,+/, $headers)), '');

    # Next we need an array of headers: From, Subject, and Message-ID in
    # that order, killing initial and final whitespace and any spaces after
    # colons.
    # PGPMoose V1.1 has a gross bug: it includes, as though they were headers,
    # any body lines that look like headers. Do this only if $bug_compatible

    my %heads = map { ($_, [ $self->header($_) ]) } qw(from subject message-id);

    if ($bug_compatible)
    {
	for (@{$self->{Body}})
	{
	    /^from: *(.*)$/i && push @{$heads{from}},$1;
	    /^subject: *(.*)$/i && push @{$heads{subject}},$1;
	    /^message-id: *(.*)$/i && push @{$heads{'message-id'}},$1;
	}
    }

    for (@heads{'from','subject','message-id'})
    {
	for (@$_)
	{
	    s/\n.*//;
	    s/^ +//;
	    s/\s*$/\n/;
	    s/: +/:/g;
	    $headers .= $_;
	}
    }

    $headers;
}

=item sign_pgpmoose ( GROUP, PASSPHRASE [, KEYID] )

Signs the article according to the PGPMoose spec.  We require that pgp be
on the path to do this.  Takes a "group" which can be either a newsgroup
or an address, a PGP password, and an optional key id and returns a null
list on success, the PGP error output as a list on failure.

If the key id is omitted, we will assume that if the group is an e-mail
address, the key id is that address surrounded by <>, and otherwise the
key id will be the group with a space on either side.  This is so that one
can help PGP distinguish between the keys for (say) mod.config and
mod.config.status.  The PGP key id should be something like:

  Moderator of group.name <request-address@some.host>

The article to be signed must already have all of the headers needed by
PGPMoose (Newsgroups, From, Subject) or this will fail. Message-ID is
added if necessary.

=cut

sub sign_pgpmoose;

use PGP::Sign qw(pgp_sign pgp_verify pgp_error);

; sub sign_pgpmoose 
{
    my ($self, $group, $passphrase, $keyid) = @_;

    # If we don't have a key id, try to generate one from the group.
    # Surround it by angle brackets if it's an e-mail address or by spaces
    # if it's a group.

    $keyid = ($group =~ /\@/) ? "<$group>" : " $group "
	unless (defined $keyid);

    # Check to make sure we have the required headers.
    for (qw(newsgroups from subject)) 
    {
        return ("Required header $_ missing")
	    unless $self->{Headers}{$_};
    }

    $self->add_message_id() unless $self->{Headers}{'message-id'};

    # Now, put together all of the stuff we need to sign.
    # XXX generate V1.1 bug-compatible version for now.

    my $headers = $self->pgpmoose_canon_headers(1);

    # Finally, we need to give it the body of the article, making the
    # following transformations:
    #
    #  - Lines consisting solely of spaces are deleted.
    #  - A leading "--" is replaced by "- --"
    #  - A leading "from" (case-insensitive) has > prepended.
    #  - A leading "subject" (case-insensitive) has > prepended.
    #  - A leading single "." is changed to "..".
    #  - All trailing whitespace on a line is removed.
    #
    # The easy way to do this is to define an anonymous sub that sends back
    # a line at a time.  That way, we don't end up wasting memory by storing
    # two copies of the article body (which could potentially be long).
    my $body;
    {
        my $line = 0;
        $body = sub {
            my $text;
            do 
	    {
                $text = $self->{Body}[$line++];
                return undef unless defined $text;
            } while ($text =~ /^ *$/);
            $text =~ s/^--/- --/;
            $text =~ s/^(from|subject)/>$1/i;
            $text =~ s/^\.($|[^.])/..$1/;
            $text =~ s/\s+$//;
            $text . "\n";
        }
    }

    # Now, actually calculate the signature and add it to the headers.
    my $signature = pgp_sign ($keyid, $passphrase, $headers, $body);
    return pgp_error
	unless defined($signature);

    $signature =~ s/\n(.)/\n\t$1/g;
    $self->add_headers('x-auth', "PGPMoose V1.1 PGP $group\n\t$signature");
    return ();
}

#--------------------------------------------------------------------------

=item verify_pgpmoose ( GROUP )

Verifies an article signature according to the PGPMoose spec.  We
require that pgp be on the path to do this.  Takes a "group" which can
be either a newsgroup or an address, and an optional key id.

Looks for a X-Auth header matching the specified group or address, and
if found, checks the validity of the signature. If successful, returns
the signer identity (from the PGP output), otherwise returns false.

=cut

sub verify_pgpmoose;

use PGP::Sign qw(pgp_sign pgp_verify pgp_error);

; sub verify_pgpmoose 
{
    my ($self, $group, $keyid) = @_;

    my $sig = (grep(/^ PGPMoose \s+ V\d\.\d \s+ PGP \s+ \Q$group\E \n /isx,
		      $self->header('x-auth')))[0];

    return undef unless $sig;

    my ($ver) = $sig =~ /^ PGPMoose \s+ V(\d\.\d) \s+/isx;

    $sig =~ s/[^\n]*\n//;
    $sig =~ s/\t//g;

    # Now, put together all of the stuff we need to sign.
    # XXX Optimistically, assume that pmcanon will be fixed after 1.1.

    my $headers = $self->pgpmoose_canon_headers($ver eq '1.1');

    # Finally, we need to give it the body of the article, making the
    # following transformations:
    #
    #  - Lines consisting solely of spaces are deleted.
    #  - A leading "--" is replaced by "- --"
    #  - A leading "from" (case-insensitive) has > prepended.
    #  - A leading "subject" (case-insensitive) has > prepended.
    #  - A leading single "." is changed to "..".
    #  - All trailing whitespace on a line is removed.
    #
    # The easy way to do this is to define an anonymous sub that sends back
    # a line at a time.  That way, we don't end up wasting memory by storing
    # two copies of the article body (which could potentially be long).
    my $body;
    {
        my $line = 0;
        $body = sub {
            my $text;
            do 
	    {
                $text = $self->{Body}[$line++];
                return undef unless defined $text;
            } while ($text =~ /^ *$/);
            $text =~ s/^--/- --/;
            $text =~ s/^(from|subject)/>$1/i;
            $text =~ s/^\.($|[^.])/..$1/;
            $text =~ s/\s+$//;
            $text . "\n";
        }
    }

    pgp_verify ($sig, undef, $headers, $body);
}

#--------------------------------------------------------------------------

=item sign_control ( KEYID, PASSPHRASE [, HEADER [...] ] )

Signs the article in the manner used for control messages.  This is
derived from signcontrol, written by David Lawrence, but with fewer sanity
checks since we assume people know what they're doing.  Caveat programmer.

We take a key id, a PGP password, and an optional list of extra
headers to add to the signature.  By default, Subject, Control,
Message-ID, Date, From, and Sender are signed. Any signed header that
isn't present in the article will be signed with an empty value. Date
and Message-ID are automatically added if needed.

=cut

sub sign_control;

use PGP::Sign qw(pgp_sign pgp_verify pgp_error);

; sub sign_control 
{
    my ($self, $keyid, $passphrase, @extra) = @_;
    my @headers = qw(subject control message-id date from sender);
    push @headers, map {lc $_} @extra;

    # Check to make sure we have the required headers.
    for (qw(subject control from))
    {
        return ("Required header $_ missing")
	    unless $self->{Headers}{$_};
    }

    $self->add_message_id('cmsg-') unless $self->{Headers}{'message-id'};
    $self->add_date();

    # We have to sign the list of headers and each header on a seperate
    # line.  Note that the verification code doesn't support continuation
    # headers, so be careful not to use them when calling this method.

    my $signheads = join (',', map { canonical $_ } @headers);
    my @sign;
    push (@sign, 'X-Signed-Headers: ' . $signheads . "\n");
    for (@headers) 
    {
        push (@sign, (canonical $_).": ".($self->header($_) || '')."\n");
    }

    # Now send everything to PGP to sign.  We have to add a new line to the
    # end of every line of the body, since we're storing it without them.
    # Make sure we munge for attached signatures, since pgpverify tests with
    # an attached signature.
    local $PGP::Sign::MUNGE = 1;
    my $body;
    {
        my $line = 0;
        $body = sub {
            my $text = $self->{Body}[$line++];
            defined $text ? $text . "\n" : undef;
        }
    }
    my ($signature, $version) =
        pgp_sign ($keyid, $passphrase, \@sign, "\n", $body);
    return pgp_error
	unless defined($signature);

    # Add tabs after the newlines and add the signature to the headers.
    $signature =~ s/\n(.)/\n\t$1/g;

    # Fix up version field (needed for at least PGP 6.5.1i)
    $version =~ s/^[PGpg]+\s+//;   # remove initial PGP or GPG or whatever
    $version =~ s/\s+/_/g;         # convert any remaining whitespace

    $self->add_headers('x-pgp-sig', "$version $signheads\n\t$signature");
    return ();
}

###########################################################################
# INTERNAL METHODS
###########################################################################

# Unique name generator for write_unique_file. This is called as a method
# to allow it to be overridden (should anyone want to). The implementation
# specifically takes account of the possibility of multiple calls in quick
# succession from the same process (and possibly different objects, which
# is why $unique_count is not an instance variable).

sub _unique_name;

my $unique_count = "aa";

; sub _unique_name
{
    my $name = sprintf("%08x%04x%2s",
		       time & 0xffffffff,
		       $$ & 0xffff,
		       $unique_count);
    $unique_count = "aa" if (length(++$unique_count) > 2);
    return $name;
}

###########################################################################
# INTERNAL FUNCTIONS
###########################################################################

# really ought to convert some of these to methods.

# Convert a header name to canonical capitalisation. We keep the header
# names in lowercase internally to simplify, but prefer to emit standard-
# looking forms on output.

sub canonical
{
    my $name = lc shift;
    join('',map { ($SPECIAL{$_} || ucfirst $_); } split(/([_-])/,$name));
}

# Fix up an envelope sender taken from a Unix-style "From" line.

# This isn't guaranteed to work due to variations in From line
# format. An explicit decision has been made to trust the
# header format *rather than* the sanity of the envelope
# address, because we have no control over the latter, whereas
# the former is generated by local software and therefore
# should be fixable if it is too insane.

# Theory:
#   If there's a timestamp (check for MMM DDD NN HH:MM) then remove
#   it and everything following it. Otherwise remove any trailing
#   text resembling 'remote from ...'.
#   Then remove trailing spaces from the result and return it.

sub fix_envelope
{
    my $from = shift;

    $from =~ s/\s \w\w\w \s \w\w\w \s [\d\s]\d \s \d\d:\d\d(:\d\d)? \s .*? $//x
	or $from =~ s/\s remote \s from \s .* $//x;

    $from =~ s/\s+$//;

    return $from;
}

# Initialise a data source; returns a CODE ref with which to
# read from that source.
#
# Allowed sources are:
#  GLOBs or unknown refs are assumed to be filehandles or equivalent.
#  ARRAY refs (treated as a list of lines)
#  SCALAR refs (treated as text)
#  SCALARs (treated as filenames)
#  CODE refs are left unchanged

sub source_init_filehandle;

use FileHandle ();

; sub source_init_filehandle
{
    return FileHandle->new(shift);
}

sub source_init
{
    my $source = shift;

    if (ref(\$source) ne 'GLOB')
    {
	return $source if (ref($source) eq 'CODE');
    
	if (ref($source) eq 'ARRAY')
	{
	    my $index = 0;
	    return sub { $source->[$index++] };
	}

	if (ref($source) eq 'SCALAR')
	{
	    my $pos = 0;
	    return sub { return undef unless $pos < length($$source);
			 my $tmp = $pos;
			 $pos = 1 + index($$source,"\n",$tmp);
			 if ($pos <= $tmp)
			 {
			     $pos = 1 + length($$source);
			     return substr($$source,$tmp);
			 }
			 else
			 {
			     return substr($$source,$tmp,($pos - $tmp));
			 }
		     };
	}
    
	if (!ref($source))
	{
	    $source = source_init_filehandle("<$source");
	    return undef unless $source;
	}
    }

    return sub { scalar(<$source>) };
}

###########################################################################
# THE END
###########################################################################

1;

__END__

###########################################################################

=head1 CAVEATS

This module is not fully transparent. In particular:

=over 4

=item -

Case of headers is smashed

=item -

improper duplicate headers may be discarded

=item -

Broken or dubious header names are not preserved

=back

These factors make it undesirable to use this module in news transit
applications.

=head1 AUTHOR

Written by Andrew Gierth <andrew@erlenstar.demon.co.uk>

Thanks to Russ Allbery <rra@stanford.edu> for comments and
suggestions.

=head1 COPYRIGHT

Copyright 1997-2002 Andrew Gierth <andrew@erlenstar.demon.co.uk>

This code may be used and/or distributed under the same terms as Perl
itself.

=cut

###########################################################################
#
# Random Comments
#
# Consistency: I'd like to drop the use of FileHandle in favour of the
# IO::* modules, but I don't want to completely break with 5.003 at this
# stage (though I no longer test with 5.003, so there is no guarantee that
# it works at all).
#
# Use of $_; at present, I'm confining it to for() and map{} / grep{}
# constructs (where it is implicitly localised).
#
# SelfLoader: the use of funky indenting to do deferred 'use' statements
# and other compile-time stuff seems to me to be over-kludgy. It's merely
# an artifact of SelfLoader's fairly simplistic method of locating the
# start and end of each function.
#
# Net::Domain seems to do poorly on BSD systems without permanent 
# connectivity (hangs in domainname() doing unnecessary DNS lookups).
# Must take that up with the maintainer at some stage if it hasn't 
# already been fixed.
#
# indirect-object vs. method call syntax for ctors: I still can't decide
# which I prefer. I've removed all the IO ones for now.
#
#

###########################################################################
#
# $Log: Article.pm $
# Revision 1.27  2002/08/11 22:51:38  andrew
# no changes, other than copyright date, this is just to bumb the version no.
#
# Revision 1.26  2001/11/08 14:11:43  andrew
# remove stray spaces from unique filenames
#
# Revision 1.25  2001/04/20 12:11:31  andrew
# handle PGP versions that put spaces in the version field, in sign_control
#
# Revision 1.24  2001/01/18 09:48:44  andrew
# work around a SelfLoader issue.
# Allow $obj->new() to work as well as CLASS->new()
#
# Revision 1.23  2000/04/14 15:11:49  andrew
# handle newlines in body better
#
# Revision 1.22  2000/04/02 12:02:27  andrew
# add parameter to add_date
#
# Revision 1.21  1998/10/21 03:15:31  andrew
# Doc tweaks and minor cleanup.
# Improvements to write_unique_file to handle collisions.
#
# Revision 1.20  1998/10/18 06:01:00  andrew
# Speedup to source_init when FileHandle is not required
#
# Revision 1.19  1998/10/18 05:41:32  andrew
# Added write_unique_file
#
# Revision 1.18  1998/10/18 03:42:19  andrew
# read_body no longer strips blank lines.
# trim_blank_lines added to compensate.
# Added IP, HTTP and URL to list of abbreviations used in canonical
# headers.
# Original sequence of headers is handled slightly differently.
#
# Revision 1.17  1998/07/05 18:03:05  andrew
# Fix the PGPMoose bug-compatible code to handle tabs the same
# way as the reference code
#
# Revision 1.16  1998/07/05 08:40:18  andrew
# Bugfix to read(SCALAR) not to drop characters.
#
# Rehash the PGPMoose code to correctly emulate the disgusting bug in
# PGPMoose V1.1 which treats body lines as though they were headers.
#
# Revision 1.15  1998/02/26 00:50:46  andrew
# Cleanup:
#   - remove "use English"
#   - use Selfloader to cut startup time
#   - minor mods (in sign_control and sign_pgpmoose) to avoid pulling
#     in selfloaded sub add_message_id unless needed
#   - change read_header to keep first copy of duplicate unique header,
#     rather than last copy
#
# Revision 1.14  1997/12/29 14:35:26  andrew
# Fixed order-reverse problem in headers() (oops)
#
# Revision 1.13  1997/12/27 23:19:07  andrew
# Missing 'x' flag on extended regexp in fix_envelope
#
# Revision 1.12  1997/12/13 13:00:52  andrew
# Changed add_date to use local time and add timezone offset
#
# Revision 1.11  1997/12/12 11:42:34  andrew
# corrections to header ordering code
#
# Revision 1.10  1997/12/12 11:09:30  andrew
# Added header ordering stuff
#
# Revision 1.9  1997/12/10 19:20:54  andrew
# added ihave
#
# Revision 1.8  1997/11/08 17:51:45  andrew
# Typos, and handling of error return in post().
#
# Revision 1.7  1997/10/22 20:59:27  andrew
# Clean up distribution terms for release
#
# Revision 1.6  1997/10/22 19:54:41  andrew
# Fixed old typo in RCS revision keyword
#
# Revision 1.5  1997/08/31 01:35:25  andrew
# Added obligatory quotation :-)
#
# Revision 1.4  1997/08/29 03:31:07  andrew
# Fix typo in previous mod
#
# Revision 1.3  1997/08/29 00:34:28  andrew
# Update for latest PGP::Sign (v0.08).
# Add reference handling to add_body().
# Allow -f '' in mail().
#
# Revision 1.2  1997/07/30 12:13:11  andrew
# cleanup (no changes)
#
# Revision 1.1  1997/07/29 15:20:40  andrew
# Initial revision
#
#
#
###########################################################################


