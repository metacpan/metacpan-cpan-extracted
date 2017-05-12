package PApp::Hinduism::Default;

use Data::Dumper;
use DBIx::Recordset;
use PApp::SQL;

sub create_temp {
    my ($app, $table) = @_;
    my $temp_table  = "temp_${table}$$";

    my $sql = "create table $temp_table as select * from $table";
    warn $sql;
    sql_exec $sql;

#    $sql = "drop table $table";
#    warn $sql;
#    sql_exec $sql;
}
    

sub select_nextval {
    my ($ah, $sequence_name) = @_;
    sql_fetch \my($number), "select nextval('$sequence_name')";
    $number;
}

sub insert_dept {
   my ($app, $department, $url, $school_id) = @_;
   
   my $nextval = $app->select_nextval('dept___id');

   sql_exec "INSERT into dept VALUES ($nextval, '$department', '$url', $school_id)";
}

sub select_publisher_id {
    my ($ah, $publisher) = @_;
    sql_fetch \my($value), "select id from publisher where name = '$publisher'";
    $value;
}

sub insert_publisher {
    my ($ah, $publisher) = @_;
    my $publisher_id = $ah->select_nextval('publisher___id');
    sql_exec "INSERT into PUBLISHER VALUES ($publisher_id, '$publisher')";
}

sub select_school_id_from_school_course_number {
   my ($ah, $school_course_number) = @_;
   sql_fetch "SELECT id from course where school_course_number = '$school_course_number'";
}

sub insert_course_reader {
    my ($ah, $school_course_number) = @_;
    my $crid = $ah->select_nextval('course_reader___id');
    my $sid  = $ah->select_school_id_from_school_course_number($school_course_number);
    my $sql = "INSERT into course_reader VALUES ($crid, $sid)";
    warn $sql;
    sql_exec $sql;
    my $mtid = $ah->select_id_from_name('course_reader', 'material_type');
    $ah->insert_course_material($sid, $mtid, $crid);
}

sub insert_course_material {
    my ($ah, $course_id, $material_type_id, $material_id) = @_;
    $material_id = "'$material_id'" unless $material_id =~ /\d+/;
    sql_exec "INSERT into course_material VALUES ($course_id, $material_type_id, $material_id)";
}

sub insert_course {
    my ($ah, $seq_id, $course_name, $url, $school_id, $description, $course_number) = @_;
    my $sql = "INSERT INTO course VALUES ($seq_id, '$course_name', '$url', $school_id, '$description', '$course_number')";
    warn $sql;
    sql_exec $sql;
}

sub insert_book {
    my ($ah, $book, $publisher, $last_name, $first_name, $middle_name, $pub_year) = @_;
    my $seq_id = $ah->select_nextval('book___id');
    my $pub_id = $ah->select_publisher_id($publisher);
    my $aut_type = $ah->select_id_for_person_type('author');
    my $aut_id = $ah->select_person($aut_type, $last_name, $first_name, $middle_name);

  DBIx::Recordset->Insert({
      '!DataSource' => $PApp::SQL::DBH,
      '!Table'      => 'book',
      id => $seq_id,
      name => $book,
      publisher_id => $pub_id,
      author_id => $aut_id,
      pub_year => $pub_year
      });


}

sub insert_book_in_course_material_via_book_id_and_course_id {
    my ($ah, $book_id, $course_id) = @_; 

    my $mtid = $ah->select_id_from_name('book', 'material_type');
    $ah->insert_course_material($course_id,  $mtid, $book_id);
}

sub insert_material_type {
    my ($ah, $material_type) = @_;
    my $seq_id = $ah->next_in_sequence('material_type___id');
    sql_exec "INSERT into material_type VALUES ($seq_id,'$material_type')";
}

sub insert_school {
    my ($ah, $school) = @_;
    my $seq_id = $ah->select_nextval('school___id');
    sql_exec "INSERT into SCHOOL VALUES ($seq_id,'$school')";
}

sub pretty_print_course_reader {
    print "Course Reader\n";
}

sub pretty_print_book {
    my ($app, $book_id) = @_;
    my ($id, $name, $publisher_id, $author_id, $pub_year) =
	sql_fetch "SELECT * FROM book where id = $book_id";

    my $OUT = "<I>$name</I>";

    if ($publisher_id) {
	my $p = $app->select_name_from_id($publisher_id, 'publisher');
	$OUT .= " ($p : $pub_year)\n";
    }

    if ($author_id) {
	$OUT .= $app->print_person($author_id) . "\n";
    }

    print "$OUT\n";
}

