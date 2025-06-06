
package TUWF::Response;


use strict;
use warnings;
use Exporter 'import';
use POSIX 'strftime';
use Carp 'croak', 'carp';


our $VERSION = '1.6';
our @EXPORT = qw|
  resInit resHeader resCookie resBuffer resFd resStatus resRedirect
  resNotFound resJSON resBinary resFile resFinish
|;


# try to load PerlIO::gzip, resBuffer will check for its availability
eval { require PerlIO::gzip; };


# Initialises response data and resets all headers and content to their
# defaults. This method can be called mutliple times per request to clear
# any previous changes and to create a new response.
sub resInit {
  my $self = shift;

  $self->{_TUWF}{Res} = {
    status => 200,
    headers => [
      'Content-Type' => 'text/html; charset=UTF-8',
    ],
    cookies => {},
    content => '',
  };

  # open output buffer
  $self->resBuffer($self->{_TUWF}{content_encoding}||'auto');

  # (re)initialize TUWF::XML
  TUWF::XML->new(
    write  => sub { print { $self->resFd } $_ for @_ },
    pretty => $self->{_TUWF}{xml_pretty},
    default => 1,
  );
}


# Arguments       Action
#  name            returns list of values of the header, first found in scalar context, undef if not exists
#  name, value     sets header, overwrites existing header with same name, removes duplicates
#  name, undef     removes header
#  name, value, 1  adds header, not checking whether it already exists
# Header names are case-insensitive
sub resHeader {
  my($self, $name, $value, $add) = @_;
  my $h = $self->{_TUWF}{Res}{headers};

  if($add) {
    push @$h, $name, $value;
    return $value;
  }

  my @h;
  my @r;
  for (@$h ? 0..$#$h/2 : ()) {
    if(lc($h->[$_*2]) eq lc($name)) {
      push @h, $h->[$_*2+1];
      if(@_ == 3 && defined $value) {
        $h->[$_*2+1] = $value;
        push @r, $_ if @h > 1
      } elsif(@_ == 3) {
        push @r, $_;
      }
    }
  }

  push @$h, $name, $value if @_ == 3 && defined $value && !@h;

  splice @$h, $r[$_]*2-$_*2, 2
    for (@r ? 0..$#r : ());

  return @_ == 3 || @_ == 2 && !wantarray ? $h[0] : @h;
}


# Adds a Set-Cookie header, arguments:
# name, value, %options.
# value = undef -> remove cookie,
# options:
#   expires, path, domain, secure, httponly, maxage, samesite
sub resCookie {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my %o = ($self->{_TUWF}{cookie_defaults} ? %{$self->{_TUWF}{cookie_defaults}} : (), @_);

  $name = "$self->{_TUWF}{cookie_prefix}$name" if $self->{_TUWF}{cookie_prefix};
  my @attr = (sprintf '%s=%s', $name, defined($value)?$value:'');
  $o{expires} = 0 if !defined $value;

  push @attr, sprintf 'Expires=%s', strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime $o{expires}) if defined $o{expires};
  push @attr, "Max-Age=$o{maxage}" if defined $o{maxage};
  push @attr, "Path=$o{path}" if $o{path};
  push @attr, "Domain=$o{domain}" if $o{domain};
  push @attr, "SameSite=$o{samesite}" if $o{samesite};
  push @attr, 'Secure'   if $o{secure};
  push @attr, 'HttpOnly' if $o{httponly};
  $self->{_TUWF}{Res}{cookies}{$name} = join '; ', @attr;
}


# Argument     Action
#  none/empty   Returns output compression type: none/gzip/deflate
#  'clear'      Clears the internal buffer, but doesn't change compression method
#  'none'       Clears buffer and disables output compression
#  'gzip'       Clears and enables gzip
#  'deflate'    Clears and enables deflate
#  'auto'       Clears and autodetects output compression from request header
# Enabling compression if PerlIO::gzip isn't installed will result in an error
sub resBuffer {
  my($self, $act, $noutf8) = @_;
  my $i = $self->{_TUWF}{Res};

  my $h = $self->resHeader('Content-Encoding');
  $h = !$h ? 'none' : $h eq 'gzip' ? 'gzip' : $h eq 'deflate' ? 'deflate' : 'none';

  if($act) {
    my $new = $act eq 'clear' ? $h : $act;
    if($new eq 'auto') {
      # can we even do output compression?
      if(!defined $PerlIO::gzip::VERSION) {
        $new = 'none';
      }
      # seems like we can, figure out which encoding to use
      else {
        my $enc = $self->reqHeader('Accept-Encoding')||'';
        my $gzip = $enc !~ /gzip\s*(?:;\s*q=(\d+(?:\.\d*)?))?/ ? 0 : defined $1 ? $1 : 1;
        my $deflate = $enc !~ /deflate\s*(?:;\s*q=(\d+(?:\.\d*)?))?/ ? 0 : defined $1 ? $1 : 1;
        $new = !$gzip && !$deflate ? 'none' : $deflate > $gzip ? 'deflate' : 'gzip';
      }
    }

    # clear buffer
    close $i->{fd} if defined $i->{fd};
    $i->{content} = '';
    open $i->{fd}, '>', \$i->{content};

    # set output compression
    binmode $i->{fd}, $new eq 'gzip' ? ':gzip' : ':gzip(none)' if $new ne 'none';
    binmode $i->{fd}, ':utf8' if !($noutf8 && $noutf8 eq 'noutf8');
    $self->resHeader('Content-Encoding', $new eq 'none' ? undef : $new);
  }

  return $h;
}


