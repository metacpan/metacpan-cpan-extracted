package Test::CGI::External;
use 5.006;
use warnings;
use strict;
use utf8;

use Carp;
use Encode 'decode';
use File::Temp 'tempfile';
use FindBin '$Bin';
use Test::Builder;

our $VERSION = '0.22';

sub new
{
    my %tester;

    my $tb = Test::Builder->new ();
    $tester{tb} = $tb;
#    $tester{html_validator} = '/home/ben/bin/validate';

    return bless \%tester;
}

sub note
{
    my ($self, $note) = @_;
    my (undef, $file, $line) = caller ();
    if ($self->{verbose}) {
        $self->{tb}->note ("$file:$line: $note");
    }
}

sub on_off_msg
{
    my ($self, $switch, $type) = @_;
    if ($self->{verbose}) {
	my $msg = "You have asked me to turn ";
	if ($switch) {
	    $msg .= "on";
	}
	else {
	    $msg .= "off";
	}
	$msg .= " testing of $type";
	my (undef, $file, $line) = caller ();
        $self->{tb}->note ("$file:$line: $msg");
    }
}

sub set_cgi_executable
{
    my ($self, $cgi_executable, @command_line_options) = @_;
    $self->note ("I am setting the CGI executable to be tested to '$cgi_executable'.");
    $self->do_test (-f $cgi_executable, "found executable $cgi_executable");
    if ($^O eq 'MSWin32') {
	# These tests don't do anything useful on Windows, see
	# http://perldoc.perl.org/perlport.html#-X
	$self->pass_test ('Invalid test for MS Windows');
    }
    else {
	$self->do_test (-x $cgi_executable, "$cgi_executable is executable");
    }
    $self->{cgi_executable} = $cgi_executable;
    if (@command_line_options) {
	$self->{command_line_options} = \@command_line_options;
    }
    else {
	$self->{command_line_options} = [];
    }
}

sub do_compression_test
{
    my ($self, $switch) = @_;
    $switch = !! $switch;
    $self->on_off_msg ($switch, "compression");
    $self->{comp_test} = $switch;
    if ($switch && ! $self->{_use_io_uncompress_gunzip}) {
	eval "use Gzip::Faster;";
	if ($@) {
	    $self->{_use_io_uncompress_gunzip} = 1;
	    if (! $self->{no_warn}) {
		carp "Gzip::Faster is not installed, using IO::Uncompress::Gunzip";
	    }
	}
    }
}

sub do_caching_test
{
    my ($self, $switch) = @_;
    $switch = !! $switch;
    $self->on_off_msg ($switch, "if-modified/last-modified response");
    $self->{cache_test} = $switch;
    if ($switch) {
	eval "use HTTP::Date;";
	if ($@) {
	    if (! $self->{no_warn}) {
		carp "HTTP::Date is not installed, cannot do caching test";
	    }
	    $self->{cache_test} = undef;
	}
    }
}

sub expect_charset
{
    my ($self, $charset) = @_;
    eval "use Unicode::UTF8 qw/decode_utf8 encode_utf8/";
    if ($@) {
	Encode->import (qw/decode_utf8 encode_utf8/);
	if (! $self->{no_warn} && ! $self->{_warned_unicode_utf8}) {
	    carp "Unicode::UTF8 is not installed, using Encode";
	    $self->{_warned_unicode_utf8} = 1;
	}
    }
    $self->note ("You have told me to expect a 'charset' value of '$charset'.");
    $self->{expected_charset} = $charset;
}

sub expect_mime_type
{
    my ($self, $mime_type) = @_;
    if ($mime_type) {
	$self->note ("You have told me to expect a mime type of '$mime_type'.");
    }
    else {
	$self->note ("You have deleted the mime type.");
    }
    $self->{mime_type} = $mime_type;
}

sub set_verbosity
{
    my ($self, $verbosity) = @_;
    $self->{verbose} = !! $verbosity;
    $self->note ("You have asked me to print messages as I work.");
}

sub set_no_warnings
{
    my ($self, $onoff) = @_;
    $self->{no_warn} = !! $onoff;
    $self->on_off_msg ($onoff, "warnings");
}

