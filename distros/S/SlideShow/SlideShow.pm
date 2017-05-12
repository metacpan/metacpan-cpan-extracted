package SlideShow;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '2.0';

@SlideShow::ISA = qw(HTML::Parser);

use CGI qw/:standard/;
use LWP::UserAgent;
use HTML::Parser;
use URI::Escape;

sub new {
  my $class = shift;

  my $self = HTML::Parser->new();
  bless $self, $class;

  while (my $X = shift) {
    my $Y = shift;
    $self->{$X} = $Y;
  }

  die "SlideShow::Master missing required parameter 'master_cgi'"
      unless exists $self->{master_cgi};

  $self->{start_title} = "SlideShow Startup" 
      unless exists $self->{start_title};
  $self->{tmp_dir}     = "/tmp"
      unless exists $self->{tmp_dir};
  $self->{view_file}   = "$self->{tmp_dir}/viewfile.html"
      unless exists $self->{view_file};
  $self->{log_file}    = "$self->{tmp_dir}/surflog.last"
      unless exists $self->{tmp_log};
  $self->{tmp_log}     = "$self->{tmp_dir}/surf.tmp"
      unless exists $self->{tmp_log};

  $self->{url_list} =  [ "http://www.perl.com/CPAN/" ]
      unless exists $self->{url_list};

  $self->{commentary}  = "Presented using SlideShow, a Perl module"
      . " for remote browser control available at"
	  ." <a href=\"http://www.perl.com/CPAN/\">www.perl.com/CPAN/</a>"
	      unless exists $self->{commentary};

  $self->{redirect} = "$self->{master_cgi}?URL=";
  $self->{inside}    = 0;

  $self->{ua} = new LWP::UserAgent;
  $self->{ua}->agent("SlideShow/2.0");
  $SlideShow::last_marker = '<!-- last -->';

  $self;
}

