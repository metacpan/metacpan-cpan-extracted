# SPRAGL::Cgi_reply.pm
# Simple HTTP replies.
# (c) 2022-2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package SPRAGL::Cgi_reply;

use strict;
use experimental qw(signatures);
use Exporter qw(import);

our $VERSION = 1.30;

use File::Spec ();
use File::Basename qw(basename);
use JSON qw(encode_json);

my sub qwac( $s ) {grep{/./} map{split /\s+/} map{s/#.*//r} split/\v+/ , $s;};

our @EXPORT = qwac '
    fail       # Send reply code and text.
    redirect   # Redirect to URL.
    reply      # Send reply and exit.
    reply_file # Send file and exit.
    reply_html # Send HTML reply and exit.
    reply_json # Send JSON reply and exit.
    set_header # Add or overwrite headers.
    cexec      # CGI exec command.
    csystem    # CGI system command. Deprecated.
    ';

our @EXPORT_OK = qwac '
    %status_code # Common status code messages.
    ';

# --------------------------------------------------------------------------- #
# Globals and defaults.

our %status_code = (
    200 => 'OK' ,
    201 => 'Created' ,
    202 => 'Accepted' ,
    203 => 'Non-Authoritative Information' ,
    204 => 'No Content' ,
    205 => 'Reset Content' ,
    206 => 'Partial Content' ,
    207 => 'Multi-Status' , # WebDAV
    208 => 'Already Reported' , # WebDAV
    226 => 'IM Used' , # HTTP Delta Encoding
    300 => 'Multiple Choices' ,
    301 => 'Moved Permanently' ,
    302 => 'Found' ,
    303 => 'See Other' ,
    304 => 'Not Modified' ,
    305 => 'Use Proxy' ,
    307 => 'Temporary Redirect' ,
    308 => 'Permanent Redirect' ,
    400 => 'Bad Request' ,
    401 => 'Unauthorized' ,
    402 => 'Payment Required' ,
    403 => 'Forbidden' ,
    404 => 'Not Found' ,
    405 => 'Method Not Allowed' ,
    406 => 'Not Acceptable' ,
    407 => 'Proxy Authentication Required' ,
    408 => 'Request Timeout' ,
    409 => 'Conflict' ,
    410 => 'Gone' ,
    411 => 'Length Required' ,
    412 => 'Precondition Failed' ,
    413 => 'Payload Too Large' ,
    414 => 'URI Too Long' ,
    415 => 'Unsupported Media Type' ,
    416 => 'Range Not Satisfiable' ,
    417 => 'Expectation Failed' ,
    418 => 'I\'m a teapot' ,
    421 => 'Misdirected Request' ,
    422 => 'Unprocessable Content' , # WebDAV
    423 => 'Locked' , # WebDAV
    424 => 'Failed Dependency' , # WebDAV
    425 => 'Too Early' ,
    426 => 'Upgrade Required' ,
    428 => 'Precondition Required' ,
    429 => 'Too Many Requests' ,
    431 => 'Request Header Fields Too Large' ,
    451 => 'Unavailable For Legal Reasons' ,
    500 => 'Internal Server Error' ,
    501 => 'Not Implemented' ,
    502 => 'Bad Gateway' ,
    503 => 'Service Unavailable' ,
    504 => 'Gateway Timeout' ,
    505 => 'HTTP Version Not Supported' ,
    506 => 'Variant Also Negotiates' ,
    507 => 'Insufficient Storage' , # WebDAV
    508 => 'Loop Detected' , # WebDAV
    510 => 'Not Extended' ,
    511 => 'Network Authentication Required' ,
    );


# Default headers.
my %header = (
    'Content-Type' => 'text/plain; charset=utf-8' ,
    Pragma => 'no-cache' ,
    Status => '200 OK' ,
    );

# --------------------------------------------------------------------------- #
# Private methods.

my $cr;
my $cx; # For holding a cexec command.


my sub hnorm( $h ) {
# Normalize header name. Uppercase the start letters, lowercase all the other.
# Remove illegal characters. Change underscores into dashes per convention.
    return $h =~
        s/[^\!-9\;-\~]//gr =~
        y/a-z_/A-Z\-/r =~
        s/([A-Z])([A-Z]+)/$1.lc($2)/ger;
    };


my sub timestring( $t = time ) { # $t in epoch seconds
# Returns for example 1970-01-01 00:00:00
    return if not defined $t;
    return if $t !~ m/^\d+$/;
    my @utcarray = (gmtime($t))[5,4,3,2,1,0];
    $utcarray[0] += 1900;
    $utcarray[1] += 1;
    return sprintf( '%04u-%02u-%02u %02u:%02u:%02u UTC' , @utcarray );
    };


my sub print_headers() {
    $header{Date} //= timestring;
    for my $h (keys %header) {
        print $h.': '.$header{$h}."\r\n";
        };
    print "\r\n";
    };


my sub cdie( $msg ) {
    warn $msg;
    fail(500);
    };


my sub cexit() {

    if ($cr != 1) {
        $cr = 1;
        }
    else {
        # Hat tip to chrispitude on Stackoverflow
        # https://stackoverflow.com/questions/3935269/how-can-i-run-a-long-background-process-from-a-perl-cgi-program

        # fork this process
        my $pid = fork();
        cdie 'SPRAGL::Cgi_reply::cexec failed: '.$!
          if not defined $pid;

        if ($pid == 0) {
            # do this in the child
            open STDIN  , '<' , File::Spec->devnull();
            open STDOUT , '>' , File::Spec->devnull();
            open STDERR , '>' , File::Spec->devnull();
            if ($^O eq 'MSWin32') {
                qx[start /b ${cx}];
                }
            else {
                qx[${cx} &];
                };
            exit;
            };
        };

    open STDERR , '>' , File::Spec->devnull();
    die; # Using die as a catchable version of exit.
    };


my sub rcheck() {
# Check redirection, and handle it if set.

    if (not exists $header{Location}) {
        return if $header{Status} !~ m/^30[1278]\b/;
        cdie 'Redirection URI missing.';
        };
    $header{Status} = '302 '.$status_code{302}
      if $header{Status} !~ m/^30[1278]\s/;

    $header{'Content-Type'} = 'text/html; charset=utf-8';
    print_headers;
    print
        '<html><head></head><body>'.
        '<a href="'.$header{Location}.'">'.
        $header{Location}.
        '</a>'.
        '</body></html>';
    cexit;
    };


my sub signature( $mp , $op , @par ) {
# Tailor-made signature-like parameter slurping.

    # Handle object parameter if there is one.
    if (defined $cr) {
        cdie 'Multiple calls of cexec.' if $cr == 1;
        cdie 'Error in cexec.' if $par[0] ne $cr;
        shift @par;
        $cr = 1;
        };

    # Take the mandatory parameters to the side.
    cdie 'Too few arguments for subroutine.'
      if scalar @par < $mp;
    my @ret = splice @par , 0 , $mp;

    # Take the optional parameter, if it is given.
    if ($op == 1) {
        if ((scalar @par) % 2 == 1) {
            push @ret , shift @par;
            }
        else {
            push @ret , undef;
            };
        };

    # Update the header hash with any named parameters left.
    cdie 'Error in optional named parameters.'
      if (scalar @par) % 2 == 1;
    while (@par) {
        my $key = shift @par;
        my $val = shift @par;
        $val =~ s/\v+$//;
        cdie 'Header value contains newline.' if $val =~ m/\n/;
        if ($key =~ m/^redirect$/i) {
            $header{Status} = '302 '.$status_code{302};
            $header{Location} = $val;
            }
        else {
            $header{hnorm($key)} = $val;
            };
        };

    return @ret;

    }; # sub signature

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

1;

# --------------------------------------------------------------------------- #
# Exportable methods.

sub fail {
# Send status code and text. Also works with "200 OK". Also works with
# redirects, for which the second parameter must be the URI redirected to.

    my ($code,$text) = signature(1,1,@_);
    cdie 'Unknown return code "'.$code.'".'
      if not exists $status_code{$code};
    $header{Status} = $code.' '.$status_code{$code};
    rcheck;
    print_headers;
    print $text // $code.' '.$status_code{$code};
    cexit;
    };


sub redirect {
# Redirect to the given URI.
    my ($uri) = signature(1,0,@_);
    $header{Status} = '302 '.$status_code{302};
    $header{Location} = $uri;
    rcheck;
    };


sub reply {
    my ($text) = signature(1,0,@_);
    rcheck;
    print_headers;
    print $text;
    cexit;
    };


sub reply_file {
    my ($filename) = signature(1,0,@_);
    fail 404 if not -f $filename;
    $header{'Content-Type'} = 'application/octet-stream';
    $header{'Content-Length'} = -s $filename;
    $header{'Content-Disposition'} = 'attachment; filename="'.basename($filename).'"';
    rcheck;
    print_headers;
    open my $fh , '<' , $filename || fail 500;
    { # localizing lineseparator change
        local $/ = undef;
        print <$fh>;
        };
    close $fh;
    cexit;
    };


sub reply_html {
    my ($doc) = signature(1,0,@_);
    $header{'Content-Type'} = 'text/html; charset=utf-8';
    rcheck;
    print_headers;
    print $doc;
    cexit;
    };


sub reply_json {
    my ($hashref) = signature(1,0,@_);
    $header{'Content-Type'} = 'application/json; charset=utf-8';
    rcheck;
    print_headers;
    print encode_json($hashref);
    cexit;
    };


sub set_header( %h ) {
    for my $h (keys %h) {
        next if not defined $h{$h};
        $header{hnorm($h)} = $h{$h};
        };
    };


sub cexec( $c ) {
    cdie 'Undefined command given to cexec.' if not defined $c;
    $cx = $c;
    my $sr;
    $sr->$* = undef;
    $cr = $sr;
    bless $sr , 'SPRAGL::Cgi_reply';
    return $sr;
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub csystem( $c ) {
    my $out;
    if ($^O eq 'MSWin32') {
        $out = qx[start /b ${c}];
        }
    else {
        $out = qx[${c} 2>/dev/null];
        };
    return $out;
    };

# --------------------------------------------------------------------------- #

=pod

=encoding utf8

=head1 NAME

SPRAGL::Cgi_reply - Simple HTTP replies.

=head1 VERSION

1.30

=head1 SYNOPSIS

    use SPRAGL::Cgi_reply;

    my %df = map {(/^(\S+).+\s(\d+)\%/)} grep {/\d\%/} qx[ df ];
    reply_json \%df;

=head1 DESCRIPTION

Simple module for sending simple HTTP replies. Geared towards CGI scripts.

CGI is simple and quick to code for, even though it is not so performant or fashionable. It nevertheless is handy when making quick and dirty web services that are not going to see a lot of load. HTTP Routing is handled by the file system. Adding or removing functionality is easy and orthogonal, like playing with Lego bricks.

The reply methods in SPRAGL::Cgi_reply will exit when they have been called. The exit is based on "die", so it is catchable.

=head1 FUNCTIONS AND VARIABLES

Loaded by default:
L<fail|/fail( $c )>,
L<redirect|/redirect( $u )>,
L<reply|/reply( $s )>,
L<reply_file|/reply_file( $fn )>,
L<reply_html|/reply_html( $d )>,
L<reply_json|/reply_json( $hr )>,
L<set_header|/set_header( %h )>,
L<cexec|/cexec ...>

Loaded on demand:
L<%status_code|/%status_code>

=over

=item fail( $c )

Replies with the given return code plus the standard return message attached to that, and then exits. It can be given a second parameter, a string, to replace the standard return message with. As in:

    fail 404 , 'Lost in Space.'; # Instead of just "fail 404;".

=item redirect( $u )

Replies with a 302 redirect to the given URI, and then exits.

=item reply( $s )

Replies with the given string as plain/text, and then exits.

=item reply_file( $fn )

Replies with the file content pointed to by the given filename, and then exits.

=item reply_html( $d )

Replies with the given string as HTML, and then exits.

=item reply_json( $hr )

Replies with the given hashref transformed into JSON, and then exits.

=item set_header( %h )

Add and or overwrite the headers that are going to be used in a reply.

=item cexec ...

CGI exec. Executes a system command, and sends a reply of your choice, in one go. Works like exec ought to in a CGI context. Calling it looks like this:

    cexec('mysqldump orders > orders_backup.sql')->reply('Database backup started.');

Or like this:

    cexec('sudo postfix stop && postfix start')->redirect('status.html');

You must naturally be very careful about what system commands it is possible to run from your webserver.

=item %status_code

A hash that maps return codes to standard return messages.

Only loaded on demand.

=back

=head2 OPTIONAL NAMED PARAMETERS

Optional named parameters can be given in the reply calls. If the name is "redirect" the reply will be like calling the redirect method. If the name is anything else, a header with that name and value will be inserted in the reply. The header will be normalized, by capitalizing words and changing underscores to dashes. The header value will be inserted raw. Be sure to adhere to RFC 8187.

Examples:

    reply $x.' seconds to go!' , refresh => 5; # Inserts a "Refresh: 5" header.

    fail 503 , 'We are down at the moment, please try again later' , 'Retry-After' => $t;

    fail 308 , redirect => 'https://perlmaven.com/'; # Redirecting with another code than 302.

=head2 DEPRECATED

=over

=item csystem( $c )

A CGI system command. Does pretty much what system already does, so use that instead. It is loaded by default.

=back

=head1 DEPENDENCIES

File::Basename

File::Spec

JSON

=head1 KNOWN ISSUES

No known issues.

=head1 TODO

=head1 SEE ALSO

L<SPRAGL::Cgi_read|https://metacpan.org/pod/SPRAGL::Cgi_read>

L<CGI|https://metacpan.org/pod/CGI>

=head1 LICENSE & COPYRIGHT

(c) 2022-2023 Bjørn Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt

=cut

__END__
