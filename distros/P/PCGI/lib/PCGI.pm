package PCGI;

use 5.005;
use strict;
use Exporter;

use Stream::Reader 0.09;

our $VERSION = '0.28';

our @ISA         = qw( Exporter );
our %EXPORT_TAGS = ( all => [ qw( trim urlencode urldecode httpdate ) ] );
our @EXPORT_OK   = ( @{$EXPORT_TAGS{all}} );
our @EXPORT      = ();

# Global/system variables

our $CODE;
our $AUTOLOAD;
our $Shift;
our $CRLF;
our $TempMode;
our $RTag;
our $RType;
our $Powered;
our $RandChars;
our $MonStr;
our $DayStr;
our $Char2Hex;

unless( $CRLF ) {

# New line delimiter
$CRLF = "\r\n";

# 'X-Powered-By' string
my $perlver;
if( $] >= 5.006 ) {
  $perlver = sprintf( '%d.%d.%d', ( $] * 1e6 ) =~ /(\d)(\d{3})(\d{3})/ );
} else {
  $perlver = $];
}
$Powered = "Perl/$perlver PCGI/$VERSION";

# HTTP/1.1 header fields, ordered by rfc2616 (without 'Request header' group)
# Added fields: Status, Set-Cookie and X-Powered-By
$RTag = [
  # General header
  qw( Status Cache-Control Connection Date Pragma Trailer Transfer-Encoding Upgrade
    Via Warning ),
  # Response header
  qw( Set-Cookie Accept-Ranges Age ETag Location Proxy-Authenticate Retry-After Server
    Vary WWW-Authenticate ),
  # Entity header
  qw( X-Powered-By Allow Content-Encoding Content-Language Content-Length Content-Location
    Content-MD5 Content-Range Content-Type Expires Last-Modified )
];

# HTTP header types:
#  1 - can be multiple
#  2 - can be multiple (multitags)
#  3 - must be unique
@$RType{ @$RTag } = (
  qw( 3 1 1 3 1 1 3 1 1 1 ), qw( 2 1 1 1 3 1 1 3 1 1 ), qw( 3 1 1 1 3 1 1 1 3 3 3 )
);

