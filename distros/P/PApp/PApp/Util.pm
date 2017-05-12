##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Util - various utility functions that didn't fit anywhere else

=head1 SYNOPSIS

   use PApp::Util;

=head1 DESCRIPTION

This module offers various utility functions that cannot be grouped into
other categories easily.

=over 4

=cut

package PApp::Util;

use Carp;
use URI;
use Socket ();
use JSON::XS;

use base 'Exporter';

BEGIN {
   $VERSION = 2.1;
   @EXPORT = qw(dumpval uniq);
   @EXPORT_OK = qw(
         format_source sv_peek sv_dump
         digest dumpval
         append_string_hash
         find_file fetch_uri load_file
         mime_header nonce alnumbits
   );

   # I was lazy, all the util xs functions are in PApp.xs
   require XSLoader;
   XSLoader::load PApp, $VERSION unless defined &PApp::bootstrap;
}

=item format_source $source

Formats a file supposed to be some "sourcecode" (e.g. perl, papp, xslt etc..)
into formatted ascii. It includes line numbering at the front of each line and
handles embedded "#line" markers.

=cut

sub format_source($) {
   my $data = shift;
   my $s = 1;
   $data =~ s{
      ^(?=\#line\ (\d+))?
   }{
      if ($1) {
         $s = $1;
         "\n";
      } else {
         sprintf "%03d: ", $s++
      }
   }gemx;
   $data;
}

=item dumpval any-perl-ref

Tries to dump the given perl-ref into a nicely-formatted
human-readable-format (currently uses either Data::Dumper or Dumpvalue)
but tries to be I<very> robust about internal errors, i.e. this functions
always tries to output as much usable data as possible without die'ing.

=cut

sub dumpval {
   eval {
      local $SIG{__DIE__};
      my $d;
      if (1) {
         require Data::Dumper;
         $d = new Data::Dumper([$_[0]], ["*var"]);
         $d->Terse(1);
         $d->Indent(2);
         $d->Quotekeys(0);
         $d->Useqq(1);
         #$d->Bless(...);
         $d->Seen($_[1]) if @_ > 1;
         $d = $d->Dump();
      } else {
         local *STDOUT;
         local *PApp::output;
         tie *STDOUT, PApp::Catch_STDOUT;

         require Dumpvalue;
         $d = new Dumpvalue globPrint => 1, compactDump => 0, veryCompact => 0;
         $d->dumpValue($_[0]);
         $d = $PApp::output;
      }
      $d =~ s/([\x00-\x07\x09\x0b\x0c\x0e-\x1f])/sprintf "\\x%02x", ord($1)/ge;
      $d;
   } || "[unable to dump $_[0]: '$@']";
}

=item $ref = decode_json $json

Converts a JSON string into the corresponding perl data structure.

=cut

*decode_json = \&JSON::XS::decode_json;

=item $json = encode_json $ref

Converts a perl data structure into its JSON representation.

=cut

*encode_json = \&JSON::XS::encode_json;

=item digest(args...)

Calculate a SHA1 digest and return it base64-encoded. The result will
always be 27 characters long.

=cut

sub digest {
   require Digest::SHA1;
   goto &Digest::SHA1::sha1_base64;
}

=item append_string_hash $hashref1, $hashref2

Appends all the strings found in $hashref2 to the respective keys in
$hashref1 (e.g. $h1->{key} .= $h2->{key} for all keys).

=cut

sub append_string_hash($$) {
   my ($h1, $h2) = @_;
   while (my ($k, $v) = each %$h2) {
      $h1->{$k} .= $h2->{$k};
   }
   $h1;
}

=item @ = uniq @array

Returns all the elements that are unique inside the array. The elements
must be strings, or at least must stringify sensibly.

=cut

sub uniq {
   my %seen;

   grep !$seen{$_}++, @_
}

=item sv_peek $sv

=item sv_dump $sv

Returns a very verbose dump of the internals of the given sv. Calls the
C<sv_peek> (C<sv_dump>) core function. If you don't know what I am talking
about then this function is not for you. Or maybe you should try it.

=item fetch_uri $uri

Tries to fetch the document specified by C<$uri>, returning C<undef>
on error. As a special "goody", uri's of the form "data:,body" will
immediately return the body part.

=cut

sub fetch_uri {
   my ($uri, $head) = @_;
   if ($uri =~ m%^/|^file:///%i) {
      # simple file URI
      $uri = URI->new($uri, "file")->file;
      return -f $uri if $head;
      local($/,*FILE);
      open FILE, "<", $uri or return ();
      return <FILE>;
   } elsif ($uri =~ s/^data:,//i) {
      return 1 if $head;
      return $uri;
   } else {
      require LWP::Simple;
      return LWP::Simple::head($uri) if $head;
      return LWP::Simple::get($uri);
   }
}

=item find_file $uri [, \@extensions] [, @bases]

Try to locate the specified document. If the uri is a relative uri (or a
simple unix path) it will use the URIs in C<@bases> and PApp's search path
to locate the file. If bases contain an arrayref than this arrayref should
contain a list of extensions (without a leading dot) to append to the URI
while searching the file.

=cut

sub find_file {
   my $file = shift;
   my @ext;
   my %seen;
   for my $path (@_, PApp::Config::search_path) {
      if (ref $path eq "ARRAY") {
         @ext = map ".$_", @$path;
      } else {
         for my $ext ("", @ext) {
            my $uri = URI->new_abs("$file$ext", "$path/");
            next if $seen{"$uri"}++; # optimization, probably not worth the effort
            return $uri if fetch_uri $uri, 1;
         }
      }
   }
   ();
}

=item load_file $uri [, @extensions]

Locate the document specified by the given uri using C<find_file>, then
fetch and return it's contents using C<fetch_uri>.

=cut

sub load_file {
   my $path = &find_file
      or return;
   return fetch_uri $path;
}

=item mime_header $text

Takes text and transforms it to a mime message header suitable for message
headers. If the text is US-ASCII it will be returned unchanged, otherwise
it will be encoded according to RFC 2047 (it will be split into multiple
CRLF-Tab-separated components of no longer than 75 characters, with the
first component not be longer than 40 characters).

=cut

sub mime_header($) {
   my ($text) = @_;

   return $text if $text =~ /^[\x20-\x7e]{0,40}$/
                   and $text !~ /=\?/;

   my $enc;
   my $fraglen = 40;
   my @frag;

   while (length $text) {
      my $len = $fraglen;
      my $frag;

      for (;;) {
         $frag = substr $text, 0, $len;

         if ($frag =~ /^[\x20-\xff]+$/) {
            # latin-1 only
            $enc = "iso-8859-1";
         } else {
            utf8::encode $frag;
            $enc = "utf-8";
         }

         $frag =~ s/([^\x21-\x3c\x3e\x40-\x7e])/sprintf "=%02X", ord $1/ge;

         $frag = "=?$enc?q?$frag?=";

         last if length $frag < $fraglen;

         $len--; # fragment too long
      }

      push @frag, $frag;
      $fraglen = 75;

      substr $text, 0, $len, "";
   }

   join "\015\012\011", @frag;
}

=item ntoa $bin

=item aton $text

Same as inet_ntoa/inet_aton, but works on (numerical) IPv4 and IPv6
addresses.

ipv6 not yte implemented

=cut

*ntoa = \&Socket::inet_ntoa;
*aton = \&Socket::inet_aton;

=back

=head2 Source Filtering

A very primitive form of source filtering can be implemented using
C<filter_add>, C<filter_read> and C<filter_simple>. Better use the
L<Filter> module family, though.

=over 4

=cut

sub filter_simple(&) {
   my $cb = $_[0];
   my $buf;

   sub {
      unless (defined $buf) {
         local $_ = "";
         1 while 0 > ($buf = PApp::Util::filter_read $_[0] + 1, $_, 65536);
         return $buf if $buf < 0;

         &$cb;

         $buf = $_;
      }

      my $len;

      if ($_[2]) {
         $len = $_[2];
      } else {
         $len = index $buf, $/;
         $len = $len < 0 ? length $buf : $len + length $/;
      }

      $_[1] .= substr $buf, 0, $len, "";
      return length $_[1];
   }
}

# internal benchmark funs

sub bench(;$) {
   use Time::HiRes 'time';
   if (@_) {
      push @bench, time, $_[0];
   } else {
      @bench = (time, "BEGIN");
   }
}

sub benchlog {
   my $log;
   push @bench, time;
   my $time = shift @bench;
   while (@bench) {
      $log .= sprintf "%s - %.3f - ", shift @bench, $bench[0]-$time;
      $time = shift @bench;
   }
   warn sprintf "%.3f: %s\n",(time-$NOW),$log;
}

=item nonce $octet_count

Return a nonce suitable for cryptographically.

=cut

sub nonce($) {
   my $nonce;

   if (open my $fh, "</dev/urandom") {
      sysread $fh, $nonce, $_[0];
   } else {
      $nonce = join "", map +(chr rand 256), 1 .. $_[0]
   }

   $nonce
}

=item alnumbits $octets

Convert the given octet string into a human-readable ascii text, using
only a-zA-Z0-9 characters (base62 encoding).

=cut

sub alnumbits($) {
   my $data = $_[0];

   if (eval "use Math::GMP 2.05; 1") {
      $data = Math::GMP::get_str_gmp (
                  (Math::GMP::new_from_scalar_with_base (+(unpack "H*", $data), 16)),
                  62
              );
   } else {
      require MIME::Base64;

      $data = MIME::Base64::encode_base64 ($data, "");
      $data =~ s/=//;
      $data =~ s/x/x0/g;
      $data =~ s/\//x1/g;
      $data =~ s/\+/x2/g;
   }

   $data
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut


