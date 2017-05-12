#!/usr/local/bin/perl
#
#
#
# A CGI script that get a URL of an HTML and generates a very simple 
# spelling version of this HTML.
#
#
use CGI;
use LWP::UserAgent;
use Text::Pspell;
use Regexp::IgnoreHTML;

####################################################################
# YOU MUST CHANGE THE VALUES BELOW TO FIT YOUR INSTALLATION
my $PROXY = 'http://mikush:80/'; # if you have no proxy, leave this 
                                 # as an empty string
my $URL = "http://mikush/cgi-bin/zap/speller.pl";
####################################################################


my $cgi = new CGI;

my $ua = new LWP::UserAgent;
if ($PROXY) {
  $ua->proxy('http', $PROXY);
}

#print "Content-Type: text/html\n\n"; # for debugging
$| = 1;
#open(STDERR, ">&STDOUT"); # for debugging
 
my $url = $cgi->path_info()."?".$cgi->query_string();
$url =~ s/(http\:\/)([^\/])/$1\/$2/; # fix http:/ to http:// (for htdig)
$url =~ s/^\///; # remove starting slash
$url =~ s/\?$//; # remove trailing question mark

$url =~ /http\:\/\/[^\/]+/i;
my $remote_machine_url = $&;

# Create a request
my $req = new HTTP::Request(GET => $url);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if ($res->is_success) {
    my $header = $res->headers_as_string();
    my $content = $res->content;
    if ($res->header("Content_Type") =~ /text\/html/i) {
       # add to all the absolute URIs the URI of this script
       # absolute means - starting with http:// or with /
       # add "$URL/" before any http://
       $content =~ s/(http\:\/\/)/$URL\/$1/g;
       
       # add "$URL/" after any href="/ or src="/
       $content =~ 
           s/((href|src)\s*\=\s*[\"\'])\//$1$URL\/$remote_machine_url\//gi;

       # now we will spell the content
       $content = spell($content);

       # find the title
       my $url_for_code = $url; 

       $url_for_code =~ s/^[\s\S]+:\/+[^\/]+\/([^\:]+)$/$1/;

       # now we fix the header content-length
       $content_length = length($content);
       $header =~ s/Content-Length: (\d+)/Content-Length: $content_length/;
    }
    # print the header, and the content
    print "$header\n";
    print $content;
} else {
    print "Content-Type: text/html\n\n";
    print "Bad luck this time\n";
}

############################
# spell
############################
sub spell {
    # get the HTML that should be examined
    my $html_text = shift;

    # create the Text::Pspell object
    my $speller = Text::Pspell->new;
    
    # set some options
    $speller->set_option('language-tag','en_US');
    $speller->set_option('sug-mode','fast');

    my $rei = new Regexp::IgnoreHTML($html_text,
				     "<!-- __INDEX__ -->");
    $rei->space_after_non_text_characteristics_html(1);
    
    # split the wanted text from the unwanted text
    $rei->split();
    
    $rei->translation_position_factor(0);
    my $cleaned_text = $rei->cleaned_text();
    my $buffer = "";
    my $last_position = 0;
    # for each word
    while ($cleaned_text =~ /(\&?)[a-zA-Z0-9\-]+(\;?)/g) {
	my $match = $&;	
	my $end_match_position = pos($cleaned_text) - 1;
	my $match_length = length($match);
	my $start_match_position = $end_match_position - $match_length + 1;
	
	my $replacer = $match; # we assume the match is spelled correctly

	# make sure we didn't find any &xxxx; like &nbsp;
	unless ($match =~ /^\&[a-zA-Z0-9\-\']+\;$/) {
	    # now we check the spell
	    unless ($speller->check( $match )) { # if the match is not 
		                                 # spelled correctly
		my @suggestions = $speller->suggest( $match );
		my $suggestions = join(", ", @suggestions);    
		$replacer = "<font color=red>$match</font>".
		    "<a href=\"javascript:alert('spelling suggestions: ".
			"$suggestions')\">?!</a>";
	    }
	}
	$rei->replace(\$buffer,
		      \$last_position,
		      $start_match_position,
		      $end_match_position,
		      $replacer);
    }
    $buffer .= substr($rei->cleaned_text(), $last_position);
    $rei->cleaned_text($buffer);

    # merge back to get the resulted text
    my $changed_text = $rei->merge();
}