# Autoload code
$CODE = {

# Constructor
new => <<'ENDC',
  foreach( \*STDIN, \*STDOUT, \*STDERR ) {
    binmode $_; # binmoding all standard streams
  }
  my $self = bless {
    set => {
      COOKIE => { EscNull => 1, IncEmpty => undef },
      GET    => { EscNull => 1, IncEmpty => undef },
      MULTI  => {
        EscNull     => 1,
        IncEmpty    => undef,
        MaxFiles    => 16,
        MaxNameSize => 128,
        MaxLoops    => 256,
        MaxSize     => 33_554_432,
        MaxValsSize => 2_097_152,
        TempDir     => undef
      },
      POST => {
        EscNull     => 1,
        IncEmpty    => undef,
        MaxNameSize => 128,
        MaxLoops    => 256,
        MaxSize     => 2_097_152,
        MaxValsSize => 2_097_152
      }
    },
    data   => { COOKIE => {}, FILE => {}, GET => {}, POST => {} },
    flag   => { COOKIE => undef, GET => undef, POST => undef },
    header => {},
    cookie => [],
    temp   => [],
    errstr => '',
    hsent  => undef
  } => shift;

  # Header pre-definition
  $self->header(
    X_Powered_By => $Powered,
    Content_Type => 'text/html; charset=ISO-8859-1',
    Date => httpdate(),
    Connection => 'close'
  );
  return $self;
ENDC

# Destructor
DESTROY => <<'ENDC',
  my $self = shift;
    # Attempt to delete temporary files
  foreach( @{$self->{temp}} ) {
    if( -e and !unlink and $^W ) { warn "Can't unlink temporary file $_: $!" }
  }
ENDC

# Public method
set => <<'ENDC',
  my $self = shift;
  $self->_set( shift, shift ) while @_;
ENDC

# Private method: SELF->_set( NAME => { ... Params ... } )
# Changing specified by NAME group settings
_set => <<'ENDC',
  my $self = shift;
  my $name = shift;
  my $attr = shift;

  if( !exists($self->{set}{$name}) ) {
    _carp("Invalid name of group") if $^W;
  } elsif( $self->{flag}{$name} ) {
    _carp("Too late for changing settings of group '$name'") if $^W;
  } elsif( ref($attr) ne 'HASH' ) {
    _carp("New parameters should be at HASH array") if $^W;
  } else {
    foreach( keys %$attr ) {
      if( !exists($self->{set}{$name}{$_}) ) {
        _carp("Unknown parameter '$_'") if $^W;
      } elsif( /IncEmpty|EscNull/ ) {
        $self->{set}{$name}{$_} = $attr->{$_};
      } elsif ( /TempDir/ ) {
        if( !defined($attr->{$_}) or ( -d $attr->{$_} and -w $attr->{$_} ) ) {
          $self->{set}{$name}{$_} = $attr->{$_};
        } else {
          _carp("Wrong temporary directory: $attr->{$_}. Will be used autodetect") if $^W;
          $self->{set}{$name}{$_} = undef;
        }
      } else {
        $self->{set}{$name}{$_} = ( defined($attr->{$_}) and $attr->{$_} >= 0 )?
          $attr->{$_} : 2e9;
      }
    }
  }
ENDC

# Public method
header => <<'ENDC',
  my $self = shift;

  if( $self->{hsent} ) {
    _carp("Too late for use header() method. Header already sent") if $^W;
  } else {
    $self->_header( shift, shift ) while @_;
  }
ENDC

# Private method: SELF->_header( PARAM => VALUE )
# Checking and storing(or deleting) new HTTP header parameter
_header => <<'ENDC',
  my $self  = shift;
  my $name  = defined($Shift = shift)? lc($Shift) : return;
  my $value = shift;
  my $rtype = 1;

  # Checking name
  $name =~ tr/_/-/;
  NCHECK: {
    foreach( @$RTag ) {
      if( lc eq $name ) { $name = $_; $rtype = $RType->{$_}; last NCHECK }
    }
    $name =~ s/([^-]+)/ ucfirst($1) /eg;
  }
  # Storing parameter
  if( defined $value ) {
    $value = [ $value ] unless( ref($value) eq 'ARRAY' );
    if( $rtype == 3 and @$value > 1 ) {
      _carp("Parameter '$name' cannot have multiple value") if $^W;
      $value = [ pop @$value ];
    }
    $self->{header}{$name} = $value;
  } else {
    delete $self->{header}{$name};
  }
ENDC

# Public method
sendheader => <<'ENDC',
  my $self = shift;

  if( $self->{hsent}++ ) {
    _carp("You can use a method sendheader() only once") if $^W;
  } else {
    $self->_sendheader();
  }
ENDC

# Private method: SELF->_sendheader()
# Formating and sending header
_sendheader => <<'ENDC',
  my $self   = shift;
  my $header = '';

  # Appending cookie data
  # and hecking some header parameter(s)
  if( @{$self->{cookie}} ) {
    push( @{$self->{header}{'Set-Cookie'}}, @{$self->{cookie}} );
  }
  if( exists $self->{header}{Location} ) {
    $self->{header}{Status} = [ '302 Found' ] unless( exists $self->{header}{Status} );
  }
  # Preparing header
  foreach my $name ( @$RTag, sort( keys %{$self->{header}} ) ) {
    if( exists $self->{header}{$name} ) {
      if( exists($RType->{$name}) and $RType->{$name} == 2 ) {
        $header .= "$name: $_".$CRLF foreach( @{ delete $self->{header}{$name} } );
      } else {
        $header .= "$name: ".join( ', ', @{ delete $self->{header}{$name} } ).$CRLF;
      }
    }
  }
  $header .= $CRLF;
    # Sending header by better way
  if( exists $ENV{MOD_PERL} ) {
    Apache->request->send_cgi_header($header);
  } else {
    print $header;
  }
ENDC

# Public method
setcookie => <<'ENDC',
  my $self = shift;

  if( $self->{hsent} ) {
    _carp("Too late for use setcookie() method. Header already sent") if $^W;
  } else {
    $self->_setcookie(@_);
  }
ENDC

# Private method: SELF->_setcookie( NAME => VALUE, { ... Params ... } )
# Checking and storing(or deleting) HTTP cookie data
_setcookie => <<'ENDC',
  my $self  = shift;
  my $name  = defined($Shift = shift)? $Shift : return;
  my $value = shift;
  my $attr  = ( ref($Shift = shift) eq 'HASH' )? $Shift : {};
  my $data  = $name.'=';

  # Preparing cookie
  if( defined $value ) {
    $data .= $attr->{Raw}? $value : urlencode($value);
    $data .= '; Expires='._httpdate( $attr->{Expires}, '-' ) if( defined $attr->{Expires} );
    $data .= '; Path='.$attr->{Path} if( defined $attr->{Path} );
    $data .= '; Domain='.$attr->{Domain} if( defined $attr->{Domain} );
    $data .= '; Secure' if $attr->{Secure};
  } else {
    $data .= 'deleted; Expires='._httpdate( 1, '-' );
  }
  # Storing cookie
  push( @{$self->{cookie}}, $data );
ENDC

# Public method
env => <<'ENDC',
  return(( exists($ENV{$_[1]}) and defined($ENV{$_[1]}) )? $ENV{$_[1]} : '' );
ENDC

# Public method
errstr => <<'ENDC',
  my $self = shift;
  $self->_init_p() unless $self->{flag}{POST};
  return $self->{errstr};
ENDC

# Public method
GET => <<'ENDC',
  my $self = shift;
  $self->_init_g() unless $self->{flag}{GET};
  return $self->_param( GET => @_ );
ENDC

# Public method
COOKIE => <<'ENDC',
  my $self = shift;
  $self->_init_c() unless $self->{flag}{COOKIE};
  return $self->_param( COOKIE => @_ );
ENDC

# Public method
POST => <<'ENDC',
  my $self = shift;
  $self->_init_p() unless $self->{flag}{POST};
  return $self->_param( POST => @_ );
ENDC

# Public method
FILE => <<'ENDC',
  my $self = shift;
  $self->_init_p() unless $self->{flag}{POST};
  return $self->_param( FILE => @_ );
ENDC

# Private method: VALUES = _param( TYPE => NAME )
# Returns specific parameter(s)
_param => <<'ENDC',
  my $self = shift;
  my $type = shift;
  my $name = shift;

  if( defined $name ) {
    if( exists $self->{data}{$type}{$name} ) {
      return wantarray? @{$self->{data}{$type}{$name}} : $self->{data}{$type}{$name}[0];
    } else {
      return;
    }
  } else {
    return keys( %{$self->{data}{$type}} );
  }
ENDC

# Private method: SELF->_init_g()
# GET query parser
_init_g => <<'ENDC',
  my $self = shift;

  if( !$self->{flag}{GET}++ ) {
      # Preparing
    my $query = $self->env('QUERY_STRING');
    $query = $self->env('REDIRECT_QUERY_STRING') unless( defined $query );
      # Processing
    foreach( split( '[&;]+', $query ) ) {
      my( $name, $value ) = ( split('='), ('')x2 );
      if( length $name ) {
        if( length($value) or $self->{set}{GET}{IncEmpty} ) {
          if( $self->{set}{GET}{EscNull} ) {
            tr/+/ / foreach( $name, $value ); # escaping null symbols
          }
          push( @{$self->{data}{GET}{ urldecode($name) }},
            urldecode($value)
          );
        }
      }
    }
  }
ENDC

# Private method: SELF->_init_c()
# COOKIE query parser
_init_c => <<'ENDC',
  my $self = shift;

  if( !$self->{flag}{COOKIE}++ ) {
      # Preparing
    my $query = $self->env('HTTP_COOKIE');
    $query = $self->env('COOKIE') unless( defined $query );
      # Processing
    foreach( split( ';+', $query ) ) {
      my( $name, $value ) = ( split('='), ('')x2 );
      foreach( $name, $value ) {
        $_ = trim($_); # removing unnecessary spaces
      }
      if( length $name ) {
        if( length($value) or $self->{set}{COOKIE}{IncEmpty} ) {
          if( $self->{set}{GET}{EscNull} ) {
            tr/+/ / foreach( $name, $value ); # escaping null symbols
          }
          $self->{data}{COOKIE}{ urldecode($name) } = [
            urldecode($value)
          ];
        }
      }
    }
  }
ENDC

_init_p => <<'ENDC',
  my $self = shift;

  unless( $self->{flag}{POST}++ ) {
    my $reason;
      # Checking request
    if( $self->env('REQUEST_METHOD') eq 'POST' ) {
        # Checking Content-Length
      my $length = $self->env('CONTENT_LENGTH');
      unless( length $length ) {
        $reason = 'Content-Length required';
      } elsif( $length !~ /^\d+$/ ) { # it is possible
        $reason = 'Invalid Content-Length';
      } elsif( $length > 0 ) {
          # Checking Content-Type
        my $ctype = _parse_mheader( 'a: '.$self->env('CONTENT_TYPE') );
        unless( exists $ctype->{a}{_MAIN_} ) {
          $reason = 'Undefined Content-Type';
        } elsif( $ctype->{a}{_MAIN_} eq 'application/x-www-form-urlencoded' ) {
            # Simple query
          if( $length > $self->{set}{POST}{MaxSize} ) {
            $reason = 'Request entity too large';
          } else {
            $reason = $self->_init_p_simple($length);
          }
        } elsif( $ctype->{a}{_MAIN_} eq 'multipart/form-data' ) {
            # Multipart query
          if( $length > $self->{set}{MULTI}{MaxSize} ) {
            $reason = 'Request entity too large';
          } elsif( !exists($ctype->{a}{boundary}) or !length($ctype->{a}{boundary}) ) {
            $reason = 'Undefined multipart boundary';
          } else {
            $reason = $self->_init_p_multipart( $length, $ctype->{a}{boundary} );
          }
        } else {
          $reason = 'Unsupported Content-Type';
        }
      }
    }
    # Setting error if having reason
    if( $reason ) {
      $self->{errstr} = "400 Bad Request ($reason)";
        # Truncating data
      $self->{data}{POST} = {};
      $self->{data}{FILE} = {};
    }
  }
ENDC

# Private method: SELF->_init_p_simple()
# Simple POST query sub-parser
_init_p_simple => <<'ENDC',
  my $self   = shift;
  my $stream = Stream::Reader->new( \*STDIN, { Limit => shift } );
  my $loop   = $self->{set}{POST}{MaxLoops};
  my $mvsize = $self->{set}{POST}{MaxValsSize};
  my $name;
  my $value;
  my $name_attr = {
    Out   => \$name, Mode => 'E',
    Limit => $self->{set}{POST}{MaxNameSize} + 1
  };

  while( $loop--> 0 ) {
    unless( $stream->readto( '=', $name_attr ) ) {
      return ''; # normal finish
    } else {
      $stream->readto( '&', {
        Out => \$value, Limit => $mvsize + 1
      });
      if( length $name ) { # checking
        if( length($name) > $self->{set}{POST}{MaxNameSize} ) {
          return 'Found too large name of parameter';
        } elsif( length($value) or $self->{set}{POST}{IncEmpty} ) {
          if( ( $mvsize -= length $value ) < 0 ) {
            return 'Summary values size is too large';
          } else {
            if( $self->{set}{POST}{EscNull} ) {
              tr/+/ / foreach( $name, $value ); # escaping null symbols
            }
            push( @{$self->{data}{POST}{ urldecode($name) }},
              urldecode($value)
            );
          }
        }
      }
    }
  }
  return 'Too much elements';
ENDC

# Private method: SELF->_init_p_multipart()
# Multipart POST query sub-parser
_init_p_multipart => <<'ENDC',
  my $self = shift;
  my $temp;
  my $s;
  my $r;

  # So strange local variables needs for more simple
  # splitting this method on some parts
  $s->{stream} = Stream::Reader->new( \*STDIN, { Limit => shift } );
  $s->{bound}  = '--'.shift;
  $s->{fcount} = $self->{set}{MULTI}{MaxFiles};
  $s->{loop}   = $self->{set}{MULTI}{MaxLoops};
  $s->{mvsize} = $self->{set}{MULTI}{MaxValsSize};
  $s->{rewind} = 1;
  $s->{header} = undef;

  # Main cycle
  while( $s->{loop}--> 0 ) {
    # Rewinding position after next found boundary. If rewinding was disabled,
    # then only checking CRLF after boundary
    if( $s->{rewind}++ and !$s->{stream}->readto( $s->{bound}, { Mode => 'E' } )) {
      return 'Malformed multipart POST'; # could not found boundary
    } elsif( !$s->{stream}->readsome( 2, { Out => \$temp } )) {
      return 'Malformed multipart POST'; # no CRLF after boundary
    } elsif( $temp eq '--' ) {
      return ''; # normal finish
    } elsif( $temp ne $CRLF ) {
      return 'Malformed multipart POST'; # bad CRLF after boundary
    } else {
      # Reading and parsing multipart header.
      # Doing that very cautiously
      unless( $s->{stream}->readto(
        $CRLF x2, { Out => \$temp, Limit => 8*1024, Mode => 'E' }
      )) {
        return 'Malformed multipart POST';
      } elsif( $s->{stream}{Readed} != $s->{stream}{Stored} ) {
        return 'Malformed multipart POST'; # malformed or too big header
      } else {
        $s->{header} = _parse_mheader($temp);
          # Checking header
        if( exists($s->{header}{content_disposition}{_MAIN_})
          and $s->{header}{content_disposition}{_MAIN_} eq 'form-data'
          and exists($s->{header}{content_disposition}{name})
          and length($s->{header}{content_disposition}{name})
        ) {
          $s->{name} = $s->{header}{content_disposition}{name};
          if( length($s->{name}) > $self->{set}{MULTI}{MaxNameSize} ) {
            return 'Found too large name of parameter';
          } else {
            if( $self->{set}{MULTI}{EscNull} ) {
              $s->{name} =~ tr/\0/ /; # escaping null symbols
            }
            # Let looking, what we have
            if( exists $s->{header}{content_disposition}{filename} ) {
              if( $s->{fcount} ) {
                $r = $self->_init_p_multipart_file($s); # file transfer
                return $r if $r;
              }
            } elsif( exists($s->{header}{content_type}{_MAIN_})
              and $s->{header}{content_type}{_MAIN_} eq 'multipart/mixed'
            ) {
              if( $s->{fcount} ) {
                $r = $self->_init_p_multipart_mixed($s); # many files transfer
                return $r if $r;
              }
            } else {
              $r = $self->_init_p_multipart_simple($s); # simple value
              return $r if $r;
            }
          }
        }
      }
    }
  }
  return 'Too much elements';
ENDC

# Private method: BOOL = SELF->_init_p_multipart_simple( S )
# Simple value extraction
_init_p_multipart_simple => <<'ENDC',
  my $self = shift;
  my $s = shift;
  my $value;

  # Reading data before next found boundary
  unless( $s->{stream}->readto(
    $CRLF.$s->{bound}, { Out => \$value, Limit => $s->{mvsize}, Mode => 'E' }
  )) {
    return 'Malformed multipart POST';
  } elsif( $s->{stream}{Stored} != $s->{stream}{Readed} ) {
    return 'Summary values size is too large';
  } else {
    $s->{rewind} = 0; # disabling rewind at next iteration
    if( $s->{stream}{Stored} or $self->{set}{MULTI}{IncEmpty} ) {
      $s->{mvsize} -= $s->{stream}{Stored};
      if( $self->{set}{MULTI}{EscNull} ) {
        $value =~ tr/\0/ /; # checking value
      }
      push( @{$self->{data}{POST}{$s->{name}}}, $value );
    }
    return '';
  }
ENDC

# Private method: BOOL = SELF->_init_p_multipart_file( S )
# File extraction
_init_p_multipart_file => <<'ENDC',
  my $self = shift;
  my $s = shift;
  my $file = {
    full => $s->{header}{content_disposition}{filename}
  };

  # Correcting and checking filename, creating new temporary file
  # and reading all data, before next found boundary, directly to temporary file
  if( length $file->{full} ) {
    $file->{base} = _basename( $file->{full} );
    if( length $file->{base} ) {
      my $handler;
      if(( $handler, $file->{temp} ) = $self->_tempfile() ) {
        unless( $s->{stream}->readto(
          $CRLF.$s->{bound}, { Out => $handler, Mode => 'E' }
        )) {
          unless( close $handler ) {
            warn("Can't close file $file->{temp}: $!") if $^W;
          }
          return 'Malformed multipart POST';
        } else {
          $s->{rewind} = 0; # disabling rewind at next iteration
          unless( close $handler ) {
            warn("Can't close file $file->{temp}: $!") if $^W;
          } elsif( $s->{stream}{Stored} != $s->{stream}{Readed} ) {
            warn("Possible writing error in file $file->{temp}") if $^W;
          } else {
            $file->{size} = $s->{stream}{Stored};
            if( exists $s->{header}{content_type}{_MAIN_} ) {
              $file->{mime} = $s->{header}{content_type}{_MAIN_};
            } else {  
              $file->{mime} = '';
            }
            if( $self->{set}{MULTI}{EscNull} ) {
              tr/+/ / foreach( @$file{qw( full base mime )} ); # escaping null symbols
            }
            push( @{$self->{data}{FILE}{$s->{name}}}, $file );
            $s->{fcount}--;
          }
        }
      }
    }
  }
  return '';
ENDC

# Private method: BOOL = SELF->_init_p_multipart_mixed( S )
# Many files extraction
_init_p_multipart_mixed => <<'ENDC',
  my $self = shift;
  my $s = shift;
  my $r;
  my $temp;

  unless( exists($s->{header}{content_type}{boundary})
   and length($s->{header}{content_type}{boundary})
  ) {
    return 'Malformed multipart POST';
  } else {
    my $mbound  = '--'.$s->{header}{content_type}{boundary};
    my $mrewind = 1;
    my $mheader;

    # Mixed sub-cycle
    for( $s->{loop}++; $s->{loop}--> 0; ) {
      unless( $s->{fcount} ) {
        return ''; # limit for files
      } else {
        # Rewinding position after next found boundary. If rewinding was disabled,
        # then only checking CRLF after boundary
        if( $mrewind++ and !$s->{stream}->readto( $mbound, { Mode => 'E' } )) {
          return 'Malformed multipart POST'; # could not found mixed boundary
        } elsif( !$s->{stream}->readsome( 2, { Out => \$temp } )) {
          return 'Malformed multipart POST'; # no CRLF after mixed boundary
        } elsif( $temp eq '--' ) {
          return ''; # normal finish
        } elsif( $temp ne $CRLF ) {
          return 'Malformed multipart POST'; # bad CRLF after mixed boundary
        } else {
          # Reading and parsing multipart/mixed header.
          # Doing that very cautiously
          unless( $s->{stream}->readto(
            $CRLF x2, { Out => \$temp, Limit => 8*1024, Mode => 'E' }
          )) {
            return 'Malformed multipart POST';
          } elsif( $s->{stream}{Readed} != $s->{stream}{Stored} ) {
            return 'Malformed multipart POST'; # malformed or too big header
          } else {
            $mheader = _parse_mheader($temp);
              # Checking multipart/mixed header
            if( exists $mheader->{content_disposition}{_MAIN_} ) {
              $temp = $mheader->{content_disposition}{_MAIN_};
              if( ( $temp eq 'file' or $temp eq 'attachment' )
                and exists($mheader->{content_disposition}{filename})
              ) {
                my $file = {
                  full => $mheader->{content_disposition}{filename}
                };
                # Correcting and checking filename, creating new temporary file
                # and reading all data, before next found boundary, directly to temporary file
                if( length $file->{full} ) {
                  $file->{base} = _basename( $file->{full} );
                  if( length $file->{base} ) {
                    my $handler;
                    if(( $handler, $file->{temp} ) = $self->_tempfile() ) {
                      unless( $s->{stream}->readto(
                        $CRLF.$mbound, { Out => $handler, Mode => 'E' }
                      )) {
                        unless( close $handler ) {
                          warn("Can't close file $file->{temp}: $!") if $^W;
                        }
                        return 'Malformed multipart POST';
                      } else {
                        $mrewind = 0; # disabling rewind at next iteration
                        unless( close $handler ) {
                          warn("Can't close file $file->{temp}: $!") if $^W;
                        } elsif( $s->{stream}{Stored} != $s->{stream}{Readed} ) {
                          warn("Possible writing error in file $file->{temp}") if $^W;
                        } else {
                          $file->{size} = $s->{stream}{Stored};
                          if( exists $mheader->{content_type}{_MAIN_} ) {
                            $file->{mime} = $mheader->{content_type}{_MAIN_};
                          } else {  
                            $file->{mime} = '';
                          }
                          if( $self->{set}{MULTI}{EscNull} ) {
                            tr/+/ / foreach( @$file{qw( full base mime )} ); # escaping null symbols
                          }
                          push( @{$self->{data}{FILE}{$s->{name}}}, $file );
                          $s->{fcount}--;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return 'Too much elements';
  }
ENDC

# Private method: ( FILENAME, HANDLER ) = SELF->_tempfile()
# Temporary files generator.
# Note(only for author): need to remember about closing all temporary files manualy
_tempfile => <<'ENDC',
  my $self = shift;
  my $tempdir;

  # Preparing
  if( !$TempMode ) {
    require File::Spec;
    require Fcntl;
    $TempMode = Fcntl::O_CREAT()|Fcntl::O_WRONLY()|Fcntl::O_EXCL()|Fcntl::O_BINARY();
  }
  $tempdir = $self->{set}{MULTI}{TempDir};
  $tempdir = File::Spec->tmpdir() unless( defined $tempdir );
    # Processing
  unless( -w $tempdir ) { # warn if bad directory
    warn("Directory is not writable: $tempdir") if $^W;
  } else {
    foreach( 1 .. 3 ) {
      my $fname = File::Spec->catfile( $tempdir, 'PCGI_'._randstr(32) );
      sysopen( my $handler, $fname, $TempMode, 0600 );
      if( fileno $handler ) {
        push( @{$self->{temp}}, $fname );
        return( $handler, $fname );
      }
    }
    # Warn if can't
    warn("Can't create file at directory: $tempdir") if $^W;
  }
  return;
ENDC

# Public function
trim => <<'ENDC',
  my $string = shift;

  $string =~ s/^\s+//s;
  $string =~ s/\s+$//s;
  return $string;
ENDC

# Public function
urldecode => <<'ENDC',
  my $string = shift;
  no warnings;

  $string =~ tr/+/ /;
  if( $] > 5.007 ) {
    use bytes;
    $string =~ s/%u([0-9a-fA-F]{4})/pack('U',hex($1))/eg;
  } else {
    my $dec;
    $string =~ s/%u([0-9a-fA-F]{4})/
      # Here utf-8 characters can have
      # maximal length 3 bytes (4 hex simbols)
      $dec = hex $1;
      if( $dec < 0x80 ) {
        chr $dec;
      } elsif( $dec < 0x800 ) {
        pack( 'c2', 0xc0|($dec>>6),0x80|($dec&0x3f) );
      } else {
        pack( 'c3', 0xe0|($dec>>12),0x80|(($dec>>6)&0x3f),0x80|($dec&0x3f) );
      }
    /egx;
  }
  $string =~ s/%([0-9a-fA-F]{2})/chr(hex $1)/eg;
  return $string;
ENDC

# Public function
urlencode => <<'ENDC',
  my $string = shift;

  # Conformity symbols to their codes
  if( !$Char2Hex ) {
    foreach( 0 .. 255 ) {
      $Char2Hex->{ chr() } = sprintf( '%%%02X', $_ );
    }
  }
  # Encoding
  $string =~ s/([^A-Za-z0-9\-_.!~*\'() ])/$Char2Hex->{$1}/g;
  $string =~ tr/ /+/;
  return $string;
ENDC

# Public function
httpdate => <<'ENDC',
  _httpdate( ( defined($Shift = shift)? $Shift : time ), ' ' );
ENDC

# Private function: DATE = _httpdate( UTIME, SEPARATOR )
_httpdate => <<'ENDC',
  my @time = gmtime(shift);
  my $sep  = shift;

  # Conformity numbers to months and day of weeks
  if( !$MonStr ) {
    $DayStr = [ qw( Sun Mon Tue Wed Thu Fri Sat ) ];
    $MonStr = [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ) ];
  }
  # Formating date
  return sprintf( "%s, %02d${sep}%s${sep}%d %02d:%02d:%02d GMT",
    $DayStr->[$time[6]], $time[3], $MonStr->[$time[4]], $time[5]+1900, $time[2], $time[1], $time[0]
  );
ENDC

# Private function: ARRAY = _parse_mheader(HEADER)
# Parsing multipart headers
_parse_mheader => <<'ENDC',
  my $array = {};
  my $group;
  my $name;
  my $value;

  # For beginning found the main pair.
  # Main parameter must be exists and not empty
  foreach my $line (
    split( $CRLF, $_[0], 6 )
  ) {
    if( $line =~ s/^([^:]+):([^;,]+)[;,]?// ) {
      $group = trim(lc $1);
      $value = trim($2);
      if( length($group) and length($value) ) {
        $group =~ tr/-/_/;
        $array->{$group}{_MAIN_} = $value;
        # Reading other parameters
        # For security check, cycle have maximum 4 iterations
        foreach( 1 .. 4 ) {
          if( $line =~ s/^([^=]+)=// ) {
            $name = trim($1);
            if( $name eq 'filename' ) {
              $value = trim($line); $line  = '';
            } else {
              $line  =~ s/^([^;,]+)[;,]?//;
              $value = trim($1);
            }
            if( length($name) and $name ne '_MAIN_' ) {
              $value =~ s/^\"(.*)\"$/$1/s;
              $array->{$group}{$name} = $value;
            }
          } else {
            last; # no matches
          }
        }
      }
    }
  }
  return $array;
ENDC

# Private function: BASENAME = _basename(PATH)
# Extracting file name from path. Very simple variant, but here more then enough
_basename => <<'ENDC',
  return(( $_[0] =~ /([^\\\/\:]+)$/ )? $1 : '' );
ENDC

# Private function: STRING = _randstr(LENGTH)
# Random strings generator. (Normal works only with little size)
_randstr => <<'ENDC',
  my $length = shift;
  my $string = '';

  # Characters for random generator
  if( !$RandChars ) {
    $RandChars = [ 'a'..'z', '0'..'9' ];
  }
  # Generating string
  foreach( 1 .. $length ) {
    $string .= $RandChars->[ rand( @$RandChars - 0.5 ) ];
  }
  return $string;
ENDC

};
}

# Compiling all under mod_perl
if( exists $ENV{MOD_PERL} ) {
  _compile($_) foreach( keys %{$CODE} );
}

# Standard function
sub AUTOLOAD {
  my $name = substr(
    $AUTOLOAD, rindex( $AUTOLOAD, ':' ) + 1
  );
  unless( _compile($name) ) {
    _croak("Undefined subroutine &${AUTOLOAD} called");
  } else {
    goto &{$AUTOLOAD};
  }
}

# Private function: BOOL = _compile(NAME)
# Compiling, specified by NAME, subroutine from $CODE array
sub _compile {
  my $name = shift;

  unless( exists $CODE->{$name} ) {
    return undef;
  } else {
    eval "sub $name { $CODE->{$name} }";
    if( $@ ne '' and $^W ) {
      warn $@; # warnings enable
    }
    delete $CODE->{$name};
    return 1;
  }
}

# Handling warnings
sub _carp {
  require Carp; Carp::carp(shift);
}

# Handling fatals
sub _croak {
  require Carp; Carp::croak(shift);
}

1;

__END__

=head1 NAME

PCGI - Perl Common Gateway Interface Class

=head1 SYNOPSIS

  use PCGI qw(:all);

  $query = PCGI->new();

  # Query's parsing settings.
  # Note: settings of specified group can be changed only before
  #       parsing activation of this group

  $query->set(
    GET => {
      IncEmpty    => $bool,     # No
      EscNull     => $bool      # Yes
    },
    COOKIE => {
      IncEmpty    => $bool,     # No
      EscNull     => $bool      # Yes
    },
    POST => {
      IncEmpty    => $bool,     # No
      EscNull     => $bool,     # Yes
      MaxLoops    => $number,   # 256
      MaxSize     => $number,   # 2Mb
      MaxNameSize => $number,   # 128b
      MaxValsSize => $number    # 2Mb
    },
    MULTI => {
      IncEmpty    => $bool,     # No
      EscNull     => $bool,     # Yes
      MaxLoops    => $number,   # 256
      MaxSize     => $number,   # 32Mb
      MaxNameSize => $number,   # 128b
      MaxValsSize => $number,   # 2Mb
      MaxFiles    => $number,   # 16
      TempDir     => $tempdir   # Autodetect
    }
  );

  # Errors checking.
  # Note: this method also activates parsing of POST query. If
  #       query isn't POST or wasn't errors, then will be returned
  #       empty string

  $errstr = $query->errstr();

  # Access to parsed query's.
  # Note: parsing of specific query is activates automatically

  @names  = $query->GET();
  @values = $query->GET($name);
  $value  = $query->GET($name);

  @names  = $query->COOKIE();
  $value  = $query->COOKIE($name);

  @names  = $query->POST();
  @values = $query->POST($name);
  $value  = $query->POST($name);

  @names  = $query->FILE();
  @files  = $query->FILE($name);
  $file   = $query->FILE($name);

  $full = $file->{full};
  $base = $file->{base};
  $temp = $file->{temp};
  $mime = $file->{mime};
  $size = $file->{size};

  # Handling response

  $query->header( $param => undef ); # delete
  $query->header( $param => $value, ... ); # add single value
  $query->header( $param => \@values, ... ); # add multiple value

  $query->setcookie( $name => undef ); # delete
  $query->setcookie( $name => $value,  # add
    {
      Path    => $path,
      Domain  => $domain,
      Expires => $utime,
      Secure  => $bool,
      Raw     => $bool
    }
  );

  $query->sendheader();

  # Utilite method(s)

  $value = $query->env($name);

  # Utilite functions

  $string  = httpdate($utime);
  $string  = trim($string);
  $encoded = urlencode($string);
  $decoded = urldecode($string);

=head1 DESCRIPTION

This is Perl module for fastest and full safely works with Common
Gateway Interface. Required little memory for work, and can safely
parsing a big or giant POST query's.

=head1 METHODS

=over 4

=item B<new()>

The constructor method instantiates a new PCGI object.

=item B<DESTROY()>

The destructor method cleaning up memory and deleting existings
temporary files.

=item B<set( GROUP =E<gt> { NAME =E<gt> VALUE }, ... )>

Method for changing settings of query's parsing.

Note: settings of specified group can be changed only before parsing
activation of this group.

=over 4

=item B<GROUP>

Name of settings group:

=over 4

=item B<GET>


Settings of GET query parsing:

B<IncEmpty> - Boolean value. Include or not parameters with empty values.
Undefined by default.

B<EscNull> - Boolean value. Escaping or not simbols with zero code from
any places, where it needed. Default value is 1 and strongly not
recommended to change this parameter!

=item B<COOKIE>

Settings of COOKIE string parsing:

B<IncEmpty> - ...

B<EscNull> - ...

=item B<POST>

Settings of POST query parsing:

B<IncEmpty> - ...

B<EscNull> - ...

B<MaxLoops> - B<This is very important parameter!> Defines limit for
quantity of cycle iterations during parsing query. Usualy quantity of
cycle iterations is equal to quantity of elements in HTML form,
or some more. Default value is 256.

B<MaxSize> - Definition maximal valid size in bytes for query. Default
value is 2Mb.

B<MaxNameSize> - Definition maximal valid size in bytes for every name
of parameter in query. Default value is 128.

B<MaxValsSize> - Definition maximal valid size in bytes of summary values
size. Default value is 2Mb.

Warning: only for this settings group. MaxSize, MaxNameSize and MaxValsSize
means size's of undecoded data!

=item B<MULTI>

Settings of multipart POST query parsing:

B<IncEmpty> - ...

B<EscNull> - ...

B<MaxLoops> - ...

B<MaxSize> - ... Default value is 32Mb.

B<MaxNameSize> - ...

B<MaxValsSize> - ...

B<MaxFiles> - Definition maximal quantity of uploading files. Defalut value
is 16.

B<TempDir> - Temporary directory manual definition. Use undefined
value for autodetect. Undefined by default.

=back

=back

=item B<errstr()>

This method activates the parsing of POST query (if wasn't parsed before) and
returns HTTP standard status of this operation. Empty string mean, what POST
query was parsed successfuly. Also empty string returns at non-POST requests.

Possible reasons of request fatal errors:

=over 4

=item *

size of POST data is more 'MaxSize' parameter;

=item *

quantity of cycle iterations is more 'MaxLoops' parameter;

=item *

found name of parameter with size more 'MaxNameSize' parameter;

=item *

sumary values size is more 'MaxValsSize' parameter;

=item *

malformed POST data;

=item *

errors in request header fields.

=back

Note: also at any of that parsing errors all POST data, what was parsed
before, will be truncated.

=item B<GET( [ NAME ] )>

In scalar context returns first one element value, specified by NAME. If
element not exists, then returns undef value.

In array context returns array of element values, specified by NAME.

If name is not specified, then returns array with all available names.

=item B<COOKIE()>

...

Only one difference. For every NAME of parameter can be maximum one value.

=item B<POST()>

...

=item B<FILE()>

...

If value of element, specified by NAME, is defined, then this is reference to
hash array with parameters:

B<full> - alltimes defined and not empty string. Full filename from client.

B<base> - alltimes defined and not empty string. Base name of full filename.
Cannot contains symbols "\", "/" and ":".

B<temp> - path to local temporary file, created in mode 0600 on POSIX systems.

B<mime> - alltimes defined, but can be empty. This is client specified mime type.
Can contains anything ;-)

B<size> - alltimes defined number. Real size of temporary file.

=item B<header( NAME =E<gt> VALUE, ... )>

Method for setting (or deleting) response header parameters.

Note: for changing HTTP status in response, please, use the 'status' parameter.

=over 4

=item B<NAME>

Name of parameter. Must be defined and not empty string. All symbols '-' can be
changed to symbols '_'. Case is not mutter.

=item B<VALUE>

This is string with new value or reference to array with many new values. In case of
undefined value, parameter will be deleted.

=back

=item B<setcookie( NAME =E<gt> VALUE, { ... Attributes ... } )>

Method for setting (or deleting) HTTP cookie's.

=over 4

=item B<NAME>

Name of cookie. Must be defined and not empty string.

=item B<VALUE>

This is string with new value. In case of undefined value, will be
generated code for deleting cookie.

=item B<Attributes:>

These optional attributes are available:

B<Expires> - time in UNIX format. Specifies a "time to live" for this
cookie. By default setted cookie will be available before browser
closing.

B<Domain> - specifies the domain for which the cookie is valid.

B<Path> - specifies the subset of URLs to which this cookie applies.

B<Secure> - if true, then directs the user agent to use only
(unspecified) secure means to contact the origin server whenever it
sends back this cookie.

B<Raw> - if true, then value will be sent as is. Otherwise, by default,
value will be url-encoded.

=back

=item B<sendheader()>

Method for sending header. Can be used only once.

=item B<env( NAME )>

Simple wrapper for array $ENV. Only one difference, - never returns undefined
values. NAME must be defined. Example:

  if( $query->env('REQUEST_METHOD') eq 'POST' ) {
    # ...
  }

=item B<httpdate( UTIME )>

HTTP date formater. Returns string, - date, formed by HTTP standard.

=over 4

=item B<UTIME>

Time in UNIX format. Current time by default.

=back

=item B<trim( STRING )>

Returns STRING copy, but without leading and trailing spaces. STRING must be
defined.

=item B<urldecode( STRING )>

Returns url-decoded STRING. String must be defined.

=item B<urlencode( STRING )>

Returns url-encoded STRING. String must be defined.

=back

=head1 UTF-8 SUPPORT

This module works only with raw data! But, URL-encoded data in UTF-8 mode
(%uXXXX) will be decoded correctly.

=head1 EBCDIC SUPPORT

No support. Only ACSII platforms supported.

=head1 REQUIREMENT

=over 4

=item *

Perl 5.005 or higher;

=item *

Stream::Reader 0.09 or higher;

=item *

Fresh enough version of Apache web server.

=back

=head1 SECURITY

This module can safely works with any size's of POST requests. It is not realy
mutter, especially for multipart POST ;-)

Warning: but be enough careful with parsing settings of POST and MULTI
groups. Default setting should be enough for mostly people. I hope so..

=head1 MOD_PERL SUPPORT

Supported transparently. You don't need think about that :-) All methods
works the same.

Note: All examples works the same under mod_perl too.

=head1 EXAMPLES

Please visit catalogue examples/ in this module distribution.

=head1 CREDITS

Special thanks to:

=over 4

=item *

Andrey Fimushkin, E<lt>plohaja@mail.ruE<gt>

=item *

Green Kakadu, E<lt>gnezdo@gmail.comE<gt>

=back

=head1 AUTHOR

Andrian Zubko aka Ondr, E<lt>ondr@cpan.orgE<gt>

=cut
