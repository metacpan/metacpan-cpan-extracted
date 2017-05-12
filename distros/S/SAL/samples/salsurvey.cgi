#!/usr/bin/perl

# This script is licensed under the FDL (Free Documentation License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html

use strict;
use SAL::WebApplication;
my $app = new SAL::WebApplication;
my $q = $app->{cgi};
my $self_url = $app->{cgi}->script_name();
my $user_id = $app->{cgi}->remote_user();
my $user_name = lookup_name($user_id);

my $survey_question = '';
my $survey_server = 'localhost';
my $survey_user = '';
my $survey_pass = '';
my $survey_db = 'Survey';

my $canvas;

# Register our application's modes
if (! $app->register_default(\&start)) { $app->throw_error("Could not register default mode 'start'\n"); }
if (! $app->register_mode('cast', \&cast)) { $app->throw_error("Could not register mode 'cast'\n"); }
if (! $app->register_mode('help', \&help)) { $app->throw_error("Could not register mode 'help'\n"); }
if (! $app->register_toolbar(\&build_toolbar)) { $app->throw_error("Could not register toolbar\n"); }
if (! $app->register_html_header(\&build_html_header)) { $app->throw_error("Could not register html header\n"); }

# Setup any databases
my $dbo_data = $app->{dbo_factory}->spawn_mysql($survey_server, $survey_user, $survey_pass, $survey_db);
my $dbo_results = $app->{dbo_factory}->spawn_mysql($survey_server, $survey_user, $survey_pass, $survey_db);

# Run the application
$app->run();

#===========
# Callbacks
#===========

