
package TUWF::Response;


use strict;
use warnings;
use Exporter 'import';
use POSIX 'strftime';


our $VERSION = '1.1';
our @EXPORT = qw|
  resInit resHeader resCookie resBuffer resFd resStatus resRedirect resNotFound resFinish
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
#   expires, path, domain, secure, httponly
sub resCookie {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my %o = ($self->{_TUWF}{cookie_defaults} ? %{$self->{_TUWF}{cookie_defaults}} : (), @_);

  $name = "$self->{_TUWF}{cookie_prefix}$name" if $self->{_TUWF}{cookie_prefix};
  my @attr = (sprintf '%s=%s', $name, defined($value)?$value:'');
  $o{expires} = 0 if !defined $value;

  push @attr, sprintf 'expires=%s', strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime $o{expires}) if defined $o{expires};
  push @attr, "path=$o{path}" if $o{path};
  push @attr, "domain=$o{domain}" if $o{domain};
  push @attr, 'secure'   if $o{secure};
  push @attr, 'httponly' if $o{httponly};
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
  my $self = shift;
  my $act = shift;
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
    binmode $i->{fd}, ':utf8';
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


# Redirect to an other page, accepts an URL (relative to current hostname) and
# an optional type consisting of 'temp' (temporary) or 'post' (after posting a form).
# No type argument means a permanent redirect.
sub resRedirect {
  my($self, $url, $type) = @_;

  $self->resInit;
  my $fd = $self->resFd();
  print $fd 'Redirecting...';
  $self->resHeader('Location' => $self->reqBaseURI().$url);
  $self->resStatus(!$type ? 301 : $type eq 'temp' ? 307 : 303);
}


sub resNotFound {
  my $self = shift;
  $self->resInit;
  $self->{_TUWF}{error_404_handler}->($self);
}


# Send everything we have buffered to the client
sub resFinish {
  my $self = shift;
  my $i = $self->{_TUWF}{Res};

  close $i->{fd};
  $self->resHeader('Content-Length' => length($i->{content}));

  printf "Status: %d\r\n", $i->{status};
  printf "%s: %s\r\n", $i->{headers}[$_*2], $i->{headers}[$_*2+1]
    for (0..$#{$i->{headers}}/2);
  printf "Set-Cookie: %s\r\n", $i->{cookies}{$_} for (keys %{$i->{cookies}});
  print  "\r\n";
  print  $i->{content} if $self->reqMethod() ne 'HEAD';

  # free the memory used for the reponse data
  $self->resInit;
}




1;


