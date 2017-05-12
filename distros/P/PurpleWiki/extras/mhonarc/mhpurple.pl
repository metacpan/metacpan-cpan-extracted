## mhpurple.pl
# vi:ai:et:sm:sw=4:ts=4
##
## Based on mhtxtplain.pl 2.14 01/04/10 21:36:41
## Requires MHonArc 2.5.x
##
## Eugene Eric Kim <eekim@eekim.com>
## http://www.eekim.com/software/mhonarc/#mhpurple
##
## $Id: mhpurple.pl,v 1.1 2004/02/07 04:04:40 cdent Exp $
##
## Copyright (c) Eugene Eric Kim 2000-2001.  All rights reserved.
##
## Filters text/plain body parts to HTML for MHonArc.  Adds purple numbers
## for granular addressability.  Extracts links and appends to link
## database if custom resources LINKBASE and BASEURL are defined.
##
## Links are saved to LINKBASE as a tab delimited file.  Link information
## is stored as:
##
##   fromlink    tolink    linktype    email    date
##
## where each value is separated by a tab.
##
## Filter routine can be registered with the following:
##   <MIMEFilters>
##   text/plain; m2h_purple::filter; /path/to/mhpurple.pl
##   </MIMEFilters>
##---------------------------------------------------------------------------##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
##    02111-1307, USA
##---------------------------------------------------------------------------##

package m2h_purple;

use lib '/home/cdent/src/PurpleWiki.remote';
use PurpleWiki::Sequence;

require 'readmail.pl';

$Url        = '(?:http://|https://|ftp://|afs://|wais://|telnet://|ldap://' .
           '|gopher://|news:|nntp:|mid:|cid:|prospero:)';
