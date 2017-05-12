package Net::ChooseFName;

use 5.005;
use strict;

use URI::URL 'url';
use File::Path 'mkpath';
use LWP::MediaTypes qw(guess_media_type media_suffix add_type);
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Net::ChooseFName - Perl extension for choosing a name of a local mirror
of a net (e.g., FTP or HTTP) resource.

=head1 SYNOPSIS

  use Net::ChooseFName;
  $namer = Net::ChooseFName->new(max_length => 64);	# Copies to CD ok

  $name = $namer->find_name_by_response($LWP_response);
  $name = $namer->find_name_by_response($LWP_response, $as_if_content_type);

  $name = $namer->find_name_by_url($url, $suggested_name,
				   $content_type, $content_encoding);
  $name = $namer->find_name_by_url($url, $suggested_name, $content_type);
  $name = $namer->find_name_by_url($url, $suggested_name);
  $name = $namer->find_name_by_url($url);

  $namer_returns_undef = Net::ChooseFName->failer();	# Funny constructor


=head1 DESCRIPTION

This module helps to pick up a local file name for a remote resource
(e.g., one downloaded from Internet).  It turns out that this is a
tricky business; keep in mind that most servers are misconfigured,
most URLs are malformed, and most filesystems are limited
w.r.t. possible filenames.  As a result most downloaders fail to work
in some situations since they choose names which are not supported on
particular filesystems, or not useful for C<file:///>-related work.

Because of the many possible twists and ramifications, the design of
this module is to be as much configurable as possible.  One of ways of
configurations is a rich system of options which influence
different steps of the process.  To cover cases when options are not
flexible enough, the process is broken into many steps; each step is
easily overridable by subclassing C<Net::ChooseFName>.

The defaults are chosen to be as safe as possible while not getting
very much into the ways.  For example, since C<%> is a special
character on DOSish shells, to simplify working from command line on
such systems, we avoid this letter in generated file names.
Similarly, since MacOS has problems with filenames with 8-bit
characters, we avoid them too; since may Unix programs have problem
with spaces in file names, we massage them into underscores; the
length of the longest file path component is restricted to 255 chars.

Note that in many situations it is advisable to make these
restrictions yet stronger.  For example, for copying to CD one should
restrict names yet more (C<max_length =E<gt> 64>); for copying to MSDOS
file systems enable option C<'8+3' =E<gt> 1>.

[In the description of methods the $self argument is omitted.]

=head2 Principal methods

=over

=item new(OPT1 => $val1, ...)

