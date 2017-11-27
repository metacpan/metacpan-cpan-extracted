
package TUWF::Request;

use strict;
use warnings;
use Encode 'decode_utf8', 'encode_utf8';
use Exporter 'import';
use Carp 'croak';

our $VERSION = '1.1';
our @EXPORT = qw|
  reqInit reqGets reqGet reqPosts reqPost reqParams reqParam
  reqUploadMIMEs reqUploadMIME reqUploadRaws reqUploadRaw reqSaveUpload
  reqCookie reqMethod reqHeader reqPath reqQuery reqProtocol reqBaseURI reqURI reqHost reqIP reqFCGI
|;


sub reqInit {
  my $self = shift;
  $self->{_TUWF}{Req} = {};

  # lighttpd doesn't always split the query string from REQUEST_URI
  if($ENV{SERVER_SOFTWARE}||'' =~ /lighttpd/) {
    ($ENV{REQUEST_URI}, $ENV{QUERY_STRING}) = split /\?/, $ENV{REQUEST_URI}, 2
      if ($ENV{REQUEST_URI}||'') =~ /\?/;
  }

  my $err = eval {
    $self->{_TUWF}{Req}{Cookies} = _parse_cookies($self, $ENV{HTTP_COOKIE} || $ENV{COOKIE});
    $self->{_TUWF}{Req}{GET} = _parse_urlencoded($ENV{QUERY_STRING});
    $self->reqPath(); # let it croak when the path isn't valid UTF-8
    1;
  };
  return 'utf8' if !$err && $@ && $@ =~ /does not map to Unicode/; # <- UGLY!
  # re-throw if it wasn't a UTF-8 problem. I don't expect this to happen
  die $@ if !$err;

  my $meth = $self->reqMethod;
  return 'method' if $meth !~ /^(GET|POST|HEAD)$/;

  if($meth eq 'POST' && $ENV{CONTENT_LENGTH}) {
    return 'maxpost' if $self->{_TUWF}{max_post_body} && $ENV{CONTENT_LENGTH} > $self->{_TUWF}{max_post_body};

    my $data;
    die "Couldn't read all POST data.\n" if $ENV{CONTENT_LENGTH} > read STDIN, $data, $ENV{CONTENT_LENGTH}, 0;

    $err = eval {
      if(($ENV{'CONTENT_TYPE'}||'') =~ m{^multipart/form-data; boundary=(.+)$}) {
        _parse_multipart($self, $data, $1);
      } else {
        $self->{_TUWF}{Req}{POST} = _parse_urlencoded($data);
      }
      1;
    };
    return 'utf8' if !$err && $@ && $@ =~ /does not map to Unicode/;
    die $@ if !$err;
  }

  return '';
}


sub _parse_urlencoded {
  my %dat;
  my $d = shift;
  for (split /[;&]/, decode_utf8 $d, 1) {
    my($key, $val) = split /=/, $_, 2;
    next if !defined $key or !defined $val;
    for ($key, $val) {
      s/\+/ /gs;
      # assume %XX sequences represent UTF-8 bytes and properly decode it.
      s#((?:%[0-9a-fA-F]{2})+)#
        (my $s=encode_utf8 $1) =~ s/%(.{2})/chr hex($1)/eg;
        decode_utf8($s, 1);
      #eg;
      s/%u([0-9a-fA-F]{4})/chr hex($1)/eg;
    }
    push @{$dat{$key}}, $val;
  }
  return \%dat;
}


