package QWizard::Generator::HTML;

#
# isprint() appears to be broken on some machine.  This will determine if
# it's broken here and tell us how to proceed later.
#
my $use_np_isprint = 0;
if(isprint("abc\000abc") || isprint("abc\001abc") || !isprint("barra"))
{
	$use_np_isprint = 1;
}


use strict;
our $VERSION = '3.15';
use CGI qw(escapeHTML);
use CGI::Cookie;
require Exporter;
use QWizard::Generator;
use QWizard::Storage::CGIParam;
use QWizard::Storage::CGICookie;
use IO::File;
use POSIX qw(isprint);

my $defaultcss = "
body {
  font-family:verdana, arial, helvetica, sans-serif;
  background-color: white;
}

span.centersection {
  width: 100%;
}

h1 {
 /* top and bottom borders: 1px; left and right borders: 0px*/
  border-width:1px;
  border-color:black;
  border-style:solid;
  background-color: #9df;
  padding-left: 5px;
}

input,.qwcheckbox,select,.qwradio,.qwtext {
  background-color: #cff;
}

.qwnext {
  margin-top: 15px;
  background-color: #9df;
  float: left;
}

.qwcancel {
  margin-top: 15px;
  background-color: #9df;
  float: right;
}

p {
  margin-left: 25px;
}

h2 {
 /* top and bottom borders: 1px; left and right borders: 0px*/
  border-width:1px;
  border-color:black;
  border-style:solid;
  background-color: #9df;
  margin-left: 10px;
  padding-left: 5px;
}

#qwlabelpagenum {
  font-weight: bold;
}

#qwlabelpageauthor {
  font-weight: bold;
}

#qwparagraphstory {
  font-family:verdana, arial, helvetica, sans-serif;
}

#story {
 /* top and bottom borders: 1px; left and right borders: 0px*/
  border-width:1px 0px;
  border-color:black;
  border-style:solid;
  background-color: #93d5ea;
}

#qwtablewhatnext {
  border-color:black;
  border-style:solid;
  background-color: #93d5ea;
  width: 100%;
}

#qwlabel {
  align: left;
}

#qwtablerowwhatnext {
  align: left;
  border-width:10px 0px;
}

#qwtablewidget {
  align: left;
  border-width:10px 0px;
}

";

@QWizard::Generator::HTML::ISA = qw(Exporter QWizard::Generator);

our %defaults = (
		 form_name => 'qwform',
		 tmpdir => '/tmp',
		 one_pass => 1,
	       );

our $have_gd_graph = eval { require GD::Graph::lines; };

our $redo_screen_js =
  "this.form.redo_screen.value=1; this.form.submit();";

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my %self = %defaults;
    for (my $i = 0; $i <= $#_; $i += 2) {
	$self{$_[$i]} = $_[$i+1];
    }
    my $self = \%self;
    bless($self, $class);
    $self->add_handler('text',\&QWizard::Generator::HTML::do_entry,
		       [['single','name'],
			['default'],
			['forced','0'],
			['single','size'],
			['single','maxsize'],
			['single','submit'],
			['single','refresh_on_change']]);
    $self->add_handler('hidetext',\&QWizard::Generator::HTML::do_entry,
		       [['single','name'],
			['default'],
			['forced','1'],
			['single','size'],
			['single','maxsize'],
			['single','submit'],
			['single','refresh_on_change']]);
    $self->add_handler('textbox',\&QWizard::Generator::HTML::do_textbox,
		       [['default'],
			['single', 'width'],
			['single', 'size'],
			['single', 'height'],
			['single', 'submit'],
			['single','refresh_on_change']]);
    $self->add_handler('checkbox',\&QWizard::Generator::HTML::do_checkbox,
		       [['multi','values'],
			['default'],
			['single', 'submit'],
			['single','refresh_on_change'],
			['single','button_label']]);
    $self->add_handler('multi_checkbox',
		       \&QWizard::Generator::HTML::do_multicheckbox,
		       [['multi','default'],
			['values,labels'],
			['single','submit'],
			['single','refresh_on_change']]);
    $self->add_handler('menu',
		       \&QWizard::Generator::HTML::do_menu,
		       [['values,labels', "   "],
			['default'],
			['single','submit'],
			['single','refresh_on_change'],
			['single', 'name']]);
    $self->add_handler('radio',
		       \&QWizard::Generator::HTML::do_radio,
		       [['values,labels'],
			['default'],
			['single','submit'],
			['single','refresh_on_change'],
			['single','name'],
			['single','icons'],
			['single','noiconpadding'],
		       ]);
    $self->add_handler('label',
		       \&QWizard::Generator::HTML::do_label,
		       [['multi','values']]);
    $self->add_handler('link',
		       \&QWizard::Generator::HTML::do_link,
		       [['single','linktext'],
			['single','url']]);
    $self->add_handler('paragraph',
		       \&QWizard::Generator::HTML::do_paragraph,
		       [['multi','values'],
			['single','preformatted']]);
    $self->add_handler('button',
		       \&QWizard::Generator::HTML::do_button,
		       [['single','values']]);
    $self->add_handler('table',
		       \&QWizard::Generator::HTML::do_table,
		       [['norecurse','values'],
			['norecurse','headers']]);
    $self->add_handler('bar',
		       \&QWizard::Generator::HTML::do_bar,
		       [['norecurse','values']]);
    $self->add_handler('graph',
		       \&QWizard::Generator::HTML::do_graph,
		       [['norecurse','values'],
			['norecursemulti','graph_options']]);
    $self->add_handler('image',
		       \&QWizard::Generator::HTML::do_image,
		       [['norecurse','imgdata'],
			['norecurse','image'],
			['single','imagealt'],
			['single', 'height'],
			['single', 'width']]);
    $self->add_handler('fileupload',
		       \&QWizard::Generator::HTML::do_fileupload,
		       [['default','values']]);
    $self->add_handler('filedownload',
		       \&QWizard::Generator::HTML::do_filedownload,
		       [['single','name'],
			['default'],
			['single','data'],
			['noexpand','datafn'],
			['single','extension'],
			['single','linktext']
		       ]);

    $self->add_handler('unknown',
		       \&QWizard::Generator::HTML::do_unknown,
		       []);

    $self->{'datastore'} = new QWizard::Storage::CGIParam;
    $self->{'prefstore'} = new QWizard::Storage::CGICookie;

    return $self;
}

