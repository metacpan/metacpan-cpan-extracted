use lib '/Users/metaperl/src/papp_hinduism/lib';

use Data::Dumper;
use DBIx::AnyDBD;
use DBIx::Connect;
use PApp::SQL;


my @data = DBIx::Connect->data_array('basic');
my $app  = DBIx::AnyDBD->connect(@data, 'PApp::Hinduism');
$PApp::SQL::DBH = $app->get_dbh;

#$app->create_temp('course');

#    my $cid = 37;
#my $x  = $app->select_id_for_person_type('lecturer');
#my $cl = $app->select_person($x, 'Witzel', 'Michael');
#$app->insert_course_lecturer($cid, $cl);


$app->insert_dept('Religion', 'http://www.bu.edu/religion/main/religionhome.html',6);
#$app->insert_school_dept_course(

#$app->insert_book_in_course_material_via_book_id_and_course_id( 15  , 27);
#$app->insert_book("Patanjali's Yoga Sutras");

#$app->insert_publisher('University of California Press');

#Leonard W. J. van der Kuijp 

#$app->insert_person('lecturer', 'Korom', 'Frank');

#my $x = $app->next_in_sequence('course_reader___id');
#$app->insert_course_reader('RELS 104');


#$app->insert_school("Boston University");

#$app->insert_school("Harvard University");
#$app->insert_material_type('book');
#$app->insert_material_type('course_reader');
#$app->insert_publisher('Prentice-Hall');

=head1
{
    my $seq_id    = $app->select_nextval('course___id');
#    my $seq_id    = 28;
    my $school_id = $app->select_school_id_via_school_name('Boston University');
    $app->insert_course(
$seq_id,
'Hinduism',
'http://www.bu.edu/religion/courses/coursespage/courses-new.html', 
$school_id, 
'Introduction to the Hindu tradition. Ritual and philosophy of the Vedas and Upanishads, yoga in the Bhagavad Gita, gods and goddesses in Hindu mythology, "popular" aspects of village and temple ritual, and problems of modernization and communalism in postcolonial India.'
,
'RN 213');


#    my $mid  = 10;# "A Rapid Sanskrit Method" $app->select_id_from_name('Bhagavad Gita', 'book');
#    my $mtid = $app->select_id_from_name('book','material_type');
#    warn "$app->insert_course_material($seq_id, $mtid, $mid);";
#    $app->insert_course_material($seq_id, $mtid, $mid);
}

=cut


