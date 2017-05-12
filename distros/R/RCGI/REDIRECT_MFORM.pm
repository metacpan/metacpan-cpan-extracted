package REDIRECT_MFORM;

#
# Package to redirect a multipart/form-data CGI POST request to another URL
#

use strict;
use HTTP::Request::Common;  
use LWP::UserAgent;


sub Read_STDIN {
    my($return);
    my($num_buffer) = 1000;
    
    while(<MFORMFILE>) {
	$return .= $_;
	if (--$num_buffer <= 0) { # return num_buffer lines at a time at most
	    last;
	}
    }
    return $return;
}

# redirect($base_url, %options);
#
# Options are:
#
# nph => (0 or undef) or 1
# username => 'username'
# password => 'password'
# user_agent => 'user_agent' (i.e. 'Mozilla')
# timeout => timeout in seconds (default is 180)

sub redirect {
    my($base_url) = shift;	# Base URL to call
    my(%options) = @_;		# Get options as associative array
    my($ua) = new LWP::UserAgent;
    my($string_method);
    my($req);
    my($headers_printed);
    my($removed);
    my($file_upload) = 0;
    my($result);
    my($temp_dir) = (defined($ENV{'TEMP'})) ? $ENV{'TEMP'} : '/tmp';
    my(@stat);

    $string_method = 'POST'; # must be POST'ed
    $req = new HTTP::Request $string_method, $base_url;
    $req->content_type('multipart/form-data'); # and multipart form
    open(MFORMFILE,">$temp_dir/mform$$.tmp");
    print MFORMFILE <>;
    close(MFORMFILE);
    @stat = stat("$temp_dir/mform$$.tmp");
    $req->content_length($stat[7]);
    $req->content(\&Read_STDIN);
    open(MFORMFILE,"$temp_dir/mform$$.tmp");
    if (defined($options{'user_agent'})) {
	$ua->agent($options{'user_agent'});
    }
    if (defined($options{'timeout'})) {
	$ua->timeout($options{'timeout'});
    }
    if (defined($options{'username'}) && defined($options{'password'})) {
	$req->authorization_basic($options{'username'}, $options{'password'});
    }

    if ($options{'nph'}) {
	$| = 1;
	$ua->request($req,
		     sub {
			 my($chunk, $res) = @_;
			 if (!$headers_printed) {
			     $headers_printed = 1;
			     $chunk =~ s/HTTP.*\s+(\d+)\s+OK/Status: \1 OK/m;
			     $chunk =~ s/Content-Type: (.*)\n/Content-Type: \1\n\n\n/m;
			     $chunk =~ s/Connection: close\s*\n//m;
			     $chunk =~ s/Date: .*\s*\n//m;
			     $chunk =~ s/Server: .*\s*\n//m;
			     $chunk =~ s/Client-Date: .*\s*\n//m;
			     $chunk =~ s/Client-Peer: .*\s*\n//m;
			     $chunk =~ s/Link: .*\s*\n//m;
			     $chunk =~ s/Title: .*\s*\n//m;
			 }
			 print $chunk;
		     },
    1024
		     );
        close(MFORMFILE);
        unlink("$temp_dir/mform$$.tmp");
	return '';
    } else {
	$result = $ua->request($req)->as_string;
	$result =~ s/\r//gm;
	$result =~ s/\t/\r/gm;
	$result =~ s/\n/\t/gm;
	$| = 1;
        my($last_result);
        # Remove any lines between HTTP and Content-Type
	while ($result !~ /^HTTP[^\t]*\s+\d+[^\t]*\t\s*Content-[Tt]ype:/ &&
               $result ne $last_result) {
        $last_result = $result;
             ($removed) = $result =~ /^HTTP[^\t]*\s+\d+[^\t]*\t([^\t]*)\t/;
             $result =~ s/^(HTTP[^\t]*\s+\d+[^\t]*\t)[^\t]*\t/\1/;
             
        }
	$result =~ s/\t/\n/gm;
	$result =~ s/\r/\t/gm;
	$result =~ s/HTTP.*\s+(\d+)\s+OK/Status: \1 OK/m;
	$result =~ s/Content-[Tt]ype: (.*)\n/Content-Type: \1\n\n\n/m;
	$result =~ s/Connection: close\s*\n//m;
	$result =~ s/Client-Date: .*\s*\n//m;
	$result =~ s/Client-Peer: .*\s*\n//m;
	$result =~ s/Date: .*\s*\n//m;
	$result =~ s/Server: .*\s*\n//m;
	$result =~ s/Link: .*\s*\n//m;
	$result =~ s/Title: .*\s*\n//m;
        close(MFORMFILE);
        unlink("$temp_dir/mform$$.tmp");
	return $result;
    }
}

1;