sub init_cgi {
    my $self = shift;
    if (!exists($self->{'cgi'})) {
	# we do this here late binding as possible for various reasons
	$self->{'cgi'} = new CGI;
    }
}

sub init_screen {
    my ($self, $wiz, $title) = @_;
    $self->init_cgi();

    return if ($self->{'started'} || $wiz->{'started'});
    $self->{'started'} = $wiz->{'started'} = $self->{'prefstore'}{'started'} =1;
    $self->{'first_tree'} = 1;
    my @otherargs;
    if ($self->{'cssurl'}) {
	push @otherargs, 'style', { src => $self->{'cssurl'}};
    } elsif (!$self->{'nocss'}) {
	push @otherargs, 'style', { code => $defaultcss };
    }
    print "Content-type: text/html\n\n" if (!$self->{'noheaders'} &&
					    !$wiz->{'noheaders'});
    print $self->{'cgi'}->start_html(-title => escapeHTML($title),
				     -bgcolor => $self->{'bgcolor'}
				     || $wiz->{'bgcolor'} || "#ffffff",
				     @otherargs);

    if ($self->{'prefstore'}->{'immediate_out'} &&
	$#{$self->{'prefstore'}->{'immediate_out'}} > -1) {
	print @{$self->{'prefstore'}->{'immediate_out'}};
	delete $self->{'prefstore'}->{'immediate_out'};
    }
    print $self->{'cgi'}->start_multipart_form(-name => $self->{'form_name'}),
      "\n";
    $self->{'wizard'} = $wiz;
}

# html always waits
sub wait_for {
  my ($self, $wiz, $next, $p) = @_;
  print $self->{'cgi'}->end_form();
  print "</tr>\n" if (exists($self->{'nocss'}));
  $self->close_div_or_table(); # end for <div class="qwizard"> in start_primaries
  return 1;
}

sub do_css {
    my ($self, $class, $name, $noidstr) = @_;
    if (!exists($self->{'nocss'})) {
	my $idstr = '';
	$idstr = $class if (!$noidstr);
	return " class=\"$class\" id=\"$idstr$name\" ";
    }
    return "";
}

sub open_div_or_table {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "<div class=\"" . $_[0] . "\">\n";
    } else {
	print "<table $_[1]>\n";
    }
}

sub close_div_or_table {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "</div>\n";
    } else {
	print "</table>\n";
    }
}

sub open_div_or_tr {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "<div class=\"" . $_[0] . "\">\n";
    } else {
	print "<tr $_[1]>\n";
    }
}

sub open_span_or_td {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "<span class=\"" . $_[0] . "\">\n";
    } else {
	print "<td valign=\"top\" $_[1]>\n";
    }
}

sub close_span_or_td {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "</span>\n";
    } else {
	print "</td>\n";
    }
}

sub close_div_or_tr {
    my $self = shift;
    if (!exists($self->{'nocss'})) {
	print "</div>\n";
    } else {
	print "</tr>\n";
    }
}

sub get_image {
    my ($self, $img, $css, $name) = @_;

    return "<img" . $self->do_css($css,$name) .
      " src=\"" . $self->{'imgpath'} . escapeHTML($img) . "\"> ";
}

sub do_question {
    my ($self, $q, $wiz, $p, $text, $qcount) = @_;
    return if (!$text && $q->{'type'} eq 'hidden');
    my $padtext;
    $padtext=" style=\"padding-left: 2em;\"" if ($q->{'indent'});
    print "  <tr" . $self->do_css('qwquestion',$q->{'name'}) . ">";
    print "<td" . $self->do_css('qwquestiontext',$q->{'name'}) . 
      " valign=top $padtext>\n";
    $text = QWizard::Generator::remove_accelerator($text);
    if ($q->{'helptext'}) {
	print $wiz->make_help_link($p, $qcount),
	  $self->maybe_escapeHTML($text, $q->{'noescape'}), "</a>\n";
    } else {
	print $self->maybe_escapeHTML($text, $q->{'noescape'});
    }
    if ($q->{'helpdesc'}) {

      #
      # Get the actual help text, in case this is a subroutine.
      #
      my $helptext = $q->{'helpdesc'};
      if (ref($helptext) eq "CODE") {
          $helptext = $helptext->();
      }
      print "<br><small><i>" . 
	$self->maybe_escapeHTML($helptext, $q->{'noescape'}) . "</i></small>";
    }
    print "</td><td" . $self->do_css('qwquestion',$q->{'name'}, 1) . ">\n";
}

