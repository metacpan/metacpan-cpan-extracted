package QWizard::Generator::HTML::Vertical;

use strict;
use QWizard::Generator::HTML;
use Exporter;
use CGI qw(escapeHTML);

our $VERSION = '3.15';

@QWizard::Generator::HTML::Vertical::ISA =
  qw(Exporter QWizard::Generator::HTML);

#
# we inherit everything from the HTML class...  including the new() routine.
#

#
# functions to override the parent and change the layout.
#
sub do_question {
    my ($self, $q, $wiz, $p, $text, $qcount) = @_;
    return if (!$text && $q->{'type'} eq 'hidden');
    print "  <p>\n";
    if ($q->{'helptext'}) {
	print $wiz->make_help_link($p, $qcount),
	  escapeHTML($text), "</a>\n";
    } else {
	print escapeHTML($text);
    }
    if ($q->{'helpdesc'}) {

      #
      # Get the actual help text, in case this is a subroutine.
      #
      my $helptext = $q->{'helpdesc'};
      if (ref($helptext) eq "CODE") {
          $helptext = $helptext->();
      }

      print "<br><small><i>" . escapeHTML($helptext) . "</i></small>";
    }
    print "<ul>\n";
}

sub do_question_end {
    my ($self, $q, $wiz, $p, $qcount) = @_;

    #
    # help text
    #
    return if (!$q->{'text'} && $q->{'type'} eq 'hidden');
    print "</ul>\n";
}

sub start_questions {
    my ($self, $wiz, $p, $title, $intro) = @_;
    if ($title) {
	print $self->{'cgi'}->h1(escapeHTML($title)),"\n";
    }
    if ($intro) {
	$intro = escapeHTML($intro);
	$intro =~ s/\n\n/\n<p>\n/g;
	print "$intro\n</p><p>\n";
    }
}

sub end_questions {
    my ($self, $wiz, $p) = @_;

    #
    # This focus() call should allow the user to type directly into the
    # first text box without having to click there first.
    #
    print "<script>\n";
    print "document.forms[0].elements[0].focus();\n";
    print "</script>\n";

    $self->{'started'} = $wiz->{'started'} = 0;
}


sub do_error {
    my ($self, $q, $wiz, $p, $err) = @_;
    print "<font color=red>" . escapeHTML($err) . "</font>\n";
}

sub do_separator {
    my ($self, $q, $wiz, $p, $text) = @_;
    if ($text eq "") {
	$text = "&nbsp";
    } else {
	$text = escapeHTML($text);
    }
    print "  <p>$text</p>";
}

1;