sub run {
  my $self = shift;

  if (not param()) {
    # no URL given
    print 
	header,
	start_html(-title => $self->{start_title},
		   -BGCOLOR => "#FFFFFF"),
	h1($self->{start_title}),
	start_form,
	submit('Show URL'),
	textfield('URL'),
	end_form;

    if ($self->{url_list}) {
      print hr;
      print h2('presets');
      print "<UL>\n";
      for my $url (@{$self->{url_list}}) {
	print "<LI> <a href=\"$self->{master_cgi}?URL=$url\">$url</a>\n";
      }
      print "</UL>\n";
    }
    
    if ($self->{commentary}) {
      print hr;
      print $self->{commentary};
    }

    print end_html;

  } else {
    my $current_http_dir = param('URL');
    $current_http_dir =~ s/\s+$//;

    if (substr($current_http_dir, -1, 1) ne '/') {
      $current_http_dir =~ s!^(http://.*/).*!$1!;
    }

    $self->{current_dir} = $current_http_dir;

    print header;

    my $item = param('URL');

    unlink($self->{view_file});

    if (not open VIEWFILE, ">$self->{view_file}") {
      print "<p> can't create $self->{view_file}: $! </p>\n";
    } else {
      print VIEWFILE $$."\n";

      if ($item =~ /^\s*last\s*$/) {
	print VIEWFILE $SlideShow::last_marker."\n"; # send the termination
	close VIEWFILE;

	if (-e $self->{tmp_log}) {
	  unlink ($self->{log_file});
	  rename ($self->{tmp_log}, $self->{log_file});
	}

	print 
	    start_html(-title => "Session finished",
		       -BGCOLOR => "#FFFFFF"),
	    h1("Session finished");

	print "<a href=\"$self->{master_cgi}\">New Session</a>",p;

	if ($self->{log_file}) {
	  print "<hr>\n";
	  print "<i>The pages were visited in this order:</i><p>\n";
	  
	  open(LOG, $self->{log_file});
	  
	  while(<LOG>) {
	    print "  <LI>".$_;
	  }
	  close(LOG);
	  print "<hr>\n";
	  print "Save this document locally if you'd like to"
	      . " keep a record.\n";
	}

	sleep(4);	# sleep longer than the update time for clients
	unlink ($self->{view_file});	
	exit 0;
      }

      my $req = new HTTP::Request 'GET' => $item;
      my $res = $self->{ua}->request($req);

      if (not $res->is_success) {
	print "Error: " . $res->status_line . "\n";
      } else {
	my $item = $res->as_string;
	print $self->rewrite($item, "master");
	print VIEWFILE $self->rewrite($item, "viewer");
	if ($self->{log_file}) {
	  open LOG, ">>$self->{tmp_log}"
	      or die "can't open $self->{tmp_log}: $!";
	  print LOG param('URL')."\n";
	  close LOG;
	}
      }
      close VIEWFILE;

    }
    print end_html;
  }
}

sub start {
  my $self = shift ;
  my ($tag, $attr, $attrseq, $origtext) = @_;

  $self->{result} .= '<' . $tag;

  if (lc($tag) eq 'html') {
    $self->{inside} = 1;
  }

  return unless $self->{inside};
  my $dirpref = $self->{current_dir};

  my $hostpref = $dirpref;
  $hostpref =~ s!^((?:ht|f)tp://[^\/]+).*!$1/!;

  if (defined $dirpref) {
    $dirpref .= '/' unless 
	substr($dirpref, -1, 1) eq '/';
  }

  if (defined $attr->{'src'}) {
    # fully qualify any relative IMG paths 
    # perhaps this should get the images locally and
    # serve them up, too, but for now it still points
    # to the original sites.
    if ($attr->{'src'} !~ m!^(?:ht|f)tp://!i) {
      if (substr($attr->{'src'}, 0, 1) eq '/') {
	$attr->{'src'} = $hostpref . $attr->{'src'};
      } else {
	print STDERR "$attr->{'src'} -> ";
	$attr->{'src'} = $dirpref  . $attr->{'src'};
	print STDERR "$attr->{'src'}\n";
      }
    }
    $attr->{'src'} =~ s|/+$|/|;
  }

  if (defined $attr->{'href'}) {
    if ($attr->{'href'} !~ m!^(ht|f)tp://!i) {
      if (substr($attr->{'href'}, 0, 1) eq '/') {
	$attr->{'href'} = $hostpref . $attr->{'href'};
      } else {
	$attr->{'href'} = $dirpref . $attr->{'href'};
      }
    }
    $attr->{'href'} =~ s!/+$!/!;
  }

  if ($tag eq 'a') {
    if ($attr->{'href'}) {

      if ($self->{'which'} eq 'master') {
	# redirect HREFs on the master back into the CGI
	my $h = $self->{redirect} . $attr->{'href'};
	$attr->{'href'} = $h;
      } else {
	# convert the viewer's HREFs to some style
	# change so that aren't as easily tempted
	# to click off the path
	delete $attr->{'href'};

	$attr->{'color'} = 'red';

	push @$attrseq, 'color'
	    unless grep $_ eq 'color', @$attrseq;
      }
    }
  }

  for my $m (@$attrseq) {
    $self->{result} .= " $m=\"$attr->{$m}\"";
  }

  $self->{result} .= '>';
  if ($tag eq 'body' and $self->{which} eq 'master') {
    $self->{result} .= "<font size=-2><p align=right>\n";
    $self->{result} .= "\nSlideShow: ";
    $self->{result} .= "<a href=\"$self->{master_cgi}\">Top</a> | ";
    $self->{result} .= "<a href=\"$self->{master_cgi}?URL=last\">Quit</a> ";
    $self->{result} .= "</font></p>\n";
  }
  
  $self->{result};
}

sub text {
  my $self    = shift ;
  my $text    = shift;

  return unless $self->{inside};

  $self->{result} .= $text;
}

sub comment {
  my $self    = shift ;
  my $comment = shift;
  return unless $self->{inside};
  $self->{result} .= "<!-- $comment -->";
}

sub end {
  my $self = shift ;
  return unless $self->{inside};

  my ($tag, $origtext) = @_;
  if (lc($tag) eq 'html') {
    $self->{inside} = 0;
  }
  if (lc($tag) eq 'body' and $self->{which} eq 'master') {
    $self->{result} .= "\n";

    $self->{result} .= start_form 
	. submit('Next Slide:') 
	    . textfield(-name => 'URL', -size=>40, -default=>param('URL'))
		. end_form;
  }
  $self->{result} .= $origtext;
}

sub rewrite {
  my $self = shift;
  my $html = shift;
  my $which = shift;

  $html =~ s/^.*?(<html)/$1/is;

  if (lc($which) eq 'viewer') {
    $self->{which} = 'viewer';
  } else {
    $self->{which} = 'master';
  }

  $self->{result}   = '';

  $self->parse($html);

  return $self->{result};
}

sub client {
  my %p;
  while (shift) {
    $p{$_} = shift;
  }

  $p{view_file}   = "/tmp/viewfile.html"
      unless $p{view_file};

  $p{log_file}    = "/tmp/surflog.last"
      unless $p{log_file};
# $DEBUG = 1;

# Unbuffer STDOUT
  $|=1;

  print "HTTP/1.0 200 OK\n";
  print "Content-type: multipart/x-mixed-replace;boundary=ThisRandomString\n";
  print "\n";
  print "--ThisRandomString\n";

  my $prev_surf_id = "-1";
  my $done         = 0;
  my $count        = 0;
  my $TIMEOUT      = 60 * 4;	# (browser timeout is typically 5 minutes)

#
# wait for the file to show up
#   present the startup message until it does
# 
  while (!-r $p{view_file}) {
    print "Content-type: text/html\n\n";

    print "<HTML>\n";
    print "<head><title>Waiting for session</title></head>\n";
    print "<body bgcolor=\"#ffffff\">\n";
    print "<h2>Presentation view</h2>\n";

    print "time: ".`date`."<p>\n";
    print "Waiting for session to begin...<br>\n\n";

    print "</body>\n";
    print "</HTML>\n";

    print "--ThisRandomString\n";
    sleep(5);
  }

#
#  Once we've seen the file, we're in a presentation.
#
  my ($line, $surf_id);
  while(($count < $TIMEOUT) && !$done) {
    $count++;
    $line = 0;
    if (open(ITEM, $p{view_file})) {
      while (my $item = <ITEM>) {
	$line++;
	if ($line == 1) {
	  chop $item;
	  $surf_id = $item;

	  if ($prev_surf_id eq $surf_id) {
	    last;
	  } else {
	    $prev_surf_id = $surf_id;
	    print "Content-type: text/html\n\n";

	    ## Reset the presentation counter
	    $count = 0;

	    next;
	  }
	}

	if ($item =~ /^$SlideShow::last_marker$/) {
	  print "<HTML>\n";
	  print "<HEAD><TITLE>Session finished</TITLE></HEAD>\n";
	  print "<BODY bgcolor=\"#ffffff\">\n";

	  print '
<H2>Thank you</H2>

The session has finished.<br>
';
	  if ($p{log_file}) {
	    print "<hr>\n";
	    print "<i>The pages were visited in this order:</i><p>\n";
	    
	    open(LOG, $p{log_file});
	    
	    while(<LOG>) {
	      print "  <LI>".$_;
	    }
	    close(LOG);
	    print "<hr>\n";
	    print "Save this document locally if you'd like to"
		. " keep a record.\n";
	  }
	  $done = 1;
	  next;
	}

	print $item; 
      }
      close(ITEM);
      print "\n--ThisRandomString\n" if ($line > 1);
    }
    sleep(1);
  }

  if ($count >= $TIMEOUT) {
    print "--ThisRandomString\n";

    print "Content-type: text/html\n\n";
    print "<HTML>\n"; 
    print '<BODY bgcolor="#ffffff">',"\n";
    print "<h2>Timed out.</h2>\n";
    print "<hr>\n";
    print "<I>This session has been active without update for too long.<br>\n";
    print "Hit <b>Reload</b> if you think the session is still in progress.\n";
    print "</HTML>\n"; 
  }

  print "--ThisRandomString--\n";
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SlideShow - Perl extension remote presentation

=head1 SYNOPSIS

  use SlideShow;
  new SlideShow
    (master_cgi  => "http://127.0.0.1/cgi-bin/master",
     start_title => "My SlideShow",
     url_list    => [qw(http://www.perl.com http://www.infobot.org)],
     )->run;

  perl -MSlideShow -e 'SlideShow->new()->run';
  perl -MSlideShow -e 'SlideShow->client()->run';


=head1 DESCRIPTION

SlideShow is a device for giving presentations over the Web.
It allows one user (the B<master>) to control the content 
that appears on other user (B<client>) browsers by using 
server pushes.

For example, you could arrange a conference call or radio
broadcast, and then tell everyone to point their browsers
at a client CGI, and then give the talk with visual materials.

=head1 PREREQUISITES

LWP::UserAgent, HTTP::Request, HTML::Parser, 
CGI.pm, and web server that will allow you to run CGIs.

=head1 RUNNING A SLIDESHOW

You will need a web server that will allow you to use CGI,
but it is otherwise a simple matter to run a SlideShow.  

First, have the session leader start a master session.
This is done by creating a SlideShow object and passing
it a few parameters, such as:

=over 4

=item B<master_cgi> The URL to the master CGI program, wherever
you are utting it. [Required].

=item B<view_file> Where to keep the currently-showing pages.

=item B<start_title> The title that shows up on the master session
at startup.

=item B<url_list> A list of URLs to use as presets to start off
the session with.

=item B<tmp_dir> Where to keep the temporary files.  default is
C</tmp>.

=item B<log_file> Where to put the final log of all pages visited.

=item B<commentary> A little message that goes on the master 
startup page.  HTML can be included verbatim.

=head1 EXAMPLES

=item for the master session:

  use SlideShow;

  new SlideShow
    (master_cgi  => "http://127.0.0.1/cgi-bin/master",
     start_title => "My SlideShow",
     view_file   => "/tmp/viewfile.html",
     url_list    => [qw(http://www.perl.com http://www.infobot.org)],
     )->run;

=item for the clients/viewers: 

  use SlideShow;

  SlideShow::client(view_file => "/tmp/viewfile.html");

=item NOTE: the push involved non-parsed headers (NPH) and
many browsers require that a CGI be named with the 
prefix 'nph-', such as 'nph-view', to work properly.

See the included examples, B<slideshow-master> and 
B<nph-slideshow-viewer>.

=head1 BUGS 

Requires someone or something to lead the session.  
Autonomous shows should be added.

=head1 AUTHOR

Kevin A. Lenzo <lenzo@cs.cmu.edu>

=head1 SEE ALSO

perl(1), L<LWP::UserAgent>, L<HTTP::Request>, 
L<HTML::Parser>, L<CGI>.

=cut