sub do_question_end {
    my ($self, $q, $wiz, $p, $qcount) = @_;

    #
    # help text
    #
    return if (!$q->{'text'} && $q->{'type'} eq 'hidden');
    print "</tr>\n";
}

sub start_questions {
    my ($self, $wiz, $p, $title, $intro) = @_;
#    print "<td id=\"qwmain\" width=\"100%\">\n";
    print "<span id=\"qwmain\">\n";
    if ($title) {
	print $self->{'cgi'}->h1(escapeHTML($title)),"\n";
    }
    if ($intro) {
	$intro = $self->maybe_escapeHTML($intro, $p->{'noescape'});
	$intro =~ s/\n\n/\n<p class=\"qwintroduction\">\n/g;
	print "<p class=\"qwintroduction\">$intro\n<p class=\"qwintroduction\">\n";
    }
    print "<table class=\"qwquestions\">\n";
    $self->{'intable'} = 1;
}

sub end_questions {
    my ($self, $wiz, $p) = @_;
    print "</table>\n";
#    print "</td>\n";
    print "</span>\n";
    #
    # This focus() call should allow the user to type directly into the
    # first text box without having to click there first.
    #
    print "<script>\n";
    print "document.forms[0].elements[0].focus();\n";
    print "</script>\n";

    $self->{'started'} = $wiz->{'started'} = 0;
    delete($self->{'intable'});
}

sub do_pass {
    my ($self, $wiz, $name) = @_;
    $self->do_hidden($wiz, $name, $self->qwparam($name)) 
      if ($self->qwparam($name) ne '');
}

##################################################
# Bar support
##################################################

sub start_bar {
    my ($self, $wiz, $name) = @_;
    if ($self->{'intable'}) {
	print "</table>\n";
    }
    print "<div " . $self->do_css('qwbar',$name) . ">\n";
}

sub end_bar {
    my ($self, $wiz, $name) = @_;
    print "</div>\n";
    if ($self->{'intable'}) {
	print "<table class=\"qwquestions\">\n";
    }
}

sub do_bar {
    my ($self, $q, $wiz, $p, $widgets) = @_;

    $self->start_bar($wiz, undef);
    $self->do_a_table([$widgets], 0, $wiz, $q, $p);
    $self->end_bar($wiz, 'Questions');
}

sub do_top_bar {
    my ($self, $q, $wiz, $p, $widgets) = @_;

    print "<tr><td colspan=\"10\">" if (exists($self->{'nocss'}));
    $self->do_a_table([$widgets], 0, $wiz, $q, $p, 'topbar', 'topbar','topbar');
    print "</td></tr>\n" if (exists($self->{'nocss'}));
}

sub start_center_section {
    my ($self) = @_;
    $self->open_span_or_td("centersection");
}

sub end_center_section {
    my ($self, $wiz, $p, $next) = @_;
    print "<div class=\"buttons\">\n";
    print "  <input class=qwnext type=submit value=\"" . escapeHTML(QWizard::Generator::remove_accelerator($next)) . "\">\n";
    $self->do_hidden($wiz, "redo_screen", 0) if (!$self->qwparam('redo_screen'));
    if ($self->qwparam('allow_refresh') || $p->{'allow_refresh'}) {
	print "<input type=submit onclick=\"$redo_screen_js\" name=redo_screen_but value=\"Refresh Screen\">\n";
    }
    print "  <input class=qwcancel name=\"qw_cancel\" type=submit value=\"Cancel\">\n" if (!$self->{'no_cancel'});
    print "</div>\n";
    $self->close_span_or_td();
}

sub start_primaries {
    my ($self) = @_;
    # this is closed in wait_for()
    $self->open_div_or_table("qwizard");
    print "<tr>\n" if (exists($self->{'nocss'}));
}

sub do_side {
    my ($self, $spot, $q, $wiz, $p, $widgets) = @_;
    $self->open_span_or_td($spot);

    my @tableinfo;
    foreach my $w (@$widgets) {
	next if (!$w);
	if (ref($w) eq 'ARRAY') {
	    # special stand-alone side component
	    my $title = "";
	    $title = shift(@$w) if (ref($w->[0]) eq '');
	    my $id = $title;
	    $id =~ s/\W//;
	    print "<div id=\"side$id\" class=\"side\">\n";
	    print "<div id=\"sidetitle$id\" class=\"sidetitle\">" .
	      escapeHTML($title) . "</div>\n" if ($title);
	    print "<table id=\"sidecontent$id\" class=\"sidecontent\">\n";
	    foreach my $widget (@$w) {
		# print "widget: $widget\n";
		$wiz->ask_question($p, $widget);
	    }
	    print "</table>\n";
	    print "</div>\n";
	} else {
	    # add to the default (bottom) table component
	    push @tableinfo, [$w];
	}
    }

    $self->do_a_table(\@tableinfo, 0, $wiz, $q, $p, $spot);
    $self->close_span_or_td();
}

sub do_left_side {
    my $self = shift;
    $self->do_side('leftside', @_);
}

sub do_right_side {
    my $self = shift;
    $self->do_side('rightside', @_);
}

##################################################
# widgets
##################################################

sub do_button {
    my ($self, $q, $wiz, $p, $vals) = @_;
    print "<input" . $self->do_css('qwbutton',$q->{'name'}) . " type=submit name=\"$q->{'name'}\" value=\"" . QWizard::Generator::remove_accelerator($vals) . "\">\n";
}