sub test_if_modified_since
{
    my ($self, $last_modified) = @_;
    die unless defined $last_modified;
    my $saved = $ENV{HTTP_IF_MODIFIED_SINCE};
    $ENV{HTTP_IF_MODIFIED_SINCE} = $last_modified;
    $self->note ("Testing response with last modified time $last_modified");
    my $saved_no_check_content = $self->{no_check_content};
    $self->{no_check_content} = 1;
    # Copy the hash of options into a private copy, so that we can run
    # the thing again without overwriting our precious stuff.
    my $saved_run_options = $self->{run_options};
    my %run_options = %$saved_run_options;
    $self->{run_options} = \%run_options;
    my $saved_no_warn = $self->{no_warn};
    $self->{no_warn} = 1;
    run_private ($self);
    $self->check_headers_private ($self);
    $self->test_status (304);
    my $body = $run_options{body};
    $self->do_test (! defined ($body) || length ($body) == 0,
		    "No body returned with 304 response");
    $ENV{HTTP_IF_MODIFIED_SINCE} = $saved;
    # Restore our precious stuff.
    $self->{run_options} = $saved_run_options;
    $self->{no_warn} = $saved_no_warn;
    $self->{no_check_content} = $saved_no_check_content;
}

sub check_caching_private
{
    my ($self) = @_;
    my $output = $self->{run_options};
    my $headers = $output->{headers};
    if (! $headers) {
	die "There are no headers in object, did the tests really run?";
    }
    my $last_modified = $headers->{'last-modified'};
    $self->do_test ($last_modified, "Has last modified header");
#    for my $k (keys %$headers) {
#	print "$k $headers->{$k}\n";
#    }
    my $time = str2time ($last_modified);
    $self->do_test (defined $time, "Last modified time can be parsed by HTTP::Date");
    if ($last_modified) {
	$self->test_if_modified_since ($last_modified);
    }
    else {
	$self->note ("Not doing last modified test due to no-header failure");
    }
    # Restore the headers because they were overwritten when we did
    # the caching test.
    $output->{headers} = $headers;
}

my @request_method_list = qw/POST GET HEAD/;
my %valid_request_method = map {$_ => 1} @request_method_list;

sub check_request_method
{
    my ($self, $request_method) = @_;
    my $default_request_method = 'GET';
    if ($request_method) {
        if ($request_method && ! $valid_request_method{$request_method}) {
	    if (! $self->{no_warn}) {
		carp "You have set the request method to a value '$request_method' which is not one of the ones I know about, which are ", join (', ', @request_method_list), " so I am setting it to the default, '$default_request_method'";
	    }
            $request_method = $default_request_method;
        }
    }
    else {
	if (! $self->{no_warn}) {
	    carp "You have not set the request method, so I am setting it to the default, '$default_request_method'";
	}
        $request_method = $default_request_method;
    }
    return $request_method;
}

sub do_test
{
    my ($self, $test, $message) = @_;
    $self->{tb}->ok ($test, $message);
}

# Register a successful test (deprecated legacy from pre-Test::Builder days)

sub pass_test
{
    my ($self, $test) = @_;
    $self->{tb}->ok (1, $test);
}

# Fail a test and keep going (deprecated legacy from pre-Test::Builder days)

sub fail_test
{
    my ($self, $test) = @_;
    $self->{tb}->ok (0, $test);
}

# Print the TAP plan

sub plan
{
    my ($self) = @_;
    $self->{tb}->done_testing ();
}

# Fail a test which means that we cannot keep going.

sub abort_test
{
    my ($self, $test) = @_;
    $self->{tb}->skip_all ($test);
}

# Set an environment variable, with warning about collisions.

sub setenv_private
{
    my ($self, $name, $value) = @_;
    if (! $self->{set_env}) {
        $self->{set_env} = [$name];
    }
    else {
        push @{$self->{set_env}}, $name;
    }
    if ($ENV{$name}) {
	if (! $self->{no_warn}) {
	    carp "A variable '$name' is already set in the environment.\n";
	}
    }
    $ENV{$name} = $value;
}