sub pretty_print_course_material {
    my ($app, $cmat) = @_;
    my $mtype = $app->select_name_from_id($cmat->[1],'material_type');
    my $method = "pretty_print_$mtype";
    $app->$method($cmat->[2]);
}

sub select_course_materials_via_course_id {
    my ($ah, $course_id) = @_;
    my $sql = "SELECT * FROM course_material WHERE course_id = $course_id";
    sql_fetchall $sql;
}

sub print_person {
    my ($app, $person_id) = @_;

    $sql = "SELECT first_name, middle_name, last_name FROM person WHERE id = $person_id";
    sql_fetch \my ($first_name, $middle_name, $last_name), $sql;
    "$first_name $middlename $last_name";
}

sub select_course_lecturer_via_course_id {
    my ($ah, $course_id) = @_;
    my $sql = "SELECT lecturer_id FROM course_lecturer WHERE course_id = $course_id";
#    warn $sql;
    sql_fetch \my($lecturer_id), $sql;

    return "No lecturer listed" unless $lecturer_id;

    $ah->print_person($lecturer_id);

}


sub insert_course_lecturer {
    my ($ah, $course_id, $lecturer_id) = @_;
    my $sql = "INSERT into course_lecturer VALUES ($course_id, $lecturer_id)";
    warn $sql;
    sql_exec $sql;
}

sub insert_person {
    my ($ah, $person_type, $last_name, $first_name, $middle_name) = @_;
    my $seq = $ah->select_nextval('person___id');
    my $person_type_id = $ah->select_id_for_person_type($person_type);
    sql_exec "INSERT into person VALUES ($seq, $person_type_id, '$last_name', '$first_name', '$middle_name')";
}

sub select_unique_dept_id_from_course {
    sql_fetchall "select distinct dept_id from course order by dept_id DESC";
}

sub select_dept_url_via_dept_id {
    my ($app, $dept_id) = @_;
    sql_fetch \my ($dept_id), "SELECT url from dept where id = $dept_id";
}

sub select_school_id_via_dept_id {
    my ($app, $dept_id) = @_;
    sql_fetch \my ($school_id), "SELECT school_id from dept where id = $dept_id";
}

sub select_school_id_via_school_name {
    my ($app, $name) = @_;
    sql_fetch \my ($school_name), "SELECT id from school where name = '$name'";
}

sub find_school_name_from_dept_id {
    my ($app, $dept_id) = @_;
    sql_fetch \my ($school_id), "SELECT school_id from dept where id = $dept_id";
    $app->select_name_from_id($school_id, 'school');
}

sub select_course_name_via_school_id {
# NO LONGER VALID
    my ($ah, $school_id) = @_;
    sql_fetchall "select name from course where school_id = $school_id";
}

sub select_course_rows_via_dept_id {
    my ($ah, $dept_id) = @_;
    sql_fetchall "select * from course where dept_id = $dept_id order by id";
}
    

sub select_id_from_school_course_number {
    my ($ah, $key) = @_;
    sql_fetch \my($value), "select id from course WHERE school_course_number = '$key'";
    $value;
}

sub select_id_for_person_type {
    my ($ah, $person_type) = @_;
    sql_fetch \my($id), "select id from person_type WHERE name = '$person_type'";
    $id;
}

sub select_id_from_name {
    my ($ah, $name, $table) = @_;
    my $sql = "select id from $table WHERE name = '$name'";
    warn $sql;
    sql_fetch \my($id), $sql;
    $id;
}

sub select_name_from_id {
    my ($ah, $id, $table) = @_;
    my $sql = "select name from $table WHERE id = $id";
   # warn $sql;
    sql_fetch $sql;

}

sub select_this_from_that {
    my ($ah,$this, $that) = @_;
    my $sql = "select $this from $that";
    warn $sql;
    sql_fetchall $sql;
}


sub select_person_type {
    my ($ah, $person_type) = @_;
    sql_fetch \my($id), "select id from person_type WHERE name = '$person_type'";
    $id;
}


sub select_person {
    my ($ah, $person_type, $last_name, $first_name, $middle_name) = @_;
    
    my $sql = "select id from person WHERE person_type_id = $person_type and last_name = '$last_name' and first_name = '$first_name'";
    $sql .=  "and middle_name = '$middle_name'" if $middle_name;

    warn $sql;
    sql_fetch \my($id), $sql;
    $id;
}
  

1;
