# -*- perl -*-

#
# $Id: Cache.pm,v 1.21.1.7 2007/11/05 20:51:06 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

=head1 NAME

Netscape::Cache - object class for accessing Netscape cache files

=head1 SYNOPSIS

The object oriented interface:

    use Netscape::Cache;

    $cache = new Netscape::Cache;
    while (defined($url = $cache->next_url)) {
	print $url, "\n";
    }

    while (defined($o = $cache->next_object)) {
	print
	  $o->{'URL'}, "\n",
	  $o->{'CACHEFILE'}, "\n",
	  $o->{'LAST_MODIFIED'}, "\n",
	  $o->{'MIME_TYPE'}, "\n";
    }

The TIEHASH interface:

    use Netscape::Cache;

    tie %cache, 'Netscape::Cache';
    foreach (sort keys %cache) { 
	print $cache{$_}->{URL}, "\n";
    }

=head1 DESCRIPTION

The B<Netscape::Cache> module implements an object class for
accessing the filenames and URLs of the cache files used by the
Netscape web browser.

Note: You can also use the undocumented pseudo-URLs C<about:cache>,
C<about:memory-cache> and C<about:global-history> to access your disk
cache, memory cache and global history.

There is also an interface for using tied hashes.

Netscape uses the old Berkeley DB format (version 1.85) for its cache
index C<index.db>. Versions 2 and newer of Berkeley DB are
incompatible with the old format (L<db_intro(3)>), so you have either
to downgrade or to convert the database using B<db_dump185> and
B<db_load>. See L<convert_185_2xx|/convert_185_2xx> for a
(experimental) converter function.

=cut

package Netscape::Cache;
use strict;
use vars qw($Default_Preferences $Default_40_Preferences @Try_Preferences
	    $Default_Cache_Dir @Default_Cache_Index
	    $Debug $Home $OS_Type $VERSION);

use DB_File;

if (defined $DB_File::db_version and $DB_File::db_version > 1) {
    warn "Netscape::Cache works only if Berkeley db version 1 is\n" .
      "installed. Please use the convert_185_2xx function to convert\n" .
	"the cache index to the new db format (see manpage).\n";
}

if ($^O =~ /^((ms)?(win|dos)|os2)/i) {
    $Default_Preferences = 'C:\NETSCAPE\NETSCAPE.INI';
    @Try_Preferences     = qw(D:\NETSCAPE\NETSCAPE.INI
			      C:\INTERNET\NETSCAPE\NETSCAPE.INI
			      D:\INTERNET\NETSCAPE\NETSCAPE.INI
			      C:\PROGRAMS\NETSCAPE\NETSCAPE.INI);
    $Default_Cache_Dir   = 'C:\NETSCAPE\CACHE';
    @Default_Cache_Index = qw(FAT.DB INDEX.DB);
    $OS_Type = 'win';
} else {
    $Home = $ENV{'HOME'} || (getpwuid($>))[7];
    $Default_Preferences    = "$Home/.netscape/preferences";
    @Try_Preferences        = ();
    $Default_40_Preferences = "$Home/.netscape/preferences.js";
    $Default_Cache_Dir      = "$Home/.netscape/cache";
    @Default_Cache_Index    = qw(index.db FAT.DB fat.db Fat.db);
    $OS_Type = 'unix';
}

$Debug = 0;
$VERSION = '0.46';

=head1 CONSTRUCTOR

    $cache = new Netscape::Cache(-cachedir => "$ENV{HOME}/.netscape/cache");

This creates a new instance of the B<Netscape::Cache> object class. The
I<-cachedir> argument is optional. By default, the cache directory setting
is retrieved from C<~/.netscape/preferences>. The index file is normally
named C<index.db> on Unix systems and C<FAT.DB> on Microsoft systems. It may
be changed with the I<-index> argument.

If the Netscape cache index file does not exist, a warning message
will be generated, and the constructor will return C<undef>.