sub do_checkbox {
    my ($self, $q, $wiz, $p, $vals, $def, $submit, $refresh_on_change,
	$button_label) = @_;
    $vals = [1, 0] if ($#$vals == -1);
    my $otherstuff;
    if ($def == $vals->[0]) {
	$otherstuff .= " checked";
    }
    if ($#$vals > -1) {
	$otherstuff .= " value=\"" . escapeHTML($vals->[0]) . "\"";
    }
    if ($submit) {
	$otherstuff .= " onclick=\"this.form.submit()\"";
    }
    if ($refresh_on_change) {
	$otherstuff .= " onclick=\"$redo_screen_js\"";
    }
    if ($button_label) {
	print "<span " . $self->do_css('qwbuttonlabel',$q->{'name'}) . ">";
    }
    print "<input" . $self->do_css('qwcheckbox',$q->{'name'}) . " type=checkbox name=\"$q->{name}\"$otherstuff>";
    if ($button_label) {
	print " $button_label</span>\n";
    }
}

sub do_multicheckbox {
    my ($self, $q, $wiz, $p, $defs, $vals, $labels,
	$submit, $refresh_on_change) = @_;
    print "<table>";
    my $count = -1;
    my ($startname, $endname);
    foreach my $v (@$vals) {
	$count++;
	my $otherstuff;

	if ($wiz->qwparam('redoing_now')) {
	    $otherstuff .= "checked"
	      if ($wiz->qwparam($q->{'name'} . $v) eq $v);
	} else {
	    $otherstuff .= "checked" if ($defs->[$count]);
	}
	

	$otherstuff .= "checked" if ($defs->[$count]);
	if ($submit) {
	    $otherstuff .= " onclick=\"this.form.submit()";
	}
	if ($refresh_on_change) {
	    $otherstuff .= " onclick=\"$redo_screen_js\"";
	}
	my $l = QWizard::Generator::remove_accelerator(($labels->{$v}) ? $labels->{$v} : "$v");
	print "<tr><td>" . escapeHTML($l)  . "</td>\n";
	print "<td><input" . 
	  $self->do_css('qwmulticheckbox',$q->{'name'}) . 
	    " $otherstuff value=\"" . 
	      escapeHTML($v) .
		"\" type=checkbox name=\"" .
		  escapeHTML("$q->{name}$v") . "\"></td></tr>";
	# XXX: hack:
	push @{$wiz->{'passvars'}},$q->{'name'} . $v;
	$startname = escapeHTML("$q->{name}$v") if ($count == 0);
	$endname = escapeHTML("$q->{name}$v") if ($count == $#$vals);
    }

    print "</table>";

    #Javascript for setting/unsetting/toggling buttons
    print "

<script language=\"JavaScript\">
    function $q->{name}_setall() {
      var doit = false;
      for (i=0; i<document.qwform.elements.length; i++) {
        if (document.qwform.elements[i].type == \"checkbox\") {
          if (document.qwform.elements[i].name == \"$startname\") {
            doit = true;
          }
          if (doit) {
            document.qwform.elements[i].checked = true;
          }
          if (document.qwform.elements[i].name == \"$endname\") {
            doit = false;
          }
        }
      }
    }

    function $q->{name}_unsetall() {
      var doit = false;
      for (i=0; i<document.qwform.elements.length; i++) {
        if (document.qwform.elements[i].type == \"checkbox\") {
          if (document.qwform.elements[i].name == \"$startname\") {
            doit = true;
          }
          if (doit) {
            document.qwform.elements[i].checked = false;
          }
          if (document.qwform.elements[i].name == \"$endname\") {
            doit = false;
          }
        }
      }
    }

    function $q->{name}_toggleall() {
      var doit = false;
      for (i=0; i<document.qwform.elements.length; i++) {
        if (document.qwform.elements[i].type == \"checkbox\") {
          if (document.qwform.elements[i].name == \"$startname\") {
            doit = true;
          }
          if (doit) {
            if (document.qwform.elements[i].checked) {
              document.qwform.elements[i].checked = false;
            } else {
              document.qwform.elements[i].checked = true;
            }
          }
          if (document.qwform.elements[i].name == \"$endname\") {
            doit = false;
          }
        }
      }
    }
	    ";
#     foreach my $boxname (@boxnames) {
# 	print " document.qwform.try1.checked=true;\n";
# #	print " document.qwform.\"$boxname\".checked=true;\n";
#     }
    print "
</script>

<a href=\"javascript:$q->{name}_setall()\">[Set All]</a>
<a href=\"javascript:$q->{name}_unsetall()\">[Unset All]</a>
<a href=\"javascript:$q->{name}_toggleall()\">[Toggle All]</a>

";

}

sub do_radio {
    my ($self, $q, $wiz, $p, $vals, $labels, $def,
	$submit, $refresh_on_change, $name, $icons, $iconwidth) = @_;
    my $stuff;
    $stuff = " onclick=\"this.form.submit()\" " if ($submit);
    $stuff = " onclick=\"$redo_screen_js\" " if ($refresh_on_change);

    # remove the key accelerators
    my %passlabs = %$labels;
    # remove key bindings specifiers
    map {
	$passlabs{$_} = QWizard::Generator::remove_accelerator($passlabs{$_});
    } keys(%passlabs);

    # correct the ordering
    my @passvals = reverse @$vals;

    foreach my $value (@passvals) {
	print "  <input type=\"radio\" name=\"$name\" value=\"" .
	  escapeHTML($value) . "\" $stuff " .
	    $self->do_css('qwradio',$q->{'name'}) . " />\n    " .
	      (($icons->{$value}) ?
	       $self->get_image($icons->{$value}, 'qwradioimg', $q->{'name'}) :
	       (($iconwidth) ? "<span style=\"width: ${iconwidth};\" />" : "")).
		 $passlabs{$value} .
		   "<br />\n";
    }
}


sub do_label {
    my ($self, $q, $wiz, $p, $vals, $def) = @_;
    if (defined ($vals)) {
	my @labs = @$vals;  # copy this so map doesn't modify the source
	map { $_ = escapeHTML($_) } @labs;
	print "<span" . $self->do_css('qwlabel',$q->{'name'}) . ">" .
	  join("<br>", @labs) . "</span>\n";
    }
}

sub do_link {
    my ($self, $q, $wiz, $p, $text, $url) = @_;
    print $self->{'cgi'}->a({href => $url,
			     id => $q->{'name'},
			     class => 'qwlink' . $q->{'name'}}, $text);
}

sub do_paragraph {
    my ($self, $q, $wiz, $p, $vals, $preformatted) = @_;
    my @labs = @$vals;  # copy this so map doesn't modify the source
    map { $_ = escapeHTML($_) } @labs;
    if ($preformatted) {
	print "<pre" . $self->do_css('qwparagraph',$q->{'name'}) . ">\n",
	  @labs,"</pre>\n";
    } else {
	print "<span" . $self->do_css('qwparagraph',$q->{'name'}) . ">" .
	  join("<br><br>", @labs) . "</span>\n";
    }
}

sub do_menu {
    my ($self, $q, $wiz, $p, $vals, $labels, $def,
	$submit, $refresh_on_change, $name) = @_;
    my @stuff;
    push @stuff, -onchange, "this.form.submit()" if ($submit);
    push @stuff, -onchange, "$redo_screen_js" if ($refresh_on_change);

    print $self->{'cgi'}->popup_menu(-name => $name,
				     -id => 'qwmenu' . $name,
				     -class => 'qwmenu',
				     -values => $vals,
				     -override => 1,
				     -labels => $labels,
				     -default => $def,
				     @stuff);
}

sub do_fileupload {
    my ($self, $q, $wiz, $p, $vals, $labels, $def) = @_;

    push @{$wiz->{'passvars'}}, $q->{'name'} . "_qwf";
    print $self->{'cgi'}->filefield(-name => $q->{name},
				    -id => 'qwmenu' . $q->{'name'},
				    -class => 'qwmenu',
				    -override => 1,
				    -default => $def);
}

sub qw_upload_file {
    my ($self) = shift;
    my ($it);
    my $ret;
    if (ref($self) =~ /QWizard/) {
	$it = shift;
    } else {
	$it = $self;
    }
    if (!exists($self->{'cgi'})) {
	$self->{'cgi'} = new CGI;
    }

    my $fn;
    if (!$self->qwparam($it . "_qwf")) {
	# copy the file to a local qwizard copy of it

	# XXX: check error if undef; puts it in $self->{'cgi'}->cgi_error
	my $fh = $self->{'cgi'}->upload($it);
	$fn = $self->create_temp_file('.tmp', $fh);
	$fn =~ s/(.*)\///;
	$fn =~ s/$self->{'tmpdir'}\/+//;
	$fn =~ s/\.tmp$//;
	$self->qwparam($it . "_qwf", $fn);
    } else {
	$fn = $self->qwparam($it . "_qwf");
	$fn =~ s/[^a-zA-Z0-9]//;
    }

    $fn = $fn . ".tmp";
    $fn = $self->{'tmpdir'} . "/" . $fn;
    return $fn;
}

sub qw_upload_fh {
    my ($self) = shift;
    my ($it);
    my $ret;
    if (ref($self) =~ /QWizard/) {
	$it = shift;
    } else {
	$it = $self;
    }
    if (!exists($self->{'cgi'})) {
	$self->{'cgi'} = new CGI;
    }

    my $fn;
    if (!$self->qwparam($it . "_qwf")) {
	# copy the file to a local qwizard copy of it

	# XXX: check error if undef; puts it in $self->{'cgi'}->cgi_error
	my $fh = $self->{'cgi'}->upload($it);
	print STDERR "*" x 20 . ref($fh) . "++\n";
	$fn = $self->create_temp_file('.tmp', $fh);
	$fn =~ s/(.*)\///;
	$fn =~ s/$self->{'tmpdir'}\/+//;
	$fn =~ s/\.tmp$//;
	$self->qwparam($it . "_qwf", $fn);
	print STDERR "*" x 20 . " -> $it -> $fn -> " . ref($fh) . "++\n";
    } else {
	$fn = $self->qwparam($it . "_qwf");
	$fn =~ s/[^a-zA-Z0-9]//;
	print STDERR "*" x 80 . $fn,"\n";
    }

    $fn = $fn . ".tmp";
    $fn = $self->{'tmpdir'} . "/" . $fn;

    my $retfh = new IO::File;
    $retfh->open("<$fn");

    return $retfh;
}

sub do_entry {
    my ($self, $q, $wiz, $p, $name, $def, $hide, $size, $maxsize,
	$submit, $refresh_on_change) = @_;
    my $otherinfo;
    if ($size) {
	$otherinfo .= " size=\"$size\"";
    } else {
	if ($maxsize) {
	    $otherinfo .= " size=\"$maxsize\"";
	}
    }
    if ($maxsize) {
	$otherinfo .= " maxlength=\"$maxsize\"";
    }
    if ($def ne '') {
	$otherinfo .= " value=\"" . escapeHTML($def) . "\"";
    }
    if ($submit) {
	$otherinfo .= " onchange=\"this.form.submit()\"";
    }
    if ($refresh_on_change) {
	$otherinfo .= " onclick=\"$redo_screen_js\"";
    }

    #
    # If the hide flag was set, we'll treat this as unprintable text.
    #
    if ($hide) {
	$otherinfo .= " type=\"password\"";
    }

    print "<input" . $self->do_css('qwtext',$q->{'name'}) . 
      " name=\"$name\" $otherinfo>";
}

sub do_textbox {
    my ($self, $q, $wiz, $p, $def, $width, $size, $height, $submit, $refresh_on_change) = @_;
    my $otherinfo;
    if ($size || $width) {
	$size = $size || $width;
	$otherinfo .= " cols=\"$size\"";
    }
    if ($height) {
	$otherinfo .= " rows=\"" . $height . "\"";
    }
    if ($submit) {
	$otherinfo .= " onchange=\"this.form.submit()\"";
    }
    if ($refresh_on_change) {
	$otherinfo .= " onclick=\"$redo_screen_js\"";
    }
    print "<textarea" . $self->do_css('qwtextbox',$q->{'name'}) . 
      " name=\"$q->{name}\" $otherinfo>" . escapeHTML($def) . "</textarea>";
}

sub do_error {
    my ($self, $q, $wiz, $p, $err) = @_;
    my $name = ($q ? $q->{'name'} : '');
    print "<tr" . $self->do_css('qwerrorrow',$name) . "><td" .
      $self->do_css('qwerrorcol',$name) .
	" colspan=3><font color=red>" . escapeHTML($err) .
	  "</font></td></tr>\n";
}

sub do_separator {
    my ($self, $q, $wiz, $p, $text) = @_;
    if ($text eq "") {
	$text = "&nbsp";
    } else {
	$text = escapeHTML($text);
    }
    my $name = (ref($q) eq 'HASH') ? $q->{'name'} : "";
    print "  <tr" . $self->do_css('qwseparatorrow',$name) . 
      "><td" . $self->do_css('qwseparatorcol',$name) . 
	" colspan=3>$text</td></tr>";
}

sub do_hidden {
    my ($self, $wiz, $name, $val) = @_;
    print "<input type=hidden name=\"$name\" value=\"" . 
      escapeHTML($val) . "\">\n";
    $self->qwparam($name,$val);
}

sub do_unknown {
    my ($self, $q, $wiz, $p) = @_;

    print "<font color=\"red\">Error: Unhandled question type '$q->{type}' in primary '$p->{module_name}'.  It is highly likely that this page will not function properly after this point.</font>\n";
}

##################################################
# Display
##################################################

sub do_table {
    my ($self, $q, $wiz, $p, $table, $headers) = @_;
    my $color = $self->{'tablebgcolor'} || $self->{'bgcolor'};
    print "<table" . $self->do_css('qwtable',$q->{'name'}) .
      (!exists($self->{'nocss'}) ? "" : "bgcolor=$color border=1>") . 
       "\n";

    if ($headers) {
	print " <tr " . $self->do_css('qwtableheaderrow',$q->{'name'}) .
	  "bgcolor=\"$self->{headerbgcolor}\">\n";
	foreach my $column (@$headers) {
	    print "<th" . $self->do_css('qwtableheader',$q->{'name'}) .
	      ">" . ($column || "&nbsp;") . "</th> ";
	}
	print " </tr>\n";
    }

    $self->do_a_table($table, 1, $wiz, $q, $p);
    print "</table>\n";
}

sub do_a_table {
    my ($self, $table, $started, $wiz, $q, $p, $name) = @_;
    $name = $q->{'name'} if (!$name);
    print "<table" . $self->do_css('qwsubtable',$name) . ">"
      if (!$started);
    foreach my $row (@$table) {
	print " <tr" . $self->do_css('qwtablerow',$name) . ">\n";
	foreach my $column (@$row) {
	    print "<td>";
	    if (ref($column) eq "ARRAY") {
	        $self->do_a_table($column, 0, $wiz, $q, $p);
	    } elsif (ref($column) eq "HASH") {
		print "<table" . $self->do_css('qwtablewidget',$name) .
		  ">\n";
		my $param = $wiz->ask_question($p, $column);
		push @{$wiz->{'passvars'}}, $param;
		print "</table>\n";
	    } else {
		my $val = $self->make_displayable($column);
		print (defined($val) && $val ne "" ? $val : "&nbsp;");
	    }
	    print "</td>";
	}
	print " </tr>\n";
    }
    print "</table>\n" if (!$started);
}

sub do_graph {
    my $self = shift;
    my ($q, $wiz, $p, $data, $gopts) = @_;

    if ($have_gd_graph) {
	my $file = $self->create_temp_file('.png', $self->do_graph_data(@_));
	$file =~ s/(.*)\///;
	
	# XXX: net-policy specific hack!
	print "<img" . $self->do_css('qwgraph',$q->{'name'}) .
	  " src=\"" . $self->{'imgpath'} . escapeHTML($file) . "\">\n";
    } else {
	print "graphs not supported without additional software\n";
    }
}

########################################################################
#
sub do_image {
	my $self = shift;
	my ($q, $wiz, $p, $imgdata, $imgfile, $alt, $height, $width) = @_;
	my $image;
	
	if ($imgdata) {
	    # store the image in a temporary file
	    $image = $self->create_temp_file('.png', $imgdata);
	    $image =~ s/(.*)\///;
	} else {
	    $image = $imgfile;
	}
	my $imagesrc = "src=\"" . $self->{'imgpath'} . escapeHTML($image) ."\"";

	#
	# If an alt tag was specified, create the alt image message.
	#
	my $altmsg = "alt=\"Broken Image - $image\"";
	if($alt ne "")
	{
		$altmsg = "alt=\"$alt\"";
	}

	#
	# If a height tag was specified, add the image height.
	#
	my $hmsg   = " ";
	if($height ne "")
	{
		$hmsg = "height=\"$height\"";
	}

	#
	# If a width tag was specified, add the image width.
	#
	my $wmsg  = " ";
	if($width ne "")
	{
		$wmsg = "width=\"$width\"";
	}

	print "<img" . $self->do_css('qwimage',$q->{'name'}) .
	  " $imagesrc $altmsg $hmsg $wmsg border=1>\n";
}

sub do_filedownload {
    my ($self, $q, $wiz, $p, $name, $def, $data, $datafn, $extension,
	$linktext) = @_;

    # We simply always generate and save the file and make a link to it
    # XXX: this is not efficient and techinically should be generated on demand.

    my ($fh, $outputfile) = $self->create_temp_fh($extension || '.bin');
    $outputfile =~ s/.*\///;

    # print the passed in data
    print $fh $data if ($data);

    # if we have code to use for directly printing data, call it
    if ($datafn && ref($datafn) eq 'CODE') {
	# passed a generator function; call it
	$datafn->($fh, undef, $wiz, $p, $q, $outputfile);
    }

    # close it out
    $fh->close();

    # print the resulting html out
    print "<a href=\"" . $self->{'datapath'} . escapeHTML($outputfile) ."\">"
      . escapeHTML($linktext) . "</a>";
}



##################################################
#
# Automatic updating for monitors.
#

sub do_autoupd
{
	my ($self, $secs) = @_;
	my $msecs = $secs * 1000;

	if($secs eq "")
	{
		return;
	}

# warn "\ndo_autoupd:  sleeping for $secs seconds\n";

	#
	# Javascript for automatically updating the screen.
	#
	print <<EOF;
	<script language="JavaScript">
	function autoupd_$secs() {
		document.qwform.submit();
	}

	setTimeout("autoupd_$secs()",$msecs);

	</script>
EOF

}

##################################################
# Trees
##################################################

#TODO: Support passing in a hash for tree data (instead of just a function)

sub do_tree {
    my ($self, $q, $wiz, $p, $labels, $expand_all, $def) = @_;

    my $treename = $q->{'name'} || 'tree';

    my $expanded = $self->qwparam("${treename}_expanded") || $q->{'root'};
    my @expand = split(/,/, $expanded);
    # redo_screen values:
    #  1: selects a label
    #  2: expands a branch
    #  3: collapses a branch
    my $redo = $self->qwparam("redoing_now");

    if ($redo == 2 && $self->qwparam("${treename}_collapse")) {
	push @expand, $self->qwparam("${treename}_collapse");
    } elsif ($redo == 3 && $self->qwparam("${treename}_collapse")) {
	@expand = grep(!($_ eq $self->qwparam("${treename}_collapse")),@expand);
    }


    my $selected = $self->qwparam($treename);
    if ($selected) {
	#if the selected node is hidden inside a collapsed branch, select the
	#closest visible node. Although it changes the selected node, this seems
	#better than the possibly-confusing situation of the selected node being
	#hidden beneath an unexpanded node.
	my $cur = $selected;
	until ($cur eq $q->{'root'}) {
	    $cur = get_name($q->{'parent'}->($wiz, $cur) || return);
	    my @tmp = grep($_ eq $cur, @expand);
	    unless ($#tmp > -1) {
		$selected = $cur;
	    }
	}
    } else { #ensure that the default is initially visible
	$selected = $def || $q->{'root'} || return;
	my $cur = $selected;
	until ($cur eq $q->{'root'}) {
	    $cur = get_name($q->{'parent'}->($wiz, $cur) || return);
	    push @expand, $cur;
	}
    }

    $expanded = join(',', @expand);
    $self->do_hidden($wiz, "${treename}_expanded", $expanded);
    if ($self->{'first_tree'}) { #only one hidden value for redo_screen
	$self->{'first_tree'} = 0;
    }
    $self->do_hidden($wiz, $treename, $selected);

    #holds the name of a node that needs to be collapsed or expanded
    $self->do_hidden($wiz, "${treename}_collapse", ''); 

    #Javascript for expanding/collapsing/selecting
    print <<EOF;
<script language="JavaScript">
    function ${treename}_select(item, oper) {
	if (oper == 1) {
	    document.qwform.${treename}.value=item;
	} else {
	    document.qwform.${treename}_collapse.value=item;
	}
	document.qwform.redo_screen.value=oper;
	document.qwform.submit();
    }
</script>
EOF

    print "<div " . $self->do_css('qwtree',$treename) . ">\n";
    $self->print_branch($wiz, $q, $q->{'root'}, $selected, 0, $labels,
			\@expand, $expand_all);
    print "</div>\n";
}

sub get_name {
    my $node = shift;

    if (ref($node) eq 'HASH') {
	return $node->{'name'};
    } else {
	return $node;
    }
}

#recursively print out the tree
sub print_branch {
    # XXX: css this
    my ($self, $wiz, $q, $cur, $selected, $nest, $labels,
	$expand, $expand_all) = @_;

    print "<br>" if $nest;
    for my $i (1 .. (5 * $nest)) { print "&nbsp;"; }

    my $children = $q->{'children'}->($wiz, get_name($cur));
    if ($#$children > -1) {
	my @ans = grep($_ eq get_name($cur), @$expand); 
	if ($#ans > -1 || $expand_all > 0) { #is it expanded?
	    $self->make_link('minus', 3, $cur, $selected, $q, $labels);
	    foreach my $child (@$children) {
		$self->print_branch($wiz, $q, $child, $selected,
				    $nest + 1, $labels, $expand, $expand_all-1);
	    }
	} else {
	    $self->make_link('plus', 2, $cur, $selected, $q, $labels);
	}
    } else {
	$self->make_link('blank', 0, $cur, $selected, $q, $labels);
    }
}

# prints a single node, and any required links, etc
sub make_link {
    # XXX: css this
    my ($self, $imgtype, $oper, $cur, $selected, $q, $labels) = @_;
    my $name = get_name($cur);
    my $treename = $q->{'name'} || 'tree';
    print "<a href=\"javascript:${treename}_select('$name', $oper)\">" if $oper;
    print "<img src=\"$self->{'imgpath'}tree_$imgtype.png\" border=0>";
    print "</a>" if $oper;
    print "&nbsp;";
    my $label;
    if (ref($cur) eq 'HASH') {
	$label = $cur->{'label'};
    }
    $label = $label || $labels->{$name} || $name;
    if ($name eq $selected && $q->{'name'}) { 
	print "<b>$label</b>";
    } else {
	print "<a href=\"javascript:${treename}_select('$name', 1);\">" if $q->{'name'};
	print $label;
	print "</a>" if $q->{'name'};
	print "\n";
    }
}



##################################################
# action confirm
##################################################

sub start_confirm {
    my ($self, $wiz) = @_;

    print "<h1 class=\"qwconfirmtitle\">Wrapping up.</h1>\n";
    print $self->{'cgi'}->start_form(),"\n";
    print "<ul class=\"qwconfirmtop\">\n" .
      "  <p>Do you want to commit the following changes:\n";
    print "<ul class=\"qwconfirmwrap\">\n";
}

sub end_confirm {
    my ($self, $wiz) = @_;
    print "</ul></ul>\n";
    # XXX: css these.  id or class?
    print "<input type=submit name=wiz_confirmed value=\"" .
      ($wiz->qwparam('QWizard_commit') || "Commit") . "\">\n";
    print "<input type=submit name=wiz_canceled value=\"Cancel\">\n";
    print $self->{'cgi'}->end_form();
    $self->{'started'} = $wiz->{'started'} = 0;
}

sub do_confirm_message {
    my ($self, $wiz, $msg) = @_;
    print "<li class=\"confirmmsg\">" . $self->{'cgi'}->escapeHTML($msg) . "\n";
}

sub canceled_confirm {
    my ($self, $wiz) = @_;
    print $self->{'cgi'}->h1("canceled");
    print "<a href=\"$wiz->{top_location}\">Return to Top</a>\n";
    $self->{'started'} = $wiz->{'started'} = 0;
}

##################################################
# actions
##################################################

sub start_actions {
    my ($self, $wiz) = @_;
    print $self->{'cgi'}->h1('Processing your request...');
    print "<div class=\"qwactions\">\n";
    # XXX: css pre or remove and style qwactions
    print "<pre>\n";
}

sub end_actions {
    my ($self, $wiz) = @_;
    print "</pre>\n";
    print "</div>\n";
    print $self->{'cgi'}->h2('Done!');
    print "<a href=\"$wiz->{top_location}\">" .
      ($wiz->qwparam('QWizard_finish') || "Return to Top") .
	"</a>\n";
    $self->{'started'} = $wiz->{'started'} = 0;
}

sub do_action_output {
    my ($self, $wiz, $action) = @_;
    print "<div class=\"qwaction\">" . escapeHTML($action) . "</div>\n";
}

sub do_action_error {
    my ($self, $wiz, $errstr) = @_;
    print "<font color=red size=+1><div class=\"qwactionerror\">ERROR: <b>" . escapeHTML($errstr) .
      "</b></div></font>\n";
}

sub make_displayable {
    my ($self, $str);
    if ($#_ > 0) {
	($self, $str) = @_;
    } else {
	($str) = @_;
    }

    my $transit = 0;

    #
    # If we have a broken isprint(), do the check ourselves.  Otherwise,
    # use the builtin.
    #
    if($use_np_isprint == 1) {
	$transit = ($str =~ /[^\w\s!\@\#\$\%\^\&\*\(\)\.]/);
    }
    else {
	$transit = (!isprint($str));
    }

    #
    # If translation is required, convert the string to its hex equivalent.
    #
    if(length($str) != 0 && $transit == 1) {
        $str = "0x" . (unpack("H*", $str))[0];
    }

    # properly escape any html
    if (!$self || !exists($self->{'noescapehtml'})) {
	$str = escapeHTML($str);
    }

    return $str;
}

sub maybe_escapeHTML {
    my ($self, $text, $noescapeit) = @_;
    return $text if ($self->{'noescape'} || $noescapeit);
    return escapeHTML($text);
}


1;
