# SPRAGL::Cgi_read.pm
# Barebones CGI.
# (c) 2022-2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package SPRAGL::Cgi_read;

use experimental qw(signatures);
use strict;
# use Exporter qw(import);

our $VERSION = 0.71;

use Encode qw(decode);
use SPRAGL::Cgi_read::Getchunk;

my sub qwac( $s ) {grep{/./} map{split /\s+/} map{s/#.*//r} split/\v+/ , $s;};

our @EXPORT = qwac '
    param     # Gives a hashref with all parameter value pairs.
    meta      # Gives a hashref with metadata for every parameter name.
    param_all # Gives a listref with values for the given parameter name.
    meta_all  # Gives a corresponding listref of metadata for the given parameter name.
    header    # Look up a request header name.
    ';

our @EXPORT_OK = qwac '
    $method   # The method of the request, as a string.
    $uri      # The relative URI of the request, as a string.
    %header   # The headers shown by CGI.
    $content  # The content of the request, as a string.
    $cgi_mode # Is true if script has been started from CGI.
    ';

our $method;
our $uri;
our %header = ();
our $content;
our $cgi_mode;

# --------------------------------------------------------------------------- #
# Globals and defaults.

# boolean variables deciding if data is to be computed/saved
my $mem_pad;
my $mem_mad;
my $mem_pd;
my $mem_md;
my $mem_c;


# For performance and convenience.
my $param_data; # first value for every parameter
my $meta_data;

# Hash of lists, with no empty lists.
my $param_all_data; # list of all values for all parameters
my $meta_all_data;

my $boundary; # Boundary for multipart.
my $qstring;  # Query string.
my $stdin;

# --------------------------------------------------------------------------- #
# Private methods.

# application/x-www-form-urlencoded parsing.


my sub pdecode( $rs ) {
# Decode percent notation.
    $rs->$* =~ s/\+/ /g;
    $rs->$* =~ s/\%([0-9A-F]{2})/chr('0x'.$1)/ge;
    };


my sub uparse( $input , $get ) {
# Parse application/x-www-form-urlencoded input. Build up memory data.
    while (1) {
        my ($chunk,$eoc) = $get->( $input , '=' , '&' , ';' );
        last if not defined $chunk;
        pdecode($chunk);
        if ( $eoc ne '=' ) {
            $param_data->{''} //= $chunk->$* if $mem_pd;
            push $param_all_data->{''}->@* , $chunk->$* if $mem_pad;
            $meta_data->{''} //= { name => '' , header => {} } if $mem_md;
            push $meta_all_data->{''}->@* , { name => '' , header => {} } if $mem_mad;
            next;
            };
        my ($chunk2) = $get->( $input , '&' , ';' );
        pdecode($chunk2);
        $param_data->{$chunk->$*} //= $chunk2->$* if $mem_pd;
        push $param_all_data->{$chunk->$*}->@* , $chunk2->$* if $mem_pad;
        $meta_data->{$chunk->$*} //= { name => $chunk->$* , header => {} } if $mem_md;
        push $meta_all_data->{$chunk->$*}->@* , { name => $chunk->$* , header => {} } if $mem_mad;
        };
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

my sub hnorm( $h ) {
# Normalize header name. Uppercase the start letters, lowercase all the other.
# Remove illegal characters. Change underscores into dashes per convention.
    return $h =~
        s/[^\!-9\;-\~]//gr =~
        y/a-z_/A-Z\-/r =~
        s/([A-Z])([A-Z]+)/$1.lc($2)/ger;
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# multipart/form-data parsing, Ref RFC1341 7.2


my sub xdecode( $s ) {
# Decode RFC5987 extended notation.
    $s =~ m/^([^\']*)\'([^\']*)\'([^\']*)$/ || return;
    my ( $cset , $lang , $val ) = ($1,$2,$3);
    return decode( $cset , $val );
    };


my sub hparse( $h ) {
# Parse multipart headers.
    my $md = { header => {} };

    while (1) {
        last if $h !~ m/\S/;
        $h =~ s/^([^:]+)\:// || return;
        my $hn = hnorm($1);
        $h =~ s/^\s*(\S.*?)\r\n// || $h =~ s/^\s*(\S.*?)$// || return;
        my $hv = $1;
        next if exists $md->{header}->{$hn}; # only want the first
        $md->{header}->{$hn} = $hv;
        };

    return if not exists $md->{header}->{'Content-Disposition'};
    my $info = $md->{header}->{'Content-Disposition'};
    return if not $info =~ s/^\s*form\-data\;\s*//;
    my $star = 0;
    for my $directive ( split /\s*\;\s*/ , $info ) {
        my ($n,$v) = $directive =~ m/^([^=]+)\=(.+)$/;
        if ( $n eq 'name' ) {
            next if exists $md->{name}; # only recognize the first
            $v =~ s/^\"(.*)\"$/$1/;
            $md->{name} = $v;
            }
        elsif ( $n eq 'filename*' ) {
            return if $star;
            my $fn = xdecode( $v );
            next if not defined $fn;
            $md->{filename} = $fn;
            $star = 1;
            }
        elsif ( $n eq 'filename' ) {
            next if $star;
            return if defined $md->{filename};
            $v =~ s/^\"(.*)\"$/$1/;
            $md->{filename} = $v;
            };
        };
    return if not exists $md->{name};

    if ( exists $md->{header}->{'Content-Type'} ) {
        $md->{type} = $md->{header}->{'Content-Type'};
        };

    return $md;
    }; # sub hparse


my sub mparse( $input , $get ) {
# Parse multipart/form-data input. Build up memory data.
    my ($preamble,$eoc) = $get->( $input , "--${boundary}\r\n" , "--${boundary}--" );
    while (1) {
        my ($chunk,$eoc) = $get->( $input , "\r\n\r\n" , "\r\n--${boundary}\r\n" , "\r\n--${boundary}--" );
        last if $eoc eq "\r\n--${boundary}--"; # if we are in the epilogue
        my $h; # for headers of the current part
        $h = hparse($chunk->$*) if $eoc eq "\r\n\r\n";
        ($chunk,$eoc) = $get->( $input , "\r\n--${boundary}\r\n" , "\r\n--${boundary}--" ) if defined $h;
        $h //= { name => '' , type => 'text/plain' , header => {} };
        $param_data->{$h->{name}} //= $chunk->$* if $mem_pd;
        push $param_all_data->{$h->{name}}->@* , $chunk->$* if $mem_pad;
        $meta_data->{$h->{name}} //= $h if $mem_md;
        push $meta_all_data->{$h->{name}}->@* , $h if $mem_mad;
        last if $eoc eq "\r\n--${boundary}--"; # if we are in the epilogue
        };
    };

# --------------------------------------------------------------------------- #
# Initialization and import.

my sub build_data() {

    my $sget;
    if ( $mem_c ) {
        if (ref $stdin eq 'GLOB') {
            $content = '';
            { # localizing lineseperator change
                local $/ = undef;
                $content = <$stdin>;
                };
            $stdin = \$content;
            }
        else {
            $content = $stdin->$*;
            };
        $sget = \&readchunk;
        }
    else {
        $sget = \&takechunk;
        };

    return if $method eq 'TRACE';

    my $mem_data = ($mem_pad || $mem_mad || $mem_pd || $mem_md);
    return if not $mem_data;

    $param_all_data = {} if $mem_pad;
    $meta_all_data = {} if $mem_mad;
    $param_data = {} if $mem_pd;
    $meta_data = {} if $mem_md;

    if ( $method eq 'POST' || $method eq 'PUT' || $method eq 'PATCH' ) {
    
        if ( $header{'Content-Type'} =~ m/^multipart\/form\-data\s*\;/ ) {
            $boundary = $header{'Content-Type'} =~ s/^.+\;\s*boundary\=(.*\S)\s*$/\1/r;
            mparse($stdin,$sget);
            }
    
        elsif ( $header{'Content-Type'} =~ m/^application\/x\-www\-form\-urlencoded\s*$/ ) {
            uparse($stdin,$sget);
            }

        else { # all other Content-Type headers
            return if not ( $mem_pad || $mem_pd );
            my $data;
            ($data->$*) = $sget->($stdin); # slurp all
            return if (($data->$* !~ m/./) and (not exists $header{'Content-Type'}));
            $header{'Content-Type'} //= 'text/plain';
            push $meta_all_data->{''}->@* , {
                type => $header{'Content-Type'} ,
                header => {} ,
                } if $mem_mad;
            $meta_data->{''} //= {
                type => $header{'Content-Type'} ,
                header => {} ,
                } if $mem_md;
            push $param_all_data->{''}->@* , $data->$* if $mem_pad;
            $param_data->{''} //= $data->$* if $mem_pd;
            };
        };

    uparse(\$qstring,\&readchunk) if $qstring =~ m/\S/;

    }; # sub build_data

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub import {
# Custom import method, adapting module calculations and memory to actual usage.

    my $mynsp = shift;
    my $calnsp = caller;

    my sub ampclean { return $_[0] =~ s/^\&//r; };

    my %check = ();
    for (@EXPORT) { $check{ampclean($_)} = 1; };
    for (@EXPORT_OK) { $check{ampclean($_)} = 1; };

    my sub exportcheck( $s ) {
        return 1 if $check{ampclean( $s =~ s/^\:\://r )};
        die "ERROR - ${s} not exported by module ${mynsp}\n";
        };

    for ( map { $_ =~ s/^\:\:\&/::/r =~ s/^\&//r }
          (0 == scalar @_) ? @EXPORT : grep { exportcheck($_) } @_ ) {

        no strict "refs";
        if    ( $_ =~ m/^\:\:/ )    { $_ =~ s/^\:\://; }
        elsif ( $_ =~ m/^\$(.*)$/ ) { *{"${calnsp}::$1"} = \$$1; }
        elsif ( $_ =~ m/^\@(.*)$/ ) { *{"${calnsp}::$1"} = \@$1; }
        elsif ( $_ =~ m/^\%(.*)$/ ) { *{"${calnsp}::$1"} = \%$1; }
        else                        { *{"${calnsp}::$_"} = \&$_; };
        use strict "refs";

        $mem_c ||= ($_ eq '$content');
        $mem_pad ||= ($_ eq 'param_all');
        $mem_mad ||= ($_ eq 'meta_all');
        $mem_pd ||= ($_ eq 'param');
        $mem_md ||= ($_ eq 'meta');
        };

    build_data;

    }; # sub import

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

if (exists $ENV{GATEWAY_INTERFACE}) {
    $cgi_mode = 1;
    $method = $ENV{REQUEST_METHOD};
    $uri = $ENV{REQUEST_URI};
    $qstring = $ENV{QUERY_STRING};
    $stdin = \*STDIN;

    for my $k ( grep {/^HTTP_/} keys %ENV ) {
        $header{ hnorm( $k =~ s/^HTTP_//r ) } = $ENV{$k};
        };
    $header{'Content-Type'} = $ENV{CONTENT_TYPE} if exists $ENV{CONTENT_TYPE};
    }
else {
    $method = 'GET';
    $uri = $0;
    $stdin->$* = '';

    my $i = 0;
    while ($i < scalar @ARGV) {
        my $opt = $ARGV[$i];
        if ($opt =~ m/^-c(.*)/) {
            die 'Cannot take -c option parameters.' if $1 ne '';
            $method = 'POST';
            $stdin = \*STDIN;

            splice @ARGV , $i , 1;
            }
        elsif ($opt =~ m/^-H(.*)/) {
            my $head = $1;
            if ($head eq '') {
                die 'Missing parameter for -H option.' if $i == $#ARGV;
                splice @ARGV , $i , 1;
                $head = $ARGV[$i];
                };

            $head =~ m/^([^:]+)\:(.*)/ ||
              die 'Unparsable parameter "'.$head.'" for -H option.';
            my ($hname,$hval) = ($1,$2);
            $hval =~ s/^\s+//;
            $hval =~ s/\s+$//;
            $header{hnorm($hname)} = $hval;

            splice @ARGV , $i , 1;
            }
        elsif ($opt =~ m/^-q(.*)/) {
            die 'Cannot handle multiple -q options.'
              if defined $qstring;
            $qstring = $1;
            if ($qstring eq '') {
                die 'Missing parameter for -q option.' if $i == $#ARGV;
                splice @ARGV , $i , 1;
                $qstring = $ARGV[$i];
                };

            $qstring =~ s/^\s*\?//;
            $qstring =~ s/\s+$//;
            $uri .= '?'.$qstring;

            splice @ARGV , $i , 1;
            }
        else {
            $i++;
            };
        };
    }; # if exists $ENV{GATEWAY_INTERFACE}

1;

# --------------------------------------------------------------------------- #
# Exportable methods.

sub param() {
# Return a hashref with all parameter value pairs.
    return $param_data;
    };


sub meta() {
# Return a hashref with metadata for every parameter.
    return $meta_data;
    };


sub param_all( $p ) {
# Return a listref with all values for the given parameter name.
    return [] if not exists $param_all_data->{$p};
    return $param_all_data->{$p};
    };


sub meta_all( $p ) {
# Return a listref corresponding to param_all, but with metadata.
    return [] if not exists $meta_all_data->{$p};
    return $meta_all_data->{$p};
    };


sub header( $h ) {
# Return the value of a header.
    return $header{ hnorm($h) };
    };

# --------------------------------------------------------------------------- #

=pod

=encoding utf8

=head1 NAME

SPRAGL::Cgi_read - Barebones CGI.

=head1 VERSION

0.71

=head1 SYNOPSIS

    use SPRAGL::Cgi_read;

    # Reading a header.
    my $greet = "Buon Giorno" if header("Accept-Language") =~ m/\b it \b/x;

    # Reading a parameter value.
    my $id = param->{ID}; # Parameter names are case sensitive.

    # Multi value parameters.
    for my ($i,$val) ( each param_all("files")->@* ) {
        write_to_log "processing ".meta_all("files")->[$i]->{filename};
        do_something( ${val} );
        };

=head1 IDIOMS

    param->{p}          # first value of parameter p
    param_all('p')->@*  # all values assigned to parameter p
    param_all('p')->[2] # the third value assigned to parameter p
    meta->{p}           # metadata for first value of parameter p
    meta_all('p')->@*   # metadata for every value assigned to parameter p
    meta_all('p')->[2]  # the metadata for the third value assigned to parameter p
    keys param->%*      # list of all parameter names sent in the request

=head1 DESCRIPTION

Barebones module for handling CGI requests. It is applicative and lightweight, and has only a few dependencies.

CGI is simple and quick to code for, even though it is not so performant or fashionable. It nevertheless is handy when making quick and dirty web services that are not going to see a lot of load. HTTP Routing is handled by the file system. Adding or removing functionality is easy and orthogonal, like playing with Lego bricks.

For decades CGI.pm has been the gold standard for doing CGI with Perl. It is a big featureful module, and in many cases that is what is needed. But in other cases you just need a simple basic module.

SPRAGL::Cgi_read.pm exists so you dont have to use CGI.pm.

The SPRAGL::Cgi_read module follows Postels Law (be conservative in what you do, be liberal in what you accept). So in case a request is a bit off, the module will not right out fail, but will try to get fairly intelligible data out of it.

=head2 OPTIMIZATIONS

The SPRAGL::Cgi_read module optimizes ressources based on the imports of the CGI script. This works without further ado for normal scripts. But if the script references a method or variable using the SPRAGL::Cgi_read namespace, then it should specify so in its import statement. This is done by prefixing "::" to the import. For example

    use SPRAGL::Cgi_read qw(param $uri ::meta ::$method);
    use SPRAGL::Cgi_reply;

    my $custname = param->{name};
    my $custmeta = SPRAGL::Cgi_read::meta(name);
    reply "URI was ".$uri." and method was ".$SPRAGL::Cgi_read::method;

If these imports are not specified, calls and lookups might give the wrong values.

=head2 COMMAND LINE

With SPRAGL::Cgi_read you can run your CGI scripts from the commandline. This is convenient when debugging or testing. The script will be run as if a GET request with no data started it. But by using options, you can change that.

B<-c>

Emulate that the request was a POST request. Send the content to it on STDIN.

B<-H &lt;string&gt;>

Emulate that the request had the given header field.

B<-q &lt;string&gt;>

Emulate that the request had the given querystring.

Example:

    perl index.pl -H "Referer: https://news.ycombinator.com/" -q "?tag=mars"

=head1 FUNCTIONS AND VARIABLES

Loaded by default:
L<param|/param()>,
L<meta|/meta()>,
L<param_all|/param_all( $p )>,
L<meta_all|/meta_all( $p )>,
L<header|/header( $h )>

Loaded on demand:
L<$method|/$method>,
L<$uri|/$uri>,
L<%header|/%header>,
L<$content|/$content>,
L<$cgi_mode|/$cgi_mode>

=over

=item param()

Gives a hashref with values for all parameters in the request.

In case a parameter name is assigned a value multiple times, the hashref will only contain "the first" of them.

If the request contained data without any parameter information, that data will be assigned the name "" (empty string). In that case, it will be the only parameter recognized in the request.

Parameter names can consist of any characters, but special characters need to be encoded in the request. The module only prevents the name "" (empty string), as it is reserved for the value that has no parameter name.

=item meta()

Gives a hashref with metadata for the parameters in the request.

The keys are the parameter names. The values are hashrefs themselves. Their keys can be:
- name (string) - The name of the parameter. Same as the key used to look up the hashref.
- type (string) - The content-type of the value.
- filename (string) - The filename used locally on the client.
- header (hashref) - Headers specific for the value.

=item param_all( $p )

Gives a listref of values for the given parameter name.

If the parameter name was not in the request, the list is empty.

=item meta_all( $p )

Gives a listref of metadata entries for the given parameter name.

The list mirrors the list given by the param_all function. Each entry is a hashref built the same way the metadata, given by the meta function, is.

=item header( $h )

Gives the value of the given header name.

Gives undef if the given header name was not in the request.

Note that two strings can be different, but be the same header name. To this module header names are US-ASCII case-insensitive, and dashes and underscores are equivalent.

Only headers provided by the web servers CGI interface can be looked up.

=item $method

The method of the request. It can be one of the strings "GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS", "CONNECT", "PATCH" and "TRACE". Only in case of the "POST", "PUT", "PATCH" methods are parameters read from the request content. In case of the "TRACE" method any parameters sent are ignored.

Only loaded on demand.

=item $uri

The relative URI of the request. It will contain a querystring, if that was part of the URI the client used.

Only loaded on demand.

=item %header

The request headers are available as the %header hash. Only the headers that are passed on by the web servers CGI interface can be found in the hash. The header names are reformatted, attempting to follow common practice. For example the CGI name "HTTP_ACCEPT_LANGUAGE" will be rewritten to "Accept-Language".

Only loaded on demand.

=item $content

The content of the request, available as the string C<$content>.

Only loaded on demand.

=item $cgi_mode

Is true if the script, that uses SPRAGL::Cgi_read, has been started from CGI.

Only loaded on demand.

=back

=head1 DEPENDENCIES

Encode

List::Util

Scalar::Util

=head1 KNOWN ISSUES

Limited testing. Should work with all major web servers.

=head1 TODO

=head1 SEE ALSO

L<SPRAGL::Cgi_reply|https://metacpan.org/pod/SPRAGL::Cgi_reply>

L<CGI|https://metacpan.org/pod/CGI>

=head1 LICENSE & COPYRIGHT

(c) 2022-2023 Bjørn Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt

=cut

__END__