=cut

sub new ($;%) {
    my($pkg, %a) = @_;
    my($try, $indexfile);
    my $cachedir = $a{-cachedir} || get_cache_dir() || $Default_Cache_Dir;
    if ($a{'-index'}) {
	$indexfile =
	  ($a{'-index'} =~ m|^/| ? $a{'-index'} : "$cachedir/$a{'-index'}");
    } else {
	foreach $try (@Default_Cache_Index) {	#try all the names
	    $indexfile = "$cachedir/$try";
	    last if -f $indexfile;		#exit when we find one
	}
    }
    if (-f $indexfile) {
	my %cache;
	my $self = {};
	if (!tie %cache, 'DB_File', $indexfile) {
	    warn
	      "Can't tie <$indexfile>. Maybe you are using version 2.x.x\n",
	      "of the Berkeley DB library?\n";
	    return undef;
	}
	$self->{CACHE}     = \%cache;
	$self->{CACHEDIR}  = $cachedir;
	$self->{CACHEFILE} = $indexfile;
	bless $self, $pkg;
    } else {
	warn "No cache db found. Try to set the cache direcetory with\n" .
	  "-cachedir and the index file with -index.\n";
        undef;
    }
}

sub TIEHASH ($;@) {
    shift->new(@_);
}

=head1 METHODS

The B<Netscape::Cache> class implements the following methods:

=over

=item *

B<rewind> - reset cache index to first URL

=item *

B<next_url> - get next URL from cache index

=item *

B<next_object> - get next URL as a full B<Netscape::Cache::Object> from
cache index

=item *

B<get_object> - get a B<Netscape::Cache::Object> for a given URL

=back

Each of the methods are described separately below.

=head2 next_url

    $url = $history->next_url;

This method returns the next URL from the cache index. Unlike
B<Netscape::History>, this method returns a string and not an
URI::URL-like object.

This method is faster than B<next_object>, since it does only evaluate the
URL of the cached file.

=cut

sub next_url ($) {
    my $self = shift;
    my $url;
    do {
	my $key = each %{ $self->{CACHE} };
	return undef if !defined $key;
	$url = Netscape::Cache::Object::url($key);
    } while !$url;
    $url;
}

=head2 next_object

    $cache->next_object;

This method returns the next URL from the cache index as a
B<Netscape::Cache::Object> object. See below for accessing the components
(cache filename, content length, mime type and more) of this object.

=cut

sub next_object ($) {
    my $self = shift;
    my $o;
    do {
	my($key, $value) = each %{ $self->{CACHE} };
	return undef if !defined $key;
	$o = Netscape::Cache::Object->new($key, $value);
    } while !defined $o;
    $o;
}

sub FIRSTKEY ($) {
    my $self = shift;
    $self->rewind;
    my $o = $self->next_object;
    defined $o ? $o->{URL} : undef;
}

sub NEXTKEY ($) {
    my $self = shift;
    my $o = $self->next_object;
    defined $o ? $o->{URL} : undef;
}

=head2 get_object

    $cache->get_object;

This method returns the B<Netscape::Cache::Object> object for a given URL.
If the URL does not live in the cache index, then the returned value will be
undefined.

=cut

sub get_object ($$) {
    my($self, $url) = @_;
    my $key = Netscape::Cache::Object::_make_key_from_url($url);
    my $value = $self->{CACHE}{$key};
    $value ? new Netscape::Cache::Object($key, $value) : undef;
}

sub FETCH ($$) {
    shift->get_object(@_);
}

sub EXISTS ($$) {
    my($self, $url) = @_;
    my $key = Netscape::Cache::Object::_make_key_from_url($url);
    exists $self->{CACHE}{$key};
}

=head2 delete_object

Deletes URL from cache index and the related file from the cache.