sub encode_utf8_safe
{
    my ($self) = @_;
    my $input = $self->{input};
    eval "use Unicode::UTF8;";
    if ($@) {
	if (! $self->{no_warn} && ! $self->{_warned_unicode_utf8}) {
	    carp "Unicode::UTF8 is not installed, using Encode";
	    $self->{_warned_unicode_utf8} = 1;
	}
	# Encode::encode_utf8 uses prototypes so we have to hassle this up.
	return Encode::encode_utf8 ($input);
    }
    return Unicode::UTF8::encode_utf8 ($input);
}

# Internal routine to run a CGI program.

sub run_private
{
    my ($self) = @_;

    # Pull everything out of the object and into normal variables.

    my $verbose = $self->{verbose};
    my $options = $self->{run_options};
    my $cgi_executable = $self->{cgi_executable};
    my $comp_test = $self->{comp_test};

    # Hassle up the CGI inputs, including environment variables, from
    # the options the user has given.

    # mwforum requires GATEWAY_INTERFACE to be set to CGI/1.1
    #    setenv_private ($o, 'GATEWAY_INTERFACE', 'CGI/1.1');

    my $query_string = $options->{QUERY_STRING};
    if (defined $query_string) {
	$self->note ("I am setting the query string to '$query_string'.");
        setenv_private ($self, 'QUERY_STRING', $query_string);
    }
    else {
	$self->note ("There is no query string.");
        setenv_private ($self, 'QUERY_STRING', "");
    }

    my $request_method;
    if ($options->{no_check_request_method}) {
	$request_method = $options->{REQUEST_METHOD};
    }
    else {
	$request_method = $self->check_request_method ($options->{REQUEST_METHOD});
    }
    $self->note ("The request method is '$request_method'.");
    setenv_private ($self, 'REQUEST_METHOD', $request_method);
    my $content_type = $options->{CONTENT_TYPE};
    if ($content_type) {
	$self->note ("The content type is '$content_type'.");
	setenv_private ($self, 'CONTENT_TYPE', $content_type);
    }
    if ($options->{HTTP_COOKIE}) {
        setenv_private ($self, 'HTTP_COOKIE', $options->{HTTP_COOKIE});
    }
    my $remote_addr = $self->{run_options}->{REMOTE_ADDR};
    if ($remote_addr) {
	$self->note ("I am setting the remote address to '$remote_addr'.");
        setenv_private ($self, 'REMOTE_ADDR', $remote_addr);
    }
    if (defined $options->{input}) {
        $self->{input} = $options->{input};
	if (utf8::is_utf8 ($self->{input})) {
	    $self->{input} = $self->encode_utf8_safe ();
	}
	if ($self->{bad_content_length}) {
	    setenv_private ($self, 'CONTENT_LENGTH', '0');
	}
	else {
	    my $content_length = length ($self->{input});
	    setenv_private ($self, 'CONTENT_LENGTH', $content_length);
	    $self->note ("I am setting the CGI program's standard input to a string of length $content_length taken from the input options.");
	    $options->{content_length} = $content_length;
	}
    }

    if ($comp_test) {
        if ($verbose) {
	    $self->{tb}->note ("I am requesting gzip encoding from the CGI executable.\n");
        }
        setenv_private ($self, 'HTTP_ACCEPT_ENCODING', 'gzip, fake');
    }

    # Actually run the executable under the current circumstances.

    my @cmd = ($cgi_executable);
    if ($self->{command_line_options}) {
	push @cmd, @{$self->{command_line_options}};
    }
    $self->note ("I am running '@cmd'");
    $self->run3 (\@cmd);
    $options->{output} = $self->{output};
    $options->{error_output} = $self->{errors};
    $options->{exit_code} = $?;
    $self->note (sprintf ("The program has now finished running. There were %d bytes of output.", length ($self->{output})));
    if ($options->{expect_failure}) {
    }
    else {
	$self->do_test ($options->{exit_code} == 0,
			"The CGI executable exited with zero status");
    }
    $self->do_test ($options->{output}, "The CGI executable produced some output");
    if ($options->{expect_errors}) {
	if ($options->{error_output}) {
	    $self->pass_test ("The CGI executable produced some output on the error stream as follows:\n$self->{errors}\n");
	}
	else {
	    $self->fail_test ("Expecting errors, but the CGI executable did not produce any output on the error stream");
	}
    }
    else {
	if ($self->{errors}) {
	    $self->fail_test ("Not expecting errors, but the CGI executable produced some output on the error stream as follows:\n$self->{errors}\n");
	}
	else {
	    $self->pass_test ("The CGI executable did not produce any output on the error stream");
	}
    }

    $self->tidy_files ();

    return;
}