###############################################################
sub start {
	my $sid = $q->param('sid') || '0';
	my $is_ok_to_vote = 0;

	my ($w, $h, $rh, $rw);

	# Get the Question...
	($w, $h) = $dbo_data->execute(qq[SELECT Question FROM SurveyQuestions WHERE SID=?], $sid);
	$survey_question = $dbo_data->{data}->[0][0];

	# Find out if this user's already voted...
	($w, $h) = $dbo_data->execute(qq[SELECT * FROM SurveyData WHERE SID=? AND Name=?], $sid, $user_id);
	if ($h < 1) { $is_ok_to_vote = 1; }

	# Get the Survey Choices...
	($w, $h) = $dbo_data->execute(qq[SELECT * FROM SurveyChoices WHERE SID=? ORDER BY ChoiceNum], $sid);

	# Calculate results
	($rw, $rh) = $dbo_results->execute(qq[SELECT sum(if(SurveyData.Choice='0', 1, 0)) as a, sum(if(SurveyData.Choice='1', 1, 0)) as b, sum(if(SurveyData.Choice='2', 1, 0)) as c FROM SurveyData WHERE SID=?], $sid);

	my $total_votes = $dbo_results->{data}->[0][0] + $dbo_results->{data}->[0][1] + $dbo_results->{data}->[0][2];
	my @pctgs;
	if ($dbo_results->{data}->[0][0] > 0) {	$pctgs[0] = ($dbo_results->{data}->[0][0] / $total_votes) * 100; }
	if ($dbo_results->{data}->[0][1] > 0) {	$pctgs[1] = ($dbo_results->{data}->[0][1] / $total_votes) * 100; }
	if ($dbo_results->{data}->[0][2] > 0) {	$pctgs[2] = ($dbo_results->{data}->[0][2] / $total_votes) * 100; }
	$pctgs[0] = sprintf("%.2f", $pctgs[0]);
	$pctgs[1] = sprintf("%.2f", $pctgs[1]);
	$pctgs[2] = sprintf("%.2f", $pctgs[2]);

	my $canvas = qq[<h3 align=center>Survey Question:<br/>$survey_question</h3>];

	if ($is_ok_to_vote) {
		$canvas .= qq[<center><form action=$self_url method=POST><table border=0 width=300 cellpadding=2 cellspacing=0>];
		for (my $y = 0; $y < $h; $y++) {
			$canvas .= qq[<tr><td align=center><input type="radio" name="choice" value="$y"></td><td align=left>$dbo_data->{data}->[$y][1]</td></tr>];
		}
		$canvas .= qq[<tr><td><input type="hidden" name="mode" value="cast"><input type="hidden" name="sid" value="$sid"></td><td><input type="submit" value="Cast Vote"></td></tr></table></form></center>];
	} else {
######### User has already cast a vote, so display a message instead of displaying the form.
		$canvas .= qq[<p align=left> </p><p align=center>You have already voted in this survey.</p>];
	}

######### Display Results
	$canvas .= qq[
<p align=center> <br/>Survey Results ($total_votes Total Votes)</p>
<center>
<table width=600 border=0 cellpadding=0 cellspacing=0 style="border-right: 1px solid #000;">
];
	for (my $y = 0; $y < $h; $y++) {
		my $progress_width= $pctgs[$y] * 2;
		my $style;
		if ($y == 0) {
			$style = "border-top: 1px solid #000; border-bottom: 1px solid #000; border-left: 1px solid #000; background-color: #ddd;";
		} else {
			$style = "border-bottom: 1px solid #000; border-left: 1px solid #000; background-color: #ddd;";
		}

		$canvas .= qq[<tr><td align=left width=340>$dbo_data->{data}->[$y][1]</td><td align=right width=60>$pctgs[$y]% </td><td align=left width=200 style="$style"><img src="/images/progress.png" width=$progress_width height=24></td></tr>];
	}

	$canvas .= qq[
</table>
</center>
];

	$app->write($canvas);
	$app->paint("User Feedback Survey");
}
###############################################################
sub cast {
	my $sid = $q->param('sid') || '0';
	my $choice = $q->param('choice');

	$dbo_data->do(qq[INSERT INTO SurveyData (SID, Name, Choice)  VALUES('$sid', '$user_id', '$choice')]);

	my $canvas = qq[
<h3 align=left>Your vote has been cast!</h3>
<a href="$self_url?sid=$sid">Back to start</a>
];

	$app->write($canvas);
	$app->paint("User Feedback Survey");
}
###############################################################
sub help {
	my $pod_file = "/var/www$self_url";

        # define some html tags we want to substitute in
        my $hr_html = '';
        my $titlebg_html = '<h1 style="background-color: #ffd; font-family: times;">';
        my $section_title_html = '<h2 style="text-decoration: underline; font-family: times; page-break-before: always;">';
        my $index_section_html = '<h2 style="text-decoration: underline; font-family: times;">';
                                                                                                                             
        # get the html version of the pod
        my $pod_contents = `pod2html --infile=$pod_file --index`;
                                                                                                                             
        # make it nicer
        # remove extraneous simple tags
        my @bad_tags = qw(<html> </html> <head> </head> <body> </body>);
        foreach my $tag (@bad_tags) {
                $pod_contents =~ s/$tag//ig;
        }
                                                                                                                             
        # remove the title tags seperately, so we can take out the text between them
        $pod_contents =~ s/<title>.*<\/title>//ig;
                                                                                                                             
        # remove the link tag seperately so we can remove the text inside it
        $pod_contents =~ s/<link.*>//ig;
                                                                                                                             
        # substitute our settings in
        $pod_contents =~ s/<hr.*\/>/$hr_html/ig;
        $pod_contents =~ s/<h1>/$titlebg_html/ig;
        $pod_contents =~ s/<h2>/$section_title_html/ig;
                                                                                                                             
        # remove any multi-newlines
        $pod_contents =~ s/\n+/\n/g;

	$app->write($index_section_html . "Index</h2>" . $pod_contents);
	$app->paint("Help Files...");
}
###############################################################
sub build_toolbar {
	my $mode = $app->{cgi}->param('mode');

	my $toolbar;
	if ($mode ne 'help') {
		$toolbar =  qq[
<a href="$self_url?mode=help" style="background-color: #fff;"><img src="/icons/unknown.gif" alt="Help" border=0></a>  
];
	} else {
		$toolbar .= qq[
<a href="$self_url" style="background-color: #fff;"><img src="/images/extra_icons/list.gif" alt="Back to Survey" border=0></a>  
];
	}

	return $toolbar
}
###############################################################
sub build_html_header {
	my $html_header = qq[
<script language="javascript">
function isReady(form) {
	for (var e = 0; e < form.elements.length; e++) {
		var el = form.elements[e];
		if (el.name.toLowerCase().substring(0,3) == "opt") {
			return true;
		} else {
			if (el.type == 'text' || el.type == 'textarea' || el.type == 'password' || el.type == 'file' ) {
				if (el.value == '') {
					alert('Please fill out the text field ' + el.name.toUpperCase());
					el.focus();
					return false;
				}
			}
			if (el.type == 'checkbox') {
				if (! el.checked) {
					alert('Please fill in Required Checkbox ' + el.name.toUpperCase());
					el.focus();
					return false;
				}
			}
		}
	}
}
</script>
];

	return $html_header
}
###############################################################


#===============
# Support Funcs
#===============

sub lookup_name {
	my $id = shift;
	my @record = split(/:/, `getent passwd | grep ^$id`);
	return $record[4];
}

sub sql_build_value_list {
	my @items = @_;
	my @clean = sql_clean(@items);
	my $value_list;

	foreach my $item (@clean) {
		$value_list .= qq['$item', ];
	}

	$value_list =~ s/,\s$//;
	return $value_list;
}

sub sql_clean {
	my @items = @_;
	my @clean;

	foreach my $item (@items) {
		$item =~ s/'//g;
		$item =~ s/"//g;
		$item =~ s/;//g;
		push (@clean, $item);
	}
	return @clean;
}

sub get_datetime {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	$mon++;
	$year += 1900;

	my $datetime = qq[$year-$mon-$mday $hour:$min:$sec];

	return $datetime;
}

=pod

=head1 SAL Surveys

=head2 Requirements

=item Apache
 - Basic Auth authentication (mod_auth_mysql, mod_auth_external, etc)

=item SAL

=item MySQL Database "Surveys"

   Tables:
 - SurveyQuestions (SID int(11), Question varchar(255))
 - SurveyChoices (SID int(11), Choice varchar(255), ChoiceNum int(11))
 - SurveyData (SID int(11), Name varchar(16), Choice int(11))

=item Images

 - progress.png (a 1px wide image for the progress bar)
 - unknown.gif for toolbar-link to help (image can be found in apache icon directory)
 - list.gif for toolbar-link to back to the survey from help (or alternate from apache icon directory)

=cut