$UrlExp     = $Url . q/[^\s\(\)\|<>"']*[^\.?!;,"'\|\[\]\(\)\s<>]/;
$HUrlExp        = $Url . q/(?:&(?![gl]t;)|[^\s\(\)\|<>"'\&])+/ .
             q/[^\.?!;,"'\|\[\]\(\)\s<>\&]/;
$QuoteChars = '[>\|\]+:]';
$HQuoteChars    = '&gt;|[\|\]+:]';

##---------------------------------------------------------------------------##
##  Text/plain filter for mhonarc.  The following filter arguments
##  are recognized ($args):
##
##  asis=set1:set2:...
##          Colon separated lists of charsets to leave as-is.
##          Only HTML special characters will be converted into
##          entities.  The default value is "us-ascii:iso-8859-1".
##
##  attachcheck Honor attachment disposition.  By default,
##          all text/plain data is displayed inline on
##          the message page.  If attachcheck is specified
##          and Content-Disposition specifies the data as
##          an attachment, the data is saved to a file
##          with a link to it from the message page.
##
##  default=set     Default charset to use if not set.
##
##      inlineexts="ext1,ext2,..."
##                      A comma separated list of message specified filename
##                      extensions to treat as inline data.
##                      Applicable only when uudecode options specified.
##
##  htmlcheck   Check if message is actually an HTML message
##          (to get around abhorrent MUAs).  The message
##          is treated as HTML if the first non-whitespace
##          data looks like the start of an HTML document.
##
##  keepspace   Preserve whitespace if nonfixed
##
##  nourl       Do hyperlink URLs
##
##  nonfixed    Use normal typeface
##
##  maxwidth=#  Set the maximum width of lines.  Lines exceeding
##          the maxwidth will be broken up across multiple lines.
##
##  quote       Italicize quoted message text
##
##  target=name     Set TARGET attribute for links if converting URLs
##          to links.  Defaults to _top.
##
##  usename     Use filename specified in uuencoded data when
##          converting uuencoded data.  This option is only
##          applicable of uudecode is specified.
##
##  uudecode    Decoded any embedded uuencoded data.
##
##  purple      Add purple numbers to content
##
##  All arguments should be separated by at least one space
##
sub filter {
    my($fields, $data, $isdecode, $args) = @_;
    local($_);

    ## Parse arguments
    $args   = ""  unless defined($args);

    ## Check if content-disposition should be checked
    if ($args =~ /\battachcheck\b/i) {
    my($disp, $nameparm) = readmail::MAILhead_get_disposition($fields);
    if ($disp =~ /\battachment\b/i) {
        require 'mhexternal.pl';
        return (m2h_external::filter(
              $fields, $data, $isdecode,
              readmail::get_filter_args('m2h_external::filter')));
    }
    }

    ## Check if decoding uuencoded data.  The implementation chosen here
    ## for decoding uuencoded data was done so when uudecode is not
    ## specified, there is no extra overhead (besides the $args check for
    ## uudecode).  However, when uudecode is specified, more overhead may
    ## exist over other potential implementations.
    ## I.e.  We only try to penalize performance when uudecode is specified.
    if ($args =~ s/\buudecode\b//ig) {
    # $args has uudecode stripped out for recursive calls

    # Make sure we have needed routines
    my $decoder = readmail::load_decoder("uuencode");
    if (!defined($decoder) || !defined(&$decoder)) {
        require 'base64.pl';
        $decoder = \&base64::uudecode;
    }
    require 'mhmimetypes.pl';

    # Grab any filename extensions that imply inlining
    my $inlineexts = '';
    if ($args =~ /\binlineexts=(\S+)/) {
        $inlineexts = ',' . lc($1) . ',';
        $inlineexts =~ s/['"]//g;
    }
    my $usename = $args =~ /\busename\b/;

    my($pdata); # have to use local() since typeglobs used
    my($inext, $uddata, $file, $urlfile);
    my @files = ( );
    my $ret = "";
    my $i = 0;

    # Split on uuencoded data.  For text portions, recursively call
    # filter to convert text data: makes it easier to handle all
    # the various formatting options.
    foreach $pdata
        (split(/^(begin \d\d\d \S+\n[!-M].*?\nend\n)/sm, $$data)) {
        if ($i % 2) {   # uuencoded data
        # extract filename extension
        ($file) = $pdata =~ /^begin \d\d\d (\S+)/;
        if ($file =~ /\.(\w+)$/) { $inext = $1; } else { $inext = ""; }

        # decode data
        $uddata = &$decoder($pdata);

        # save to file
        if (readmail::MAILis_excluded('application/octet-stream')) {
            $ret .=
            "<tt>&lt;&lt;&lt; $file: EXCLUDED &gt;&gt;&gt;</tt><br>\n";
        } else {
            push(@files,
             mhonarc::write_attachment(
                'application/octet-stream', \$uddata, '',
                ($usename?$file:''), $inext));
            $urlfile = mhonarc::htmlize($files[$#files]);

            # create link to file
            if (index($inlineexts, ','.lc($inext).',') >= $[) {
            $ret .= qq|<a href="$urlfile"><img src="$urlfile">| .
                qq|</a><br>\n|;
            } else {
            $ret .= qq|<a href="$urlfile">| .
                mhonarc::htmlize($file) .  qq|</a><br>\n|;
            }
        }

        } elsif ($pdata =~ /\S/) {  # plain text
        my(@subret) = filter($fields, \$pdata, $isdecode, $args);
        $ret .= shift @subret;
        push(@files, @subret);
        } else {
        # Make sure readmail thinks we processed
        $ret .= " ";
        }
        ++$i;
    }

    ## Done with uudecode
    return ($ret, @files);
    }

    
    ## Check for HTML data if requested
    if ($args =~ s/\bhtmlcheck\b//i &&
        $$data =~ /\A\s*<(?:html\b|x-html\b|!doctype\s+html\s)/i) {
    my $html_filter = readmail::load_filter('text/html');
    if (defined($html_filter) && defined(&$html_filter)) {
        return (&$html_filter($fields, $data, $isdecode, $args));
    } else {
        require 'mhtxthtml.pl';
        return (m2h_text_html::filter($fields, $data, $isdecode, $args));
    }
    }

    my($charset, $nourl, $doquote, $igncharset, $nonfixed,
       $keepspace, $maxwidth, $target, $defset, $xhtml);
    my(%asis) = (
    'us-ascii'   => 1,
    'iso-8859-1' => 1,
    );

    $nourl  = ($mhonarc::NOURL || ($args =~ /\bnourl\b/i));
    $doquote    = ($args =~ /\bquote\b/i);
    $nonfixed   = ($args =~ /\bnonfixed\b/i);
    $keepspace  = ($args =~ /\bkeepspace\b/i);
    if ($args =~ /\bmaxwidth=(\d+)/i) { $maxwidth = $1; }
    else { $maxwidth = 0; }
    if ($args =~ /\bdefault=(\S+)/i) { $defset = lc $1; }
    else { $defset = 'us-ascii'; }
    $target = "";
    if ($args =~ /\btarget="([^"]+)"/i) { $target = $1; }
    elsif ($args =~ /\btarget=(\S+)/i) { $target = $1; }
    $target =~ s/['"]//g;
    if ($target) {
    $target = qq/target="$target"/;
    }
    $defset =~ s/['"\s]//g;

    ## Grab charset parameter (if defined)
    if ( defined($fields->{'content-type'}[0]) and
     $fields->{'content-type'}[0] =~ /\bcharset\s*=\s*([^\s;]+)/i ) {
    $charset = lc $1;
    $charset =~ s/['";\s]//g;
    } else {
    $charset = $defset;
    }

    ## Check if certain charsets should be left alone
    if ($args =~ /\basis=(\S+)/i) {
    my $t = lc $1;  $t =~ s/['"]//g;
    %asis = ('us-ascii' => 1);  # XXX: Should us-ascii always be "as-is"?
    local($_);  foreach (split(':', $t)) { $asis{$_} = 1; }
    }

    ## Check MIMECharSetConverters if charset should be left alone
    my $charcnv = &readmail::load_charset($charset);
    if (defined($charcnv) && $charcnv eq '-decode-') {
    $asis{$charset} = 1;
    }

    ## Check if max-width set
    if ($maxwidth) {
    $$data =~ s/^(.*)$/&break_line($1, $maxwidth)/gem;
    }

    ## Convert data according to charset
    if (!$asis{$charset}) {
    # Japanese we have to handle directly to support nourl flag
    if ($charset =~ /iso-2022-jp/) {
        require "iso2022jp.pl";
        if ($nonfixed) {
        return (&iso_2022_jp::jp2022_to_html($$data, $nourl));
        } else {
        return ('<pre>' .
            &iso_2022_jp::jp2022_to_html($$data, $nourl).
            '</pre>');
        }

    # Registered in CHARSETCONVERTERS
    } elsif (defined($charcnv) && defined(&$charcnv)) {
        $$data = &$charcnv($$data, $charset);

    # Other
    } else {
        warn qq/Warning: Unrecognized character set: $charset\n/;
        esc_chars_inplace($data);
    }

    } else {
    esc_chars_inplace($data);
    }

    ## Check for purple numbers; extract back-links
    if ($args =~ /\bpurple\b/i) {
        my $sequence = '';
        my $remote = 0;
        if ($mhonarc::CustomRcVars{'SEQUENCE'}) {
            $sequence = $mhonarc::CustomRcVars{'SEQUENCE'};
        }
        if ($mhonarc::CustomRcVars{'REMOTESEQUENCE'}) {
            $sequence = $mhonarc::CustomRcVars{'REMOTESEQUENCE'};
            $remote = 1;
        }
        $$data = &add_purple($$data,
                     &get_link_metadata($fields->{'message-id'}[0]),
                     $sequence, $remote);
    }

    ##  Check for quoting
    if ($doquote) {
        $$data =~ s@^( ?${HQuoteChars})(.*)$@$1<I>$2</I>@gom;
    }

    ## Check if using nonfixed font
    if ($nonfixed) {
        $$data =~ s/(\r?\n)/<br>$1/g;
        if ($keepspace) {
            $$data =~ s/^(.*)$/&preserve_space($1)/gem;
        }
    } else {
        $$data = "<pre>\n" . $$data . "</pre>\n";
    }

    ## Convert URLs to hyperlinks
    $$data =~ s@($HUrlExp)@<A $target HREF="$1">$1</A>@gio
    unless $nourl;

    ($$data);
}

##---------------------------------------------------------------------------##

sub esc_chars_inplace {
    my($foo) = shift;
    $$foo =~ s/&/&amp;/g;
    $$foo =~ s/</&lt;/g;
    $$foo =~ s/>/&gt;/g;
    $$foo =~ s/"/&quot;/g;
    1;
}

sub unesc_chars_inplace {
    my($foo) = shift;
    $$foo =~ s/&amp;/&/g;
    $$foo =~ s/&lt;/</g;
    $$foo =~ s/&gt;/>/g;
    $$foo =~ s/&quot;/"/g;
    1;
}

##---------------------------------------------------------------------------##

sub preserve_space {
    my($str) = shift;

    1 while
    $str =~ s/^([^\t]*)(\t+)/$1 . ' ' x (length($2) * 8 - length($1) % 8)/e;
    $str =~ s/ /\&nbsp;/g;
    $str;
}

##---------------------------------------------------------------------------##

sub break_line {
    my($str) = shift;
    my($width) = shift;
    my($q, $new) = ('', '');
    my($try, $trywidth, $len);

    ## Translate tabs to spaces
    1 while
    $str =~ s/^([^\t]*)(\t+)/$1 . ' ' x (length($2) * 8 - length($1) % 8)/e;

    ## Do nothing if str <= width
    return $str  if length($str) <= $width;

    ## See if str begins with a quote char
    if ($str =~ s/^( ?$QuoteChars)//o) {
    $q = $1;
    --$width;
    }

    ## Create new string by breaking up str
    while ($str ne "") {

    # If $str less than width, break out
    if (length($str) <= $width) {
        $new .= $q . $str;
        last;
    }

    # handle case where no-whitespace line larger than width
    if (($str =~ /^(\S+)/) && (($len = length($1)) >= $width)) {
        $new .= $q . $1;
        substr($str, 0, $len) = "";
        next;
    }

    # Break string at whitespace
    $try = '';
    $trywidth = $width;
    $try = substr($str, 0, $trywidth);
    if ($try =~ /(\S+)$/) {
        $trywidth -= length($1);
        $new .= $q . substr($str, 0, $trywidth);
    } else {
        $new .= $q . $try;
    }
    substr($str, 0, $trywidth) = '';

    } continue {
    $new .= "\n"  if $str;
    }
    $new;
}

##---------------------------------------------------------------------------##

sub get_link_metadata {
    my $messageIdField = shift;
    my ($messageUrl, $linkBase, $responseTo);
    my ($baseUrl, $index, $messageId, $responseToNum, $responseToUrl);
    my ($email, $date);

    $linkBase = $mhonarc::CustomRcVars{'LINKBASE'};
    $baseUrl = $mhonarc::CustomRcVars{'BASEURL'};
    if ($linkBase && $baseUrl) {
        $baseUrl .= '/' if ($baseUrl !~ m/\/$/);
        $messageUrl = $baseUrl . $mhonarc::MsgPrefix . $mhonarc::MHAmsgnum .
            '.' . $mhonarc::HtmlExt;
        # in-response-to?
        $messageIdField =~ m/^<([^>]+)>$/;
        $messageId = $1;
        $index = $mhonarc::MsgId{$messageId};
        $email = &mhonarc::extract_email_address($mhonarc::From{$index});
        $date = (split(/$mhonarc::X/, $index))[0];
        if (defined($mhonarc::Refs{$index}) &&
              scalar(@{$mhonarc::Refs{$index}})) {
            $responseTo = $mhonarc::IndexNum{
                  $mhonarc::MsgId{$mhonarc::Refs{$index}->[-1]} };
            if (defined $responseTo) {
                $responseToNum = &mhonarc::fmt_msgnum($responseTo);
                $responseToUrl = $baseUrl . $mhonarc::MsgPrefix .
                    $responseToNum . '.' . $mhonarc::HtmlExt;
            }
        }
    }
    return ($linkBase, $messageUrl, $responseToUrl, $email, $date);
}

sub add_purple {
    my ($str, $linkBase, $messageUrl, $responseToUrl, $email, $date,
        $sequence, $remote) = @_;
    my $nid;
    my $newp = 1;
    my $newstr;
    my @linklist;
    my %links;
    my $currentUrl;

    if (!defined($sequence)) {
        die "SEQUENCE or REMOTESEQUENCE must be defined";
    }

    if ($remote) {
        $sequence = new PurpleWiki::Sequence(undef, $sequence);
    } else {
        $sequence = new PurpleWiki::Sequence($sequence);
    }
    $nid = $sequence->getNext($currentUrl);

    my @lines = split(/\n/, $str);
    foreach my $line (@lines) {
        if ($line =~ /^\s*$/) {
            if (!$newp) {
                $newstr =~ s/\n$//;
                $newstr .= ' &nbsp;&nbsp; ';
                $newstr .= qq{<a class="nid" title="$nid" href="#nid$nid">($nid)</a>\n};
                $newp = 1;
                $nid = $sequence->getNext($messageUrl);
                $currentUrl = $messageUrl;
            }
            $newstr .= "\n";
        } else {
            if ($newp) {
                $newstr .= qq{<a name="nid$nid" id="nid$nid"></a>};
                $newp = 0;
                $currentUrl .= "#nid$nid" if ($messageUrl);
            }
            $newstr .= "$line\n";
            if ($messageUrl) {
                @linklist = ($line =~ m/($HUrlExp)/iog);
                foreach (@linklist) {
                    $links{$currentUrl} = $_;
                    &unesc_chars_inplace(\$links{$currentUrl});
                }
            }
        }
    }
    if (!$newp) {
        $newstr =~ s/\n$//;
        $newstr .= ' &nbsp;&nbsp; ';
        $newstr .= qq{<a class="nid" title="$nid" href="#nid$nid">($nid)</a>\n};
    }
    &write_linkbase($linkBase, $messageUrl, $responseToUrl, $email, $date,
                    \%links) if ($messageUrl);
    return $newstr;
}

sub write_linkbase {
    my ($fname, $messageUrl, $responseToUrl, $email, $date, $links) = @_;

    if (open FH, ">>$fname") {
#        print "+" if (%{$links});
        foreach my $fromlink (keys %{$links}) {
            print FH "$fromlink\t" . $links->{$fromlink} . "\thtml\t$email\t$date\n";
        }
        print FH "$messageUrl\t$responseToUrl\temailresponse\t$email\t$date\n"
            if (defined $responseToUrl);
        close(FH);
        chmod 0644, $fname;
    }
}

##---------------------------------------------------------------------------##
1;