# my %token_valid_chars;
# @token_valid_chars{0..127} = (1) x 128;
# my @ctls = (0..31,127);
# @token_valid_chars{@ctls} = (0) x @ctls;
# my @tspecials = 
#     ('(', ')', '<', '>', '@', ',', ';', ':', '\\', '"',
#      '/', '[', ']', '?', '=', '{', '}', \x32, \x09 );
# @token_valid_chars{@tspecials} = (0) x @tspecials;

# These regexes are for testing the validity of the HTTP headers
# produced by the CGI script.

my $HTTP_CTL = qr/[\x{0}-\x{1F}\x{7f}]/;

my $HTTP_TSPECIALS = qr/[\x{09}\x{20}\x{22}\x{28}\x{29}\x{2C}\x{2F}\x{3A}-\x{3F}\x{5B}-\x{5D}\x{7B}\x{7D}]/;

my $HTTP_TOKEN = '[\x{21}\x{23}-\x{27}\x{2a}\x{2b}\x{2d}\x{2e}\x{30}-\x{39}\x{40}-\x{5a}\x{5e}-\x{7A}\x{7c}\x{7e}]';

my $HTTP_TEXT = qr/[^\x{0}-\x{1F}\x{7f}]/;

# This does not include [CRLF].

my $HTTP_LWS = '[\x{09}\x{20}]';