Constructor method.  Creates an object with given options.  Default
values for the unspecified options are (comments list in which methods
this option is used):

  protect	=>		# protect_characters()
				# $1 should contain the match
		   qr/([?*|\"<>\\:?#\x00-\x1F\x7F-\xFF\[\])/,
  protect_pref	=> '@',		# protect_characters(), protect_directory()
  root		=> '.',		# find_directory()
  dir_mode	=> 0775,	# directory_found()
  mkpath	=> 1,		# directory_found()
  max_suff_len	=> 4,		# split_suffix()	'jpeg'
  keepsuff_same_mediatype => 1,	# choose_suffix()
  type_suff	=>		# choose_suffix()
		   {'text/ftp-dir-listing' => '.dirl'}
  keep_suff	=> { text/plain => 1,
		     application/octet-stream => 1 },
  short_suffices =>		# eight_plus_three()
		   {jpeg => 'jpg', html => 'htm',
		    'tar.bz2' => 'tbz', 'tar.gz' => 'tgz'},
  suggest_disposition => 1,	# find_name_by_response()
  suggested_only_basename => 1,	# find_name_by_response(), raw_name()
  fix_url_backslashes => 1,	# protect_characters()
  max_length	=> 255,		# fix_dups(), fix_component()
  cache_name	=> 1,		# name_found()
  queryless_types =>		# url_takes_query()
	 { map(($_ => 1),	# http://filext.com/detaillist.php?extdetail=DJV 2005/01
	       qw(image/djvu image/x-djvu image/dejavu image/x-dejavu
		  image/djvw image/x.djvu image/vnd.djvu ))},
  queryless_ext	=> { 'djvu' => 1, 'djv' => 1 }, # url_takes_query()

The option C<type_suff> is special so that the user-specified value is
I<added> to this hash, and not I<replaces> it.  Similarly, the value
of option C<html_suff> is used to populate the value for C<text/html>
of this hash.

Other, options have C<undef> as the default value.  Their effects are
documented in the documentation of the methods they affect.  With the
exception of C<known_names>, these options are booleans.

  html_suff			# new()
  known_names			# known_names() name_found(); hash ref or undef
  only_known			# known_names()
  hierarchical			# raw_name(), find_directory()
  use_query			# raw_name()
  8+3				# fix_basename(), fix_component()
  keep_space			# fix_component()
  keep_dots			# fix_component()
  tolower			# fix_component()
  dir_query			# find_directory()
  site_dir			# find_directory()
  ignore_existing_files		# fix_dups

  keep_nosuff, type_suff_no_enc, type_suff_fallback,
  type_suff_fallback_no_enc	# choose_suffix()

Summary of the most useful in applications options (with defaults if
applicable):

  html_suff			# Suffix for HTML (dot will be prepended)
  root		=> '.',		# Where to put files?
  mkpath	=> 1,		# Create directories with chosen names?
  max_length	=> 255,		# Maximal length of a path component
  ignore_existing_files		# Should the filename be "new"?
  cache_name	=> 1,		# Return the same filename on the same URL,
				#   even if file jumped to existence?
  hierarchical			# Only the last component of URL path matters?
  suggested_only_basename => 1,	# Should suggested name be relative the path?
  use_query			# Do not ignore the query part of URL?
				# Value is used as (literal) prefix of query
  dir_query			# Make the non-query part of URL a directory?
  site_dir			# Put the hostname part of URL into directory?
  keepsuff_same_mediatype	# Preserve the file extensions matching type?
  8+3				# Is the filesystem DOSish?
  keep_space			# Map spaces in URL to spaces in filenames?
  tolower			# Translate filenames to lowercase?

  type_suff, type_suff_no_enc, type_suff_fallback, type_suff_fallback_no_enc,
  keep_suff, keep_nosuff	# Hashes indexed by lowercased types;
				# Allow tuning choosing the suffix

=cut

my $pr = '([?*|\"<>\\\\:?#\x00-\x1F\x7F-\xFF\\[\\]])';
my $defaults = {
  protect	=> eval("qr/$pr/") || $pr,
  protect_pref	=> '@',
  root		=> '.',
  dir_mode	=> 0775,
  mkpath	=> 1,
  keep_suff	=> {map(($_ => 1),
			qw( text/plain
		            application/octet-stream application/download ))},
  max_suff_len	=> 4,		# 'jpeg'
  keepsuff_same_mediatype => 1,
  short_suffices	=> {qw( jpeg jpg tar.bz2 tbz html htm
			tar.gz tgz )},	# used if '8+3' is true
  suggest_disposition => 1,
  suggested_only_basename => 1,
  fix_url_backslashes => 1,
  max_length	=> 255,
  cache_name	=> 1,		# name_found()
  queryless_types =>		# url_takes_query()
	 { map(($_ => 1),	# http://filext.com/detaillist.php?extdetail=DJV 2005/01
	       qw(image/djvu image/x-djvu image/dejavu image/x-dejavu
		  image/vnd.djvw image/djvw image/x.djvu))},
  queryless_ext	=> { 'djvu' => 1, 'djv' => 1 }, # url_takes_query()
};

my %default_suff = (
  'text/ftp-dir-listing' => '.dirl',
);

sub new {
  my $class = shift;
  my $self = bless {%$defaults, @_}, $class;
  $self->{type_suff} ||= {};
  $self->{type_suff}{'text/html'} = ".$self->{html_suff}"
    if defined $self->{html_suff};
  $self->{type_suff} = {%default_suff, %{$self->{type_suff}}};
  $self;
}

=item find_name_by_url($url, $suggested_name, $type, $enc)

This method returns a suitable filename for the resource given its URL.
Optional arguments are a suggested name (possibly, it will be modified
according to options of the object), the content-type, and the
content-encoding of the resource.  If multiple content-encodings are
required, specify them as an array reference.

A chain of helper methods (L<"Transformation chain">) is called to
apply certain transformations to the name.  C<undef> is returned if
any of the helper methods (except known_names() and protect_query())
return undefined values; the caller is free to interpret this as "load
to memory", if appropriate.  These helper methods are listed in the
following section.

=cut

sub find_name_by_url {
    my ($self, $url, $suggested, $type, $enc) = @_;

    defined($url = $self->url_2resource($url, $type, $enc)) or return;

    my $f = $self->known_names($url, $suggested, $type, $enc);
    return $f if defined $f;

    ($f, my $q) = $self->raw_name($url, $suggested, $type, $enc)
      or return;

    $f = $self->protect_characters($f, $q, $url, $suggested, $type, $enc);
    return unless defined $f;

    $q = $self->protect_query($f, $q, $url, $suggested, $type, $enc);

    (my $dirname, $f, $q)
      = $self->find_directory($f, $q, $url, $suggested, $type, $enc)
	or return;

    $dirname = $self->protect_directory($dirname, $f, $q, $url, $suggested, $type, $enc);
    return unless defined $dirname;

    $dirname = $self->directory_found($dirname, $f, $q, $url, $suggested, $type, $enc);
    return unless defined $dirname;

    ($f, my $suff) =
      $self->split_suffix($f, $dirname, $q, $url, $suggested, $type, $enc)
	or return;
    ($f, $suff) = $self->choose_suffix($f, $suff, $dirname, $q, $url,
				       $suggested, $type, $enc)
	or return;
    ($f, $suff) =
      $self->fix_basename($f, $dirname, $suff, $url, $suggested, $type, $enc)
	or return;
    $f = $self->fix_dups($f, $dirname, $suff, $url, $suggested, $type, $enc);
    return unless defined $f;
    return $self->name_found($url, $f, $dirname, $suff, $suggested, $type, $enc);
}

=item find_name_by_response($response [, $content_type])

This method returns name given an LWP response object (and,
optionally, an overriding C<Content-Type>).  If option
C<suggest_disposition> is TRUE, uses the header C<Content-Disposition>
from the response as the suggested name, then passes the fields from
the response object to the method find_name_by_url().

=cut

sub find_name_by_response {
    my ($self, $res, $ct) = (shift, shift, shift);
    $ct = $res->content_type unless defined $ct;
    # "Content-Disposition" header is defined by RFC1806; supported by Netscape
    my $cd = $self->{suggest_disposition} && $res->header("Content-Disposition");
    my $suggested;
    if ($cd && $cd =~ /\bfilename\s*=\s*(\S+)/) {
        $suggested = $1;
        $suggested =~ s/;$//;
        $suggested =~ s/^([\"\'])(.*)\1$/$2/;
	$suggested =~ s,.*[\\/],, if $self->{suggested_only_basename};
    }
    $self->find_name_by_url($res->request->url, $suggested,
			    $ct, $res->content_encoding);
}

=back

=head2 Transformation chain

=over

=item url_2resource($url [, $type, $encoding])

This method returns $url modified by removing the parts related to
access to I<parts> of the resource.  In particular, the I<fragment> part is
removed, as well as the I<query> part if url_is_queryless() returns TRUE.

=cut

sub url_2resource {
    my ($self, $url, $type, $enc) = @_;

    $url = url($url) unless ref($url);
    my $cpy;
    if (defined $url->frag) {
      $cpy = $url = $url->clone;
      $url->frag(undef);
    }
    if (defined $url->equery and $self->url_takes_query($url, $type, $enc)) {
      $url = $url->clone unless $cpy;
      $url->query(undef);
    }
    $url
}

=item known_names($url, $suggested, $type, $enc)

The method find_name_by_url() will return the return value of this
method (unless L<undef>) immediately.  Unless overriden, this method
returns the value of the hash option C<known_names> indexed by the
$url.  (By default this hash is empty.)

If the option C<only_known> is true, it is a fatal error if $url is
not a key of this hash.

=cut

sub known_names {
    my ($self, $url) = @_;
    my $f = $self->{known_names}{$url};
    return $f if defined $f;

    die "URL with unknown name `$url'"
	if $self->{only_known} and keys %{$self->{known_names}};
    return;
}

=item raw_name($url, $suggested, $type, $enc)

Returns the 0th approximation to the filename of the resource; the
return value has two parts: the principal part, and the query string
(C<undef> if should not be used).

If $suggested is undefined, returns the path part of the $url, and the
query part, if present and if option C<use_query> is TRUE).  Otherwise
either returns $suggested, or (if options C<suggested_only_basename>
and C<hierarchical> are both true), returns the I<path> part of the
$url with the last component changed to $suggested; the query part is
ignored in this case.  In the latter case, if option C<suggested_basename> is TRUE, only the last path component of $suggested is used.

=cut

sub raw_name {
    my ($self, $url, $suggested) = @_;
    if (defined $suggested) {
	if ($self->{suggested_only_basename} and $self->{hierarchical}) {
	    my @p = $url->path_segments;
	    $suggested =~ s,.*/,, if $self->{suggested_basename};
	    return join '/', @p[0..$#p-1], $suggested;
	}
	return $suggested;
    } else {
	my $q = $self->{use_query} ? $url->equery : undef;
	return ($url->path, $q);
    }
}

=item protect_characters($f, $query, $url, $suggested, $type, $enc)

Returns the filename $f with necessary character-by-character
translations performed.  Unless overriden, it translates backslashes
to slashes if the option C<fix_url_backslashes> is TRUE, replaces
characters matched by regular expression in the option C<protect> by
their hexadecimal representation (with the leader being the value of
the option C<protect_pref>), and replaces percent signs by the value
of the option C<protect_pref>.

=cut

sub protect_characters {
    my ($self, $f) = @_;
    $f =~ s,\\,/,g if $self->{fix_url_backslashes};
    # Protect against funny characters, some filesystems can bark on them
    $f =~ s($self->{protect})
	   ( sprintf '%s%02X', $self->{protect_pref}, ord $1 )ge;
    $f =~ s(%)($self->{protect_pref})g if $self->{protect_pref} ne '%';
    $f
}

=item protect_query($f, $query, $url, $suggested, $type, $enc)

Returns $query with necessary character-by-character translations
performed.  Unless overriden, it translates slashes, backslashes, and
characters matched byregular expression in the option C<protect> by
their hexadecimal representation (with the leader being the value of
the option C<protect_pref>), and replaces percent signs by the value
of the option C<protect_pref>.

=cut

sub protect_query {
    my ($self, $f, $q) = @_;
    return unless defined $q;
    # Protect against funny characters, some filesystems can bark on them
    $q =~ s($self->{protect})
	   ( sprintf '%s%02X', $self->{protect_pref}, ord $1 )ge;
    $q =~ s(%)($self->{protect_pref})g if $self->{protect_pref} ne '%';
    $q =~ s(([/\\]))
	   ( sprintf '%s%02X', $self->{protect_pref}, ord $1 )ge;
    $q
}

=item find_directory($f, $query, $url, $suggested, $type, $enc)

Returns a triple of the appropriate directory name, the relative
filename, and a string to append to the filename, based on
processed-so-far filename $f and the $query string.

Unless overriden, does the following: unless the option
C<hierarchical> is TRUE, all but the last path components of $f are
ignored. If the option C<site_dir> is TRUE, the host part of the URL
(as well as the port part - if non-standard) are prepended to the
filename.  The leading backslash is always stripped, and the option
C<root> is used as the lead components of the directory name.  If
$query is defined, and the option C<dir_query> is true, $f is used as
the last component of the directory, and $query as file name (with
option C<use_query> prepended).

(Dirname is assumed to be C</>-terminated.)

=cut

sub find_directory {
    my ($self, $f, $q, $url) = @_;
    # trim path until only the basename is left
    $f =~ s|(.*/)||;
    my $dirname = ($self->{hierarchical} and $1) ? $1 : '';
    $dirname =~ s#^/##;

    if (defined $q) {
      $q = "$self->{use_query}$q";
      if ($self->{dir_query}) {
	$dirname = "$dirname$f/"; # XXXX If it already exists as a file?
	$f = $q;
	$q = '';
      }
    } else {
      $q = '';
    }

    if ($self->{site_dir}) {
	eval {
	    my $site = lc $url->host;
	    my $port = $url->port;
	    my $def = $url->default_port;
	    $port = '' if $port == $def;
	    $site .= "=port$port" if length $port;
	    $dirname = "$self->{root}/$site/$dirname";
	};
    } else {
	$dirname = "$self->{root}/$dirname";
    }
    ($dirname, $f, $q)
}

=item protect_directory($dirname, $f, $append, $url, $suggested, $type, $enc)

Returns the provisional directory part of the filename.  Unless
overriden, replaces empty components by the string C<empty> preceeded
by the value of C<protect_pref> option; then applies the method
fix_component() to each component of the directory.

=cut

sub protect_directory {
    my ($self, $dirname) = @_;
    $dirname =~ s,/(?=/),/$self->{protect_pref}empty,g; # empty components
    return join '/', map($self->fix_component($_,1), split m|/|, $dirname), '';
}

=item directory_found($dirname, $f, $append, $url, $suggested, $type, $enc)

A callback to process the calculated directory name.  Unless
overriden, it creates the directory (with permissions per option
C<dir_mode>) if the option C<mkpath> is TRUE.

Actually, the directory name is the return value, so this is the last
chance to change the directory name...

=cut

sub directory_found {
    my ($self, $dirname) = @_;
    mkpath $dirname,  $self->{verbose}, $self->{dir_mode}
	if $self->{mkpath} and length $dirname and not -d $dirname;
    $dirname;
}

# Copied from LWP::Mediatypes v1.32
my %suffixEncoding = (
    'Z'   => 'compress',
    'gz'  => 'gzip',
    'hqx' => 'x-hqx',
    'uu'  => 'x-uuencode',
    'z'   => 'x-pack',
    'bz2' => 'x-bzip2',
);
my %suffixDecoding = reverse %suffixEncoding;

=item split_suffix($f, $dirname, $append, $url, $suggested, $type, $enc)

Breaks the last component $f of the filename into a pair of basename
and suffix, which are returned.  $dirname consists of other components
of the filename, $append is the string to append to the basename in
the future.

Suffix may be empty, and is supposed to contain the leading dot (if
applicable); it may contain more than one dot.  Unless overriden, the
suffix consists of all trailing non-empty started-by-dot groups with
length no more than given by the option C<max_suff_len> (not including
the leading dot).

=cut

sub split_suffix {
  my ($self, $f, $dirname, $append, $url, $suggested, $type, $enc) = @_;

  my $suff;

  my $max = $self->{max_suff_len};
  (my $base = $f) =~ s<((?:\.[^/]{1,$max})*)$><>;
  return ($base, "$1");
}


=item choose_suffix($f, $suff, $dirname, $append, $url, $suggested, $type, $enc)

Returns a pair of basename and appropriate suffix for a file.  $f is
the basename of the file, $suff is its suffix, $dirname consists of
other components of file names, $append is the string to append to the
basename.

Different strategies applicable to this problem are:

=over

=item *

keep the file extension;

=item *

replace by the "best" extension for this $type (and $enc);

=item *

replace by the user-specified type-specific extension.

=back

Any of these has two variants: whether we want the encodings reflected
in the suffix, or not.  Unless overriden, chosing strategy/variant
consists of several rounds.

In the first round, choose user-specified suffix if $type is defined,
and is (lowercased) in the option-hashes C<type_suff> and
C<type_suff_no_enc> (choosing the variant based on which hash
matched).  Keep the current suffix if $type is not defined, or option
C<keepsuff_same_mediatype> is TRUE and the current suffix of the file
matches $type and $enc (per database of known types and encodings).

The second round runs if none of these was applicable.  Choose
user-specified suffix if $type is (lowercased) in the hashes
C<type_suff_fallback> or C<type_suff_fallback_no_enc> (choosing
variant as above); keep the current suffix if the type (lowercased) is
in the hashes C<keep_nosuff> or C<keep_suff> (depending on whether
$suff is empty or not).

If none of these was applicable, the last round chooses the
appropriate suffix by the database of known types and encodings; if
not found, the existing suffix is preserved.

=cut

sub choose_suffix {
  my ($self, $f, $suff, $dirname, $append, $url, $suggested, $type, $enc) = @_;

  my ($guess_suffix, $check_enc);
  $enc = [] unless defined $enc;
  $enc = [$enc] unless ref $enc;
  if (not defined $type) {	# Do nothing
  } elsif (exists $self->{type_suff}{lc $type}) {
    $suff = $self->{type_suff}{lc $type};
    $check_enc = $enc;
  } elsif (exists $self->{type_suff_no_enc}{lc $type}) {
    $suff = $self->{type_suff}{lc $type};
  } elsif ($self->{keepsuff_same_mediatype}) {
    my($t, @enc) = guess_media_type($f);
    $guess_suffix = 1
      unless defined $t and lc $t eq lc $type and lc "@enc" eq lc "@$enc";
  } else {
    $guess_suffix = 1;
  }

  if (not $guess_suffix) {		# No substitution
  } elsif (exists $self->{type_suff_fallback}{lc $type}) {
    $suff = $self->{type_suff_fallback}{lc $type};
    $check_enc = $enc;
  } elsif (exists $self->{type_suff_fallback_no_enc}{lc $type}) {
    $suff = $self->{type_suff_fallback}{lc $type};
  } elsif ((length $suff)
	   ? $self->{keep_suff}{lc $type}
	   : $self->{keep_nosuff}{lc $type}) { # No substitution
  } else {
    my $s = media_suffix($type);
    if (defined $s and length $s) { # Known media type...
      $suff = ".$s";
      $check_enc = $enc;
    }
  }

  if ($check_enc) {
    for my $e (@$enc) {
      $suff .= $suffixDecoding{$e} if exists $suffixDecoding{$e};
    }
  }

  return ("$f$append", $suff);
}

=item fix_basename($f, $dirname, $suff, $url, $suggested, $type, $enc)

Returns a pair of basename and suffix for a file.  $f is the last
component of the name of the file, $dirname consists of other
components.  Unless overriden, this method replaces an empty basename
by C<"index"> and applies fix_component() method to the basename;
finally, if C<'8+3'> otion is set, it converts the filename and suffix
to a name suitable 8+3 filesystems.

=cut

sub fix_basename {
  my ($self, $f, $dirname, $suffix) = @_;

  $f = "index" unless length $f;
  $f = $self->fix_component($f,0);	# Length ignores extension...
  ($f, $suffix) = $self->eight_plus_three($f, $suffix) if $self->{'8+3'};
  return ($f, $suffix);
}

=item fix_dups($f, $dirname, $suff, $url, $suggested, $type, $enc)

Given a basename, extension, and the directory part of the filename,
modifies the basename (if needed) to avoid duplicates; should return
the complete file name (combining the dirname, basename, and suffix).
Unless overriden, appends a number to the basename (shortening
basename if needed) so that the result is unique.

This is a prime candidate for overriding (e.g., to ask user for
confirmation of overwrite).

=cut

sub fix_dups {
  my ($self, $f, $dirname, $suff) = @_;

  return "$dirname$f$suff" if $self->{ignore_existing_files};
  my $max_length = $self->{max_length};
  my $extra = "";		# something to make the name unique
  $max_length = 8 + length $suff if $self->{'8+3'};
  while (1) {
    # Construct a new file name; give up shortening if suffix is too long...
    if ( $max_length and length "$f$extra$suff" > $max_length
	 and length "$extra$suff" < $max_length ) {
      $f = substr $f, 0, $max_length - length "$extra$suff";
    }
    my $file = $dirname . $f . $extra . $suff;
    # Check if it is unique
    return $file unless -e $file;

    $extra = "000" unless $extra; # Try appending a number
    $extra++;
  }
}

=item name_found($url, $f, $dirname, $suff, $suggested, $type, $enc)

The callback method to register the found name.  Unless overridden,
behaves like following: if option C<cache_name> is TRUE, stores the
found name in the C<known_names> hash.  Otherwise just returns the found name.

=cut

sub name_found {
  my ($self, $url, $f, $dirname, $suff, $suggested, $type, $enc) = @_;

  return $f unless $self->{cache_name};
  return $self->{known_names}{$url} = $f;
}

=back

=head2 Helper methods

=over

=item fix_component($component, $isdir)

Returns a suitably modified value of a path component of a filename.
The non-overriden method massages unescapes embedded SPACE characters;
it removes starting/trailing, and converts the rest to C<_> unless the
option C<keep_space> is TRUE; removes trailing dots unless the option
C<keep_dots> is TRUE; translates to lowercase if the option C<tolower>
is TRUE, truncates to C<max_length> if this option is set, and applies
the eight_plus_three() method if the option C<'8+3'> is set.

=cut

sub fix_component {
    my ($self, $f, $isdir) = @_;

    $f =~ s/%20/ /g;	# URL-encoded space is %20
    $f =~ s/\E$self->{protect_pref}20/ /g;	# URL-encoded space is %20
    unless ($self->{keep_space}) { # Translate spaces in URL to underscores (_)
	$f =~ s/^ *//;		# Remove initial spaces from base
	$f =~ s/ *$//;		# Remove trailing spaces from base

	$f =~ tr/ /_/;
    }
    $f =~ s/\.+$// unless $self->{keep_dots};
    $f = lc $f if $self->{tolower};	# Output lower-case

    substr($f, $self->{max_length}) = ''
	if $self->{max_length} and length $f > $self->{max_length};
    return join '', $self->eight_plus_three($f) if $self->{'8+3'};
    $f;
}

=item eight_plus_three($fname, $suffix)

Returns the value of filename modified for filesystems with 8+3
restriction on the filename (such as DOS).  If $suffix is not given,
calculates it from $fname; otherwise $suffix should include the
leading dot, and $fname should have $suffix already removed.  (Some
parts of info may be moved between suffix and filename if judged
appropriate.)

=cut

sub eight_plus_three {
    my ($self, $f, $suff) = @_;

    ($f, $suff) = $self->split_suffix($f, undef, '') unless defined $suff;
    # Try to move some info to a suffix even if it becomes too long
    $suff = $2 if not length $suff and $f =~ s|(.{8,})\.(.*)$|$1|s ;

    # Balance multiple suffices between the parts
    $f .= $1 while length($f) <= 6 and $suff =~ s/^(\..*?)(?=\...)//s;

    if (not length $suff and length($f) > 8) { # Move part of fname to suff
      my $l = length($f) - 8;
      $l = 3 if $l > 3;
      $suff = substr $f, -$l, $l;
      substr($f, -$l, $l) = '';
    }
    $f =~ s/\./_/g;
    $suff =~ s/^\.//;		# Temporary strip the leading dot
    my $s = $self->{short_suffices}{$suff};
    ($s = $suff) =~ s/\./_/g unless defined $s;

    substr($f, 8) = ''			if length($f) > 8;
    substr($s, 2, length($s)-3) = ''	if length($s) > 3;
    $s = ".$s" if length $s;
    ($f, $s);
}

=item url_takes_query($url [, $type, $encoding])

This method returns TRUE if the I<query> part of the URL is selecting
a part of the resource (i.e., if it is behaves as a I<fragment> part,
and it is the client which should process this part).  Such URLs are
detected by $type (should be in hash option C<queryless_types>), or by
extension of the last path component (should be in hash option
C<queryless_ext>).

=back

=cut

sub url_takes_query {
    my ($self, $url, $type) = @_;
    return 1 if $type and $self->{queryless_types}{$type};
    my @p = $url->path_segments;
    my ($ext) = (@p and $p[-1] =~ /.*\.(.*)$/);
    $ext and $self->{queryless_ext}{$ext};
}

=head1 Net::ChooseFName::Failer class

A class which behaves as Net::ChooseFName, but always returns
C<undef>.  For convenience, the constructor is duplicated as a class
method failer() in the class Net::ChooseFName.

=cut

# These always return undef; the caller is free to interpret this "to memory"
sub Net::ChooseFName::Failer::find_name_by_response {}
sub Net::ChooseFName::Failer::find_name_by_url {}
sub Net::ChooseFName::Failer::new {bless [], shift}
sub Net::ChooseFName::failer {bless [], 'Net::ChooseFName::Failer'}

sub __Fix_broken_MediaTypes {
  my @s = media_suffix('application/postscript');
#	warn "Fixing `@s'...";
#  if ($s[0] eq 'ai' or 1) {	# [0] addresses in hash order; meaningless
#	warn "Fixing...";
    @s = ('ps', grep $_ ne 'ps', @s);
    add_type('application/postscript', @s);
#  }
}
__Fix_broken_MediaTypes();

1;
__END__

=head2 EXPORT

None by default.

=head1 BUGS

Documentation keeps mentioning I<"unless overriden">...  Of course it
is a generic remark applicable to any method of any class; however,
please remember that methods of this class are designed to be
overriden.

There is no protection against a wanted directory name being already taken
by a file.

There is no restriction on length of overall file name, only on length of
a component name.

=head1 SEE ALSO

LWP=libwww-perl

=head1 AUTHOR

Ilya Zakharevich <ilyaz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ilya Zakharevich <ilyaz@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