# Heavily inspired by CGI::Minimal::Multipart::_burst_multipart_buffer()
sub _parse_multipart {
  my($self, $data, $boundary) = @_;
  my $nfo = $self->{_TUWF}{Req};
  my $CRLF = "\015\012";

  $nfo->{POST} = {};
  $nfo->{FILES} = {};
  $nfo->{MIMES} = {};

  for my $p (split /--\Q$boundary\E(?:--)?$CRLF/, $data) {
    next if !defined $p;
    $p =~ s/$CRLF$//;
    last if $p eq '--';
    next if !$p;
    my($header, $value) = split /$CRLF$CRLF/, $p, 2;

    my($name, $mime, $filename) = ('', '', '');
    for my $h (split /$CRLF/, $header) {
      my($hn, $hv) = split /: /, $h, 2;
      # Does not handle multipart/mixed, but those don't appear to be used in practice.
      if($hn =~ /^Content-Type$/i) {
        $mime = $hv;
      }
      if($hn =~ /^Content-Disposition$/i) {
        for my $dis (split /; /, $hv) {
          $name     = $2 if $dis =~ /^name=("?)(.*)\1$/;
          $filename = $2 if $dis =~ /^filename=("?)(.*)\1$/;
        }
      }
    }

    $name = decode_utf8 $name, 1;

    # In the case of a file upload, use the filename as value instead of the
    # data. This is to ensure that reqPOST() always returns decoded data.

    # Note that I use the presence of a filename attribute for determining
    # whether this parameters comes from an <input type="file"> rather than a
    # regular form element. The standards do not require the filename to be
    # present, but I am not aware of any browser that does not send it.
    if($filename) {
      push @{$nfo->{POST}{$name}}, decode_utf8 $filename, 1;
      push @{$nfo->{MIMES}{$name}}, decode_utf8 $mime, 1;
      push @{$nfo->{FILES}{$name}}, $value; # not decoded, can be binary
    } else {
      push @{$nfo->{POST}{$name}}, decode_utf8 $value, 1;
    }
  }
}


sub _parse_cookies {
  my($self, $str) = @_;
  return {} if !$str;

  my %dat;
  # The format of the Cookie: header is hardly standardized and the widely used
  # implementations all differ in how they interpret the data. This (rather)
  # lazy implementation assumes the cookie values are not escaped and don't
  # contain any characters that are used within the header format.
  for (split /[;,]/, decode_utf8 $str, 1) {
    s/^ +//;
    s/ +$//;
    next if !$_ || !m{^([^\(\)<>@,;:\\"/\[\]\?=\{\}\t\s]+)=("?)(.*)\2$};
    my($n, $v) = ($1, $3);
    next if $self->{_TUWF}{cookie_prefix} && !($n =~ s/^\Q$self->{_TUWF}{cookie_prefix}\E//);
    $dat{$n} = $v if !exists $dat{$n};
  }
  return \%dat;
}


sub _tablegets {
  my($k, $s, $n) = @_;
  my $lst = $s->{_TUWF}{Req}{$k};
  return keys %$lst if @_ == 2;
  return $lst->{$n} ? @{$lst->{$n}} : ();
}


sub _tableget {
  my($k, $s, $n) = @_;
  my $v = $s->{_TUWF}{Req}{$k}{$n};
  return $v ? $v->[0] : undef;
}


sub reqGets        { _tablegets(GET => @_) }
sub reqGet         { _tableget (GET => @_) }
sub reqPosts       { _tablegets(POST => @_) }
sub reqPost        { _tableget (POST => @_) }
sub reqUploadMIMEs { _tablegets(MIMES => @_) }
sub reqUploadMIME  { _tableget (MIMES => @_) }
sub reqUploadRaws  { _tablegets(FILES => @_) }
sub reqUploadRaw   { _tableget (FILES => @_) }


# get parameters from either or both POST and GET
# (POST has priority over GET in scalar context)
sub reqParams {
  my($s, $n) = @_;
  my $nfo = $s->{_TUWF}{Req};
  if(!$n) {
    my %keys = map +($_,1), keys(%{$nfo->{GET}}), keys(%{$nfo->{POST}});
    return keys %keys;
  }
  return (
    $nfo->{POST}{$n} ? @{$nfo->{POST}{$n}} : (),
    $nfo->{GET}{$n}  ? @{$nfo->{GET}{$n}}  : (),
  );
}


# (POST has priority over GET in scalar context)
sub reqParam {
  my($s, $n) = @_;
  my $nfo = $s->{_TUWF}{Req};
  return [
    $nfo->{POST}{$n} ? @{$nfo->{POST}{$n}} : (),
    $nfo->{GET}{$n}  ? @{$nfo->{GET}{$n}}  : (),
  ]->[0];
}


# saves file contents identified by the form name to the specified file
# (doesn't support multiple file upload using the same form name yet)
sub reqSaveUpload {
  my($s, $n, $f) = @_;
  open my $F, '>', $f or croak "Unable to write to $f: $!";
  print $F $s->reqUploadRaw($n);
  close $F;
}


sub reqCookie {
  my($self, $n) = @_;
  my $nfo = $self->{_TUWF}{Req}{Cookies};
  return keys %$nfo if @_ == 1;
  return $nfo->{$n};
}


sub reqMethod {
  return $ENV{REQUEST_METHOD}||'GET';
}


# Returns list of header names when no argument is passed
#   (may be in a different order and can have different casing than
#    the original headers - CGI doesn't preserve that information)
# Returns value of the specified header otherwise, header name is
#   case-insensitive
sub reqHeader {
  my($self, $name) = @_;
  if(@_ == 2) {
    (my $v = uc $_[1]) =~ tr/-/_/;
    return $ENV{"HTTP_$v"}||'';
  } else {
    return (map {
      if(/^HTTP_/) { 
        (my $h = lc $_) =~ s/_([a-z])/-\U$1/g;
        $h =~ s/^http-//;
        decode_utf8 $h, 1;
      } else { () }
    } sort keys %ENV);
  }
}


# returns the path part of the current URI, including the leading slash
sub reqPath {
  (my $u = ($ENV{REQUEST_URI}||'')) =~ s{\?.*$}{};
  return decode_utf8 $u, 1;
}


sub reqProtocol {
  return $ENV{HTTPS} ? 'https' : 'http';
}


# returns base URI, excluding trailing slash
sub reqBaseURI {
  my $s = shift;
  return $s->reqProtocol().'://'.$s->reqHost();
}


sub reqQuery {
  my $u = $ENV{QUERY_STRING} ? '?'.$ENV{QUERY_STRING} : '';
  return decode_utf8 $u, 1;
}


sub reqURI {
  my $s = shift;
  return $s->reqBaseURI().$s->reqPath().$s->reqQuery();
}


sub reqHost {
  return $ENV{HTTP_HOST}||'localhost';
}


sub reqIP {
  return $ENV{REMOTE_ADDR}||'0.0.0.0';
}


sub reqFCGI {
  return shift->{_TUWF}{fcgi_req};
}

1;