B<WARNING:> Do not use B<delete_object> while in a B<next_object> loop!
It is better to collect all objects for delete in a list and do the
deletion after the loop, otherwise you can get strange behavior (e.g.
malloc panics).

=cut

sub delete_object ($$) {
    my($self, $url) = @_;
    my $f = $self->{CACHEDIR} . "/" . $self->{CACHEFILE};
    if (-e $f) {
	return undef if !unlink $f;
    }
    delete $self->{CACHE}{$url->{'_KEY'}};
}

sub DELETE ($$) {
    my($self, $url) = @_;
    my $key = Netscape::Cache::Object::_make_key_from_url($url);
    delete $self->{CACHE}{$key};
}

=head2 rewind

    $cache->rewind();

This method is used to move the internal pointer of the cache index to
the first URL in the cache index. You do not need to bother with this
if you have just created the object, but it does not harm anything if
you do.

=cut

sub rewind ($) {
    my $self = shift;
    reset %{ $self->{CACHE} };
}

sub CLEAR {
    die "CLEARs are not permitted";
}

sub STORE {
    die "STOREs are not permitted";
}

sub DESTROY ($) {
    my $self = shift;
    untie %{ $self->{CACHE} };
}

=head2 get_object_by_cachefile

    $o = $cache->get_object_by_cachefile($cachefile);

Finds the corresponding entry for a cache file and returns the object,
or undef if there is no such C<$cachefile>. This is useful, if you find
something in your cache directory by using B<grep> and you want to
know the URL and other attributes of this file.

WARNING: Do not use this method while iterating with B<get_url>, B<get_object>
or B<each>, because this method does iterating itself and would mess up
the previous iteration.

=cut

sub get_object_by_cachefile {
    my($self, $cachefile) = @_;
    $self->rewind;
    my $o;
    while(defined($o = $self->next_object)) {
	if ($cachefile eq $o->{'CACHEFILE'}) {
	    return $o;
	}
    }
    undef;
}

=head2 get_object_by_cachefile

    $url = $cache->get_url_by_cachefile($cachefile);

Finds the corresponding URL for a cache file. This method is implemented
using B<get_object_by_cachefile>.

=cut

sub get_url_by_cachefile {
    my($self, $cachefile) = @_;
    my $o = $self->get_object_by_cachefile($cachefile);
    if (defined $o) {
	$o->{'URL'};
    } else {
	undef;
    }
}

# internal subroutine to get the cache directory from Netscape's preferences
sub get_cache_dir {
    my $cache_dir;
    if ($Default_40_Preferences && open(PREFS, $Default_40_Preferences)) {
	# try preferences from netscape 4.0
	while(<PREFS>) {
	    if (/user_pref\("browser.cache.directory",\s*"([^\"]+)"\)/) {
		$cache_dir = $1;
		last;
	    }
	}
	close PREFS;
    }
    if (!$cache_dir) {
	my $pref;
      TRY:
	foreach $pref ($Default_Preferences, @Try_Preferences) {
	    if (open(PREFS, $pref)) {
		if ($OS_Type eq 'unix') {
		    while(<PREFS>) {
			if (/^CACHE_DIR:\s*(.*)$/) {
			    $cache_dir = $1;
			    last;
			}
		    }
		} elsif ($OS_Type eq 'win') {
		    my $cache_section_found;
		    while(<PREFS>) { # read .ini file
			if ($cache_section_found) {
			    if (/^cache dir=(.*)$/i) {
				($cache_dir = $1) =~ s/\r//g; # strip ^M
				last;
			    } elsif (/^\[/) { # new section found
				undef $cache_section_found;
				redo; # maybe the new section is a cache section too?
			    }
			} elsif (/^\[Cache\]/i) { # cache section found
			    $cache_section_found++;
			}
		    }
		}
		close PREFS;
		last TRY;
	    }
	}
    }
    if ($OS_Type eq 'unix' && defined $cache_dir) {
	$cache_dir =~ s|^~/|$Home/|;
    }
    $cache_dir;
}

=head2 convert_185_2xx

    $newindex = Netscape::Cache::convert_185_2xx($origindex [, $tmploc])

This is a (experimental) utility for converting C<index.db> to the new
Berkeley DB 2.x.x format. Note that this function will not overwrite
the original C<index.db>, but rather copy the converted index to
C<$tmploc> or C</tmp/index.$$.db>, if C<$tmploc> is not given.
B<convert_185_2xx> returns the filename of the new created index file.
The converted index is only temporary, and all write access is
useless.

Usage example:

    my $newindex = Netscape::Cache::convert_185_2xx($indexfile);
    my $o = new Netscape::Cache -index => $newindex;

=cut

sub convert_185_2xx {
    my($indexfile, $tmploc) = @_;
    my $success = 0;
    my $tmpdir;
    foreach (qw(/tmp /temp .)) {
	if (-d $_ && -w $_) {
	    $tmpdir = $_;
	    last;
	}
    }
    die "No /tmp or /temp directory writeable" if !defined $tmpdir;
    die "usage: convert_185_2xx(indexfile [,tmploc])"
      unless defined $indexfile;
    $tmploc = "$tmpdir/index.$$.db"
      unless defined $tmploc;
    my $tmpdump = "$tmpdir/dump";
    system("db_dump185 $indexfile > $tmpdump");
    if ($?) { warn $!;
	      goto CLEANUP }
    chmod 0600, $tmpdump;
    system("db_load $tmploc < $tmpdump");
    if ($?) { warn $!;
	      unlink $tmploc;
	      goto CLEANUP }
    chmod 0600, $tmploc;
    $success++;
  CLEANUP:
    unlink $tmpdump;
    $success ? $tmploc : undef;
}

package Netscape::Cache::Object;
use strict;
use vars qw($Debug);

$Debug = $Netscape::Cache::Debug;

=head1 Netscape::Cache::Object

B<next_object> and B<get_object> return an object of the class
B<Netscape::Cache::Object>. This object is simply a hash, which members
have to be accessed directly (no methods).

An example:

    $o = $cache->next_object;
    print $o->{'URL'}, "\n";

=over 4

=item URL

The URL of the cached object

=item COMPLETE_URL

The complete URL with the query string attached (only Netscape 4.x).

=item CACHEFILE

The filename of the cached URL in the cache directory. To construct the full
path use (C<$cache> is a B<Netscape::Cache> object and C<$o> a
B<Netscape::Cache::Object> object)

    $cache->{'CACHEDIR'} . "/" . $o->{'CACHEFILE'}

=item CACHEFILE_SIZE

The size of the cache file.

=item CONTENT_LENGTH

The length of the cache file as specified in the HTTP response header.
In general, SIZE and CONTENT_LENGTH are equal. If you interrupt a transfer of
a file, only the first part of the file is written to the cache, resulting
in a smaller CONTENT_LENGTH than SIZE.

=item LAST_MODIFIED

The date of last modification of the URL as unix time (seconds since
epoch). Use

    scalar localtime $o->{'LAST_MODIFIED'}

to get a human readable date.

=item LAST_VISITED

The date of last visit.

=item EXPIRE_DATE

If defined, the date of expiry for the URL.

=item MIME_TYPE

The MIME type of the URL (eg. text/html or image/jpeg).

=item ENCODING

The encoding of the URL (eg. x-gzip for gzipped data).

=item CHARSET

The charset of the URL (eg. iso-8859-1).

=item NS_VERSION

The version of Netscape which created this cache file (C<3> for
Netscape 2.x and 3.x, C<4> for Netscape 4.0x and C<5> for Netscape
4.5).

=back

=cut

sub new ($$;$) {
    my($pkg, $key, $value) = @_;

    return undef if !defined $value || $value eq '';

    my $url = url($key);
    return undef if !$url;

    my $self = {};
    bless $self, $pkg;
    $self->{URL} = $url;

    $self->{'_KEY'} = $key;

    my($rest, $len, $last_modified, $expire_date);
    ($self->{NS_VERSION},
     $last_modified, 
     $self->{LAST_VISITED},
     $expire_date,
     $self->{CACHEFILE_SIZE},
     $self->{'_XXX_FLAG_2'})      = unpack("V6", substr($value, 4));
    ($self->{CACHEFILE}, $rest) = split(/\000/, substr($value, 33), 2);
    $self->{'_XXX_FLAG_3'}        = unpack("V", substr($rest, 4, 4));
    $self->{'_XXX_FLAG_4'}        = unpack("V", substr($rest, 25, 4));
    $self->{LAST_MODIFIED}      = $last_modified if $last_modified != 0;
    $self->{EXPIRE_DATE}        = $expire_date if $expire_date != 0;
    
    if ($Debug) {
	$self->_report(1, $key, $value, 
		       "<".substr($rest, 0, 4)."><".substr($rest, 8, 17)
		       ."><".substr($rest, 29, 4).">")
	  if   substr($rest, 0, 4)  =~ /[^\000]/
	    || substr($rest, 8, 17) =~ /[^\000]/
	    || substr($rest, 29, 4) =~ /[^\000]/;
    }
    
    my $inx;
    if ($self->{NS_VERSION} >= 5) {
	$inx = 21;
    } else {
	$inx = 33;
    }
    $len = unpack("V", substr($rest, $inx, 4));
    if ($len) {
	$self->{MIME_TYPE} = substr($rest, $inx+4, $len-1);
    }
    $rest = substr($rest, $inx+4 + $len);
    
    $len = unpack("V", substr($rest, 0, 4));
    if ($len) {
	$self->{ENCODING} = substr($rest, 4, $len-1);
    }
    $rest = substr($rest, 4 + $len);
    
    $len = unpack("V", substr($rest, 0, 4));
    if ($len) {
	$self->{CHARSET} = substr($rest, 4, $len-1);
    }
    $rest = substr($rest, 4 + $len);
    
    $self->{CONTENT_LENGTH} = unpack("V", substr($rest, 1, 4));
    $rest = substr($rest, 5);

    $len = unpack("V", substr($rest, 0, 4));
    if ($len) {
	$self->{COMPLETE_URL} = substr($rest, 4, $len-1);
    }
    $rest = substr($rest, 4 + $len);

    if ($Debug) {
	$self->_report(2, $key, $value)
	  if $rest =~ /[^\000]/;

	my $record_length = unpack("V", substr($value, 0, 4));
	warn "Invalid length for value of <$key>\n"
	  if $record_length != length($value);
	$self->_report(4, $key, $value)
	  if $self->{'_XXX_FLAG_2'} != 0 && $self->{'_XXX_FLAG_2'} != 1;
	$self->_report(5, $key, $value)
	  if $self->{'_XXX_FLAG_3'} != 1;
	$self->_report(6, $key, $value)
	  if $self->{'_XXX_FLAG_4'} != 0 && $self->{'_XXX_FLAG_4'} != 1;
    }

    $self;
}

sub url ($) {
    my $key = shift;
    my $keylen2 = unpack("V", substr($key, 4, 4));
    my $keylen1 = unpack("V", substr($key, 0, 4));
    if ($keylen1 == $keylen2 + 12) {
	substr($key, 8, $keylen2-1);
    } # else probably one of INT_CACHESIZE etc. 
}

sub _report {
    my($self, $errno, $key, $value, $addinfo) = @_;
    if ($self->{'_ERROR'} && $Debug < 2) {
	warn "Error number $errno\n";
    } else {
	warn
	  "Please report:\nError number $errno\nURL: "
	    . $self->{URL} . "\nEncoded URL: <"
	      . join("", map { sprintf "%02x", ord $_ } split(//, $key))
		. ">\nEncoded Properties: <"
		  . join("", map { sprintf "%02x", ord $_ } split(//, $value))
		    . ">\n"
		      . ($addinfo ? "Additional Info: <$addinfo>\n" : "")
			. "\n";
    }	
    $self->{'_ERROR'}++;
}

sub _make_key_from_url ($) {
    my $url = shift;
    pack("V", length($url)+13) . pack("V", length($url)+1)
      . $url . ("\000" x 5);
}

=head1 AN EXAMPLE PROGRAM

This program loops through all cache objects and prints a HTML-ified list.
The list is sorted by URL, but you can sort it by last visit date or size,
too.

    use Netscape::Cache;

    $cache = new Netscape::Cache;

    while ($o = $cache->next_object) {
        push(@url, $o);
    }
    # sort by name
    @url = sort {$a->{'URL'} cmp $b->{'URL'}} @url;
    # sort by visit time
    #@url = sort {$b->{'LAST_VISITED'} <=> $a->{'LAST_VISITED'}} @url;
    # sort by mime type
    #@url = sort {$a->{'MIME_TYPE'} cmp $b->{'MIME_TYPE'}} @url;
    # sort by size
    #@url = sort {$b->{'CACHEFILE_SIZE'} <=> $a->{'CACHEFILE_SIZE'}} @url;

    print "<ul>\n";
    foreach (@url) {
        print
          "<li><a href=\"file:",
          $cache->{'CACHEDIR'}, "/", $_->{'CACHEFILE'}, "\">",
          $_->{'URL'}, "</a> ",
	  scalar localtime $_->{'LAST_VISITED'}, "<br>",
          "type: ", $_->{'MIME_TYPE'}, 
	  ",size: ", $_->{'CACHEFILE_SIZE'}, "\n";
    }
    print "</ul>\n";

=head1 FORMAT OF index.db

Here is a short description of the format of index.db. All integers
are in VAX byte order (little endian). Time is specified as seconds
since epoch.

    Key:

    Offset  Type/Length  Description

    0       long         Length of key entry
    4       long         Length of URL with trailing \0
    8       string       URL (null-terminated)
    +0      string       filled with \0

    Value:

    Offset  Type/Length  Description

    0       long         Length of value entry
    4       long         A version number (see NS_VERSION)
    8       long         Last modified
    12      long         Last visited
    16      long         Expire date
    20      long         Size of cachefile
    24      ...          Unknown
    29      long         Length of cache filename with trailing \0
    33      string       Cache filename (null-terminated)
    +0      ...          Unknown
    +33     long         Length of mime type with trailing \0
    +37     string       Mime type (null-terminated)
    +0      long         Length of content encoding with trailing \0
    +4      string       Content encoding (null-terminated)
    +0      long         Length of charset with trailing \0
    +4      string       Charset (null-terminated)
    +0      ...          Unknown
    +1      long         Content length
    +5      long         Length of the complete URL with trailing \0
    +9      string       Complete URL (null-terminated)

=head1 ENVIRONMENT

The B<Netscape::Cache> module examines the following environment variables:

=over 4

=item HOME

Home directory of the user, used to find Netscape's preferences
(C<$HOME/.netscape>). Otherwise, if not set, retrieve the home directory
from the passwd file.

=back

=head1 BUGS

There are still some unknown fields (_XXX_FLAG_{2,3,4}).

You can't use B<delete_object> while looping with B<next_object>. See the
question "What happens if I add or remove keys from a hash while iterating
over it?" in L<perlfaq4>.

B<keys()> or B<each()> on the tied hash are slower than the object
oriented equivalents B<next_object> or B<next_url>.

=head1 SEE ALSO

L<Netscape::History>

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

Thanks to: Fernando Santagata <lac0658@iperbole.bologna.it>

=head1 COPYRIGHT

Copyright (c) 1997 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
