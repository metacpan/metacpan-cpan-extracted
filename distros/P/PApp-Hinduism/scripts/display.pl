#!/Users/metaperl/install/perl/bin/perl

# HYPERLINK DEPT

use lib '/Users/metaperl/src/papp_hinduism/lib';

use Data::Dumper;
use DBIx::AnyDBD;
use DBIx::Connect;
use PApp::SQL;
use Text::Template;

my @data = DBIx::Connect->data_array('basic');
my $app  = DBIx::AnyDBD->connect(@data, 'PApp::Hinduism');
$PApp::SQL::DBH = $app->get_dbh;



my $tab = "\t";

print '<html>
<head>
<!-- #BeginEditable "pagetitle" --><title>Course Scan</title><!-- #EndEditable -->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">

<link rel="stylesheet" href="/main.css" type="text/css">


</head>
<body bgcolor="#FF6633" text="#000000" leftmargin="0" topmargin="0">
';

my @dept_id = $app->select_unique_dept_id_from_course;
for our $dept_id (@dept_id) {

    warn "DEPT_ID: $dept_id";

    my $school_name = $app->find_school_name_from_dept_id($dept_id);
    my $dept_name = $app->select_name_from_id($dept_id, 'dept');
    my $dept_url = $app->select_dept_url_via_dept_id($dept_id);
    my $hotlink = "
<a href=$dept_url>$dept_name</a>";
    print "<h2>$school_name ($hotlink)</h2>\n";

    my $school_id = $app->select_school_id_via_dept_id($dept_id);
#    warn $school_id;
    our @course_row = $app->select_course_rows_via_dept_id($dept_id);
    for my $course_row (@course_row) {
	print " <h3> 
<a href=$course_row->[2]>
$course_row->[1] ($course_row->[4])
</a>
 </h3>\n";
	print "<P>Lecturer: ", $app->select_course_lecturer_via_course_id($course_row->[0]), $/;
	print "<P>", $course_row->[5];
	my @course_material = $app->select_course_materials_via_course_id($course_row->[0]);
	if (@course_material) {
	    print "<P><P><B><I>Course Materials</B></I>";
	} else {
	    print "<P>No course materials listed";
	}
	for my $course_material (@course_material) {
	    print "<P>\n";
	    $app->pretty_print_course_material($course_material);
	    print "</p>\n";
	}
    }
    
#    warn $template->fill_in;

}

print "</body></html>";