# Returns the file descriptor where output functions can 'print' to
sub resFd {
  return shift->{_TUWF}{Res}{fd};
}


# Returns or sets the HTTP status
sub resStatus {
  my($self, $new) = @_;
  $self->{_TUWF}{Res}{status} = $new if $new;
  return $self->{_TUWF}{Res}{status};
}


# Redirect to an other page, accepts an URL (either relative or absolute) and
# an optional type consisting of 'temp' (temporary) or 'post' (after posting a form).
# No type argument means a permanent redirect.
sub resRedirect {
  my($self, $url, $type) = @_;

  $self->resBuffer('clear');
  my $fd = $self->resFd();
  print $fd 'Redirecting...';
  $self->resHeader('Content-Type' => 'text/plain');
  $self->resHeader('Location' => $url);
  $self->resStatus(!$type ? 301 : $type eq 'temp' ? 307 : 303);
}


sub resNotFound {
  my $self = shift;
  $self->resInit;
  $self->{_TUWF}{error_404_handler}->($self);
}


my $_json_codec;
sub resJSON {
  my($self, $obj) = @_;
  $_json_codec ||= TUWF::Misc::_JSON()->new->convert_blessed->utf8;

  $self->resHeader('Content-Type' => 'application/json; charset=UTF-8');
  $self->resBinary($_json_codec->encode($obj), 'clear');
}


sub resBinary {
  my($self, $data, $buffer) = @_;
  my $enc = $self->resBuffer($buffer//'none', 'noutf8');

  if($enc eq 'none') {
    # Write to the buffer directly if we're not compressing, avoids extra copying.
    $self->{_TUWF}{Res}{content} = $data;
  } else {
    print { $self->{_TUWF}{Res}{fd} } $data;
  }
}


sub resFile {
  my($self, $path, $fn) = @_;

  # This also catches files with '..' somewhere in the middle of the name.
  # Let's just disallow that too to simplify this check, I'd err on the side of
  # caution.
  if($fn =~ /\.\./) {
      $self->resNotFound;
      $self->done;
  }

  my $ext = $fn =~ m{\.([^/\.]+)$} ? lc $1 : '';
  my $ctype = $self->{_TUWF}{mime_types}{$ext} || $self->{_TUWF}{mime_default};
  my $compress = $ctype =~ /^text/;

  my $file = "$path/$fn";
  return 0 if !-f $file;
  open my $F, '<', $file or croak "Unable to open '$file': $!";
  {
      local $/=undef;
      $self->resBinary(scalar <$F>, $compress ? 'auto' : 'none');
  }

  $self->resHeader('Content-Type' => "$ctype; charset=UTF-8"); # Adding a charset to binary formats should be safe, too.
  return 1;
}


# Send everything we have buffered to the client
sub resFinish {
  my $self = shift;
  my $i = $self->{_TUWF}{Res};

  close $i->{fd};
  if($i->{status} == 204) {
    $self->resHeader('Content-Type' => undef);
    $self->resHeader('Content-Encoding' => undef);
  } else {
    $self->resHeader('Content-Length' => length($i->{content}));
  }

  if($self->{_TUWF}{http}) {
    printf "HTTP/1.0 %d Hi, I am a HTTP response.\r\n", $i->{status};
  } else {
    printf "Status: %d\r\n", $i->{status};
  }
  my $hdr = join "\r\n",
    (map "$i->{headers}[$_*2]: $i->{headers}[$_*2+1]", @{$i->{headers}} ? 0..$#{$i->{headers}}/2 : ()),
    (map "Set-Cookie: $i->{cookies}{$_}", keys %{$i->{cookies}});
  utf8::encode $hdr;
  print  "$hdr\r\n\r\n";
  print  $i->{content} if $self->reqMethod() ne 'HEAD' && $i->{status} != 204;

  # free the memory used for the reponse data
  $self->resInit;
}




1;