my $qd_text = qr/[^"\x{0}-\x{1f}\x{7f}]/;
my $quoted_string = qr/"$qd_text+"/;
my $field_content = qr/(?:$HTTP_TEXT)*|
                       (?:
                           $HTTP_TOKEN|
                           $HTTP_TSPECIALS|
                           $quoted_string
                       )*
                      /x;

my $http_token = qr/(?:$HTTP_TOKEN+)/;

# Check for a valid content type line.

sub check_content_line_private
{
    my ($self, $header, $verbose) = @_;

    my $expected_charset = $self->{expected_charset};

    $self->note ("I am checking to see if the output contains a valid content type line.");
    my $content_type_ok;
    my $has_content_type = ($header =~ m!(Content-Type:\s*.*)!i);
    my $content_type_line = $1;
    $self->do_test ($has_content_type, "There is a Content-Type header");
    if (! $has_content_type) {
	return;
    }
    my $lineok = ($content_type_line =~ m!^Content-Type:(?:$HTTP_LWS)+
					  ($http_token/$http_token)
					 !xi);
    my $mime_type = $1;
    $self->do_test ($lineok, "The Content-Type header is well-formed");
    if (! $lineok) {
	return;
    }
    if ($self->{mime_type}) {
	$self->do_test ($mime_type eq $self->{mime_type},
			"Got expected mime type $mime_type = $self->{mime_type}");
    }
    if ($expected_charset) {
	my $has_charset = ($content_type_line =~ /charset
						  =
						  (
						      $http_token|
						      $quoted_string
						  )/xi);
	my $charset = $1;
	$self->do_test ($has_charset, "Specifies a charset");
	if ($has_charset) {
	    $charset =~ s/^"(.*)"$/$1/;
	    $self->do_test (lc $charset eq lc $expected_charset,
			    "Got expected charset $charset = $expected_charset");
	}
    }
}

sub check_http_header_syntax_private
{
    my ($self, $header, $verbose) = @_;
    if ($verbose) {
        $self->note ("Checking the HTTP header.");
    }
    my @lines = split /\r?\n/, $header;
    my $line_number = 0;
    my $bad_headers = 0;
    my %headers;
    my $line_re = qr/($HTTP_TOKEN+):$HTTP_LWS+(.*)/;
#    print "Line regex is $line_re\n";
    for my $line (@lines) {
        if ($line =~ /^$/) {
            if ($line_number == 0) {
                $self->fail_test ("The output of the CGI executable has a blank line as its first line");
            }
            else {
                $self->pass_test ("There are $line_number valid header lines");
            }
            # We have finished looking at the headers.
            last;
        }
        $line_number += 1;
        if ($line !~ $line_re) {
            $self->fail_test ("The header on line $line_number, '$line', appears not to be a correctly-formed HTTP header");
            $bad_headers++;
        }
        else {
	    my $key = lc $1;
	    my $value = $2;
	    $headers{$key} = $value;
            $self->pass_test ("The header on line $line_number, '$line', appears to be a correctly-formed HTTP header");
        }
    }
    if ($verbose) {
        print "# I have finished checking the HTTP header for consistency.\n";
    }
    $self->{run_options}{headers} = \%headers;
}

# The output is required to have a blank line even if it has no body.

sub check_blank_line
{
    my ($self, $output) = @_;
    my $blank = ($output =~ /\r?\n\r?\n/);
    $self->{tb}->ok ($blank, "Output contains a blank line");
}

# Check whether the headers of the CGI output are well-formed.

sub check_headers_private
{
    my ($self) = @_;

    # Extract variables from the object

    my $verbose = $self->{verbose};
    my $output = $self->{run_options}->{output};
    if (! $output) {
	$self->note ("No output, skipping header tests");
        return;
    }
    check_blank_line ($self, $output);
    my ($header, $body) = split /\r?\n\r?\n/, $output, 2;
    check_http_header_syntax_private ($self, $header, $verbose);
    if (! $self->{no_check_content}) {
        check_content_line_private ($self, $header, $verbose);
    }

    $self->{run_options}->{header} = $header;
    $self->{run_options}->{body} = $body;
}

# This is "safe" in the sense that it falls back to using
# IO::Uncompress::Gunzip if it can't find Gzip::Faster. However, it
# throws an exception if it fails, so it's not really "safe".

sub gunzip_safe
{
    my ($self, $content) = @_;
    my $out;
    if ($self->{_use_io_uncompress_gunzip}) {
	# gunzip_safe is called within an eval block. It's possible
	# that the require might fail, but trying to fix these kinds
	# of problems goes beyond the scope of this module.
	eval "use IO::Uncompress::Gunzip;";
	my $status = IO::Uncompress::Gunzip::gunzip (\$content, \$out);
	if (! $status) {
	    die "IO::Uncompress::Gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
	}
    }
    else {
	# We have already loaded Gzip::Faster within
	# do_compression_test.
	$out = Gzip::Faster::gunzip ($content);
    }
    return $out;
}

sub check_compression_private
{
    my ($self) = @_;
    my $body = $self->{run_options}->{body};
    my $header = $self->{run_options}->{header};
    my $verbose = $self->{verbose};
    if ($verbose) {
        print "# I am testing whether compression has been applied to the output.\n";
    }
    if ($header !~ /Content-Encoding:.*\bgzip\b/i) {
        $self->fail_test ("Output does not have a header indicating compression");
    }
    else {
        $self->pass_test ("The header claims that the output is compressed");
        my $uncompressed;
        #printf "The length of the body is %d\n", length ($body);
	eval {
	    $uncompressed = $self->gunzip_safe ($body);
	};
        if ($@) {
            $self->fail_test ("Output claims to be in gzip format but gunzip on the output failed with the error '$@'");
            my $failedfile = "$0.gunzip-failure.$$";
            open my $temp, ">:bytes", $failedfile or die $!;
            print $temp $body;
            close $temp or die $!;
            print "# Saved failed output to $failedfile.\n";
        }
        else {
            my $uncomp_size = length $uncompressed;
            my $percent_comp = sprintf ("%.1f%%", (100 * length ($body)) / $uncomp_size);
            $self->pass_test ("The body of the CGI output was able to be decompressed using 'gunzip'. The uncompressed size is $uncomp_size. The compressed output is $percent_comp of the uncompressed size.");
            
            $self->{run_options}->{body} = $uncompressed;
        }
    }
    if ($verbose) {
        print "# I have finished testing the compression.\n";
    }
}

sub set_no_check_content
{
    my ($self, $value) = @_;
    my $verbose = $self->{verbose};
    if ($verbose) {
        print "# I am setting no content check to $value.\n";
    }
    $self->{no_check_content} = $value;
}

sub test_not_implemented
{
    my ($self, $method) = @_;
    my %options;
    if ($method) {
	$options{REQUEST_METHOD} = $method;
    }
    else {
	$options{REQUEST_METHOD} = 'GOBBLEDIGOOK';
    }
    $options{no_check_request_method} = 1;
    my $saved_no_check_content = $self->{no_check_content};
    $self->{no_check_content} = 1;
    $self->{run_options} = \%options;
    run_private ($self);
    #print $options{output}, "\n";
    $self->check_headers_private ();
    $self->test_status (501);
    $self->{no_check_content} = $saved_no_check_content;
    $self->clear_env ();
}

sub test_status
{
    my ($self, $status) = @_;
    if ($status !~ /^[0-9]{3}$/) {
	carp "$status is not a valid HTTP status, use a number like 301 or 503";
	return;
    }
    my $headers = $self->{run_options}{headers};
    if (! $headers) {
	carp "no headers in this object; have you run a test yet?";
	return;
    }
    $self->{tb}->ok ($headers->{status}, "Got status header");
    $self->{tb}->like ($headers->{status}, qr/$status/, "Got $status status");
} 


sub test_method_not_allowed
{
    my ($self, $bad_method) = @_;
    my $tb = $self->{tb};
    my %options;
    $options{REQUEST_METHOD} = $bad_method;
    $options{no_check_request_method} = 1;
    my $saved_no_check_content = $self->{no_check_content};
    $self->{no_check_content} = 1;
    $self->{run_options} = \%options;
    run_private ($self);
    $self->check_headers_private ();
    my $headers = $options{headers};
    $tb->ok ($headers->{allow}, "Got Allow header");
    $tb->like ($headers->{status}, qr/405/, "Got method not allowed status");
    $self->clear_env ();
    if ($headers->{allow}) {
	my @allow = split /,\s*/, $headers->{allow};
	my $saved_no_warn = $self->{no_warn};
	$self->{no_warn} = 1;
	for my $ok_method (@allow) {
	    # Run the program with each of the headers we were told were
	    # allowed, and see whether the program executes correctly.
	    my %op2;
	    $op2{REQUEST_METHOD} = $ok_method;
	    if ($ok_method eq 'POST') {
		$op2{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
		$op2{input} = 'a=b';
		#	    $op2{CONTENT_LENGTH} = length ($op2{input});
	    }
	    $self->{run_options} = \%op2;
	    run_private ($self);
	    $self->check_headers_private ();
	    my $headers2 = $op2{headers};
	    # Check that either there is no status line (defaults to 200),
	    # or that there is a status line, and it has status 200.
	    $tb->ok (! $headers2->{status} || $headers2->{status} =~ /200/,
		     "Method $ok_method specified by Allow: header was allowed");
	    $self->clear_env ();
	}
	$self->{no_warn} = $saved_no_warn;
    }
    $self->{no_check_content} = $saved_no_check_content;
}

# Make a request with CONTENT_LENGTH set to zero and see if the
# executable produces a 411 status (content length required).

sub test_411
{
    my ($self, $options) = @_;
    if (! $options) {
	$options = {};
    }
    $self->{bad_content_length} = 1;
    my $rm;
    if ($options->{REQUEST_METHOD} && $options->{REQUEST_METHOD} ne 'POST') {
	$rm = $options->{REQUEST_METHOD};
	if (! $self->{no_warn}) {
	    carp "test_411 requires REQUEST_METHOD to be POST";
	}
    }
    $options->{REQUEST_METHOD} = 'POST';
    if (! $options->{CONTENT_TYPE}) {
	$options->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
    }
    if (! $options->{input}) {
	$options->{input} = 'this does not have a zero length';
    }
    my $saved_no_check_content = $self->{no_check_content};
    $self->{no_check_content} = 1;
    $self->{run_options} = $options;
    $self->run_private ();
    # This has to be run to parse the headers.
    $self->check_headers_private ();
    $self->test_status (411);
    # Delete everything from $self so that it can be used again.
    $self->{bad_content_length} = undef;
    $self->{run_options} = undef;
    $self->clear_env ();
    $self->{no_check_content} = $saved_no_check_content;
    # Put the user's %options back to how it was.
    $options->{REQUEST_METHOD} = $rm;
}

# Send bullshit queries expecting a 400 response.

sub test_broken_queries
{
    my ($self, $options, $queries) = @_;
    for my $query (@$queries) {
	$ENV{QUERY_STRING} = $query;
	$self->run ($options);
	# test for 400 header
	$self->test_status (400);
    }
}

# Clear all the environment variables we have set ourselves.

sub clear_env
{
    my ($self) = @_;
    for my $e (@{$self->{set_env}}) {
#        print "Deleting environment variable $e\n";
        $ENV{$e} = undef;
    }
    $self->{set_env} = undef;
}

sub run
{
    my ($self, $options) = @_;
    if (ref $options ne 'HASH') {
	carp "Use a hash reference as argument, \$tester->run (\\\%options);";
	return;
    }
    my $verbose = $self->{verbose};
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if (! $self->{cgi_executable}) {
        croak "You have requested me to run a CGI executable with 'run' without telling me what it is you want me to run. Please tell me the name of the CGI executable using the method 'set_cgi_executable'.";
    }
    if (! $options) {
        $self->{run_options} = {};
	if (! $self->{no_warn}) {
	    carp "You have requested me to run a CGI executable with 'run' without specifying a hash reference to store the input, output, and error output. I can only run basic tests of correctness";
	}
    }
    else {
        $self->{run_options} = $options;
    }
    if ($self->{verbose}) {
        print "# I am commencing the testing of CGI executable '$self->{cgi_executable}'.\n";
    }
    if ($options->{html} && ! $self->{no_warn}) {
	if ($self->{mime_type}) {
	    if ($self->{mime_type} ne 'text/html') {
		carp "If you want to test for HTML output, you should also specify a mime type 'text/html', but you have specified '$self->{mime_type}'";
	    }
	}
	else {
	    carp "If you want to check for html validity, you should also check the mime type is 'text/html' using expect_mime_type";
	}
    }
    elsif ($options->{json} && ! $self->{no_warn}) {
	my $mime_type = $self->{mime_type};
	if ($mime_type) {
	    if ($mime_type ne 'text/plain' && $mime_type ne 'application/json') {
		carp "Your expected mime type of $mime_type is not valid for JSON";
	    }
	}
	else {
	    carp "There is no expected mime type, use expect_mime_type ('application/json') or expect_mime_type ('text/plain') for JSON output";
	}
    }
    elsif ($options->{png} && ! $self->{no_warn}) {
	my $mime_type = $self->{mime_type};
	if ($mime_type) {
	    if ($mime_type ne 'image/png') {
		carp "Your expected mime type of $mime_type is not valid for PNG";
	    }
	}
	else {
	    carp "There is no expected mime type, use image/png for PNG output";
	}
    }

    if ($options->{png}) {
	if ($options->{html} || $options->{json}) {
	    carp "Contradictory options png and json/html";
	}
    }
    elsif ($options->{html}) {
	if ($options->{json}) {
	    carp "Contradictory options json and html";
	}
    }

#    eval {
    run_private ($self);
    my $output = $self->{run_options}->{output};
    # Jump over the following tests if there is no output. This used
    # to complain a lot about output and fail tests but this proved a
    # huge nuisance when creating TODO tests, so just skip over the
    # output tests if we have already failed the basic "did not
    # produce output" issue.
    if ($output) {
	check_headers_private ($self);
	if ($self->{comp_test}) {
	    check_compression_private ($self);
	}
	my $ecs = $self->{expected_charset};
	if ($ecs) {
	    if ($ecs =~ /utf\-?8/i) {
		if ($verbose) {
		    print ("# Expected charset '$ecs' looks like UTF-8, sending it to Unicode::UTF8.\n");
		}
		$options->{body} = decode_utf8 ($options->{body});
	    }
	    else {
		if ($verbose) {
		    print ("# Expected charset '$ecs' doesn't look like UTF-8, sending it to Encode.\n");
		}
		eval {
		    $options->{body} = decode ($options->{body}, $ecs);
		};
		if (! $@) {
		    $self->pass_test ("decoded from $ecs encoding");
		}
		else {
		    $self->fail_test ("decoded from $ecs encoding");
		}
	    }
	}
	if ($self->{cache_test}) {
	    $self->check_caching_private ();
	}
    }
    if ($options->{html}) {
	validate_html ($self);
    }
    if ($options->{json}) {
	validate_json ($self);
    }
    if ($options->{png}) {
	validate_png ($self);
    }
    $self->clear_env ();
}

sub tidy_files
{
    my ($self) = @_;
    if ($self->{infile}) {
	unlink $self->{infile} or die $!;
    }

    # Insert HTML test here?

    unlink $self->{outfile} or die $!;
    unlink $self->{errfile} or die $!;
}

sub tfilename
{
    my $dir = "/tmp";
    my $file = "$dir/temp.$$-" . scalar(time ()) . "-" . int (rand (10000));
    return $file;
}

sub run3
{
    my ($self, $exe) = @_;
    my $cmd = "@$exe";
    if (defined $self->{input}) {
	$self->{infile} = tfilename ();
	open my $in, ">:raw", $self->{infile} or die $!;
	print $in $self->{input};
	close $in or die $!;
	$cmd .= " < " . $self->{infile};
    }
    my $out;
    ($out, $self->{outfile}) = tempfile ("/tmp/output-XXXXXX");
    close $out or die $!;
    my $err;
    ($err, $self->{errfile}) = tempfile ("/tmp/errors-XXXXXX");
    close $err or die $!;
  
    my $status = system ("$cmd > $self->{outfile} 2> $self->{errfile}");

    $self->{output} = '';
    if (-f $self->{outfile}) {
	open my $out, "<", $self->{outfile} or die $!;
	while (<$out>) {
	    $self->{output} .= $_;
	}
	close $out or die $!;
    }
    $self->{errors} = '';
    if (-f $self->{errfile}) {
	open my $err, "<", $self->{errfile} or die $!;
	while (<$err>) {
	    $self->{errors} .= $_;
	}
	close $err or die $!;
    }

#    print "OUTPUT IS $self->{output}\n";
#    print "$$errors\n";
#    exit;

    return $status;
}

sub set_html_validator
{
    my ($self, $hvc) = @_;
    if (! $hvc) {
	if (! $self->{no_warn}) {
	    carp "Invalid value for validator";
	}
	return;
    }
    if (! -x $hvc) {
	if (! $self->{no_warn}) {
	    carp "$hvc doesn't seem to be an executable program";
	}
    }
    $self->{html_validator} = $hvc;
}

sub validate_html
{
    my ($self) = @_;
    my $html_validator = $self->{html_validator};
    if (! $html_validator || ! -x $html_validator) {
	warn "HTML validation could not be completed, set validator to executable program using \$tce->set_html_validator ('command')";
	return;
    }
    my $html_validate = "$Bin/html-validate-temp-out.$$";
    my $html_temp_file = "$Bin/html-validate-temp.$$.html";
    open my $htmltovalidate, ">:encoding(utf8)", $html_temp_file or die $!;
    print $htmltovalidate $self->{run_options}->{body};
    close $htmltovalidate or die $!;
    my $status = system ("$html_validator $html_temp_file > $html_validate");
    
    $self->do_test (! -s $html_validate, "HTML is valid");
    if (-s $html_validate) {
	open my $in, "<", $html_validate or die $!;
	while (<$in>) {
	    print ("# $_");
	}
	close $in or die $!;
    }
    unlink $html_temp_file or die $!;
    if (-f $html_validate) {
	unlink $html_validate or die $!;
    }
}

sub validate_json
{
    my ($self) = @_;
    my $json = $self->{run_options}->{body};
    eval "use JSON::Parse 'valid_json';";
    if ($@) {
	croak "JSON::Parse is not installed, cannot validate JSON";
    }
    my $valid = valid_json ($json);
    if ($valid) {
	$self->pass_test ("Valid JSON");
    }
    else {
	$self->fail_test ("Valid JSON");
    }
}

sub validate_png
{
    my ($self) = @_;
    eval "use Image::PNG::Libpng 'read_from_scalar';";
    if ($@) {
	croak "Image::PNG::Libpng is not installed, cannot validate PNG";
    }
    my $body = $self->{run_options}->{body};
    my $png;
    eval {
	$png = read_from_scalar ($body);
    };
    $self->{tb}->ok (!$@, "Could read PNG from body");
    $self->{tb}->ok ($png, "Got a valid value for PNG");
    $self->{run_options}{pngdata} = $png;
}

1;

