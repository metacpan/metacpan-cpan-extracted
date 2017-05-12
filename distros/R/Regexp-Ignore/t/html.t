# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

BEGIN { 
    $| = 1; 
    $GENERATE_TEST_FILES = $ENV{GENERATE_TEST_FILES};
    @test_files = ("test1.html", "test2.html", "test3.html");
    $number_of_tests_per_file = $GENERATE_TEST_FILES ? 0 : 8;
    my $number_of_tests = 
	$number_of_tests_per_file * scalar(@test_files) * 2 + 1;
    print "1..$number_of_tests\n"; 
}

END {print "not ok 1\n" unless $loaded;}

use Regexp::IgnoreHTML;
$loaded = 1;
print "ok 1\n";

chdir("t");

for (my $k = 0; $k <= 1; $k++) {
    for (my $i = 0; $i < scalar(@test_files); $i++) {
	my $j = ($i + $k * scalar(@test_files)) * $number_of_tests_per_file;
	my $test_file = $test_files[$i];
	my $test_file_cleaned = "html_cleaned_".$i."_".$k.".html";
	my $test_file_delimited = "html_delimited_".$i."_".$k.".html";   
	my $test_file_merged = "html_merged_".$i."_".$k.".html";
	my $test_file_counters = "html_counters_".$i."_".$k;
	
	# get the original text
	open(FILE, $test_file) || die("cannot open to read $test_file");
	my $original_text;
	read(FILE, $original_text, -s $test_file);
	close(FILE);
	
	# create the Regexp::IgnoreHTML object (that implements 
	# the get_tokens method)
	my $rei = new Regexp::IgnoreHTML($original_text, 
					 "<__INDEX__>");
	
	if ($k == 0) { # stay with the defaults
	    $rei->space_after_non_text_characteristics_html(0);
	}
	elsif ($k == 1) {
	    $rei->space_after_non_text_characteristics_html(1);
	}

	unless ($GENERATE_TEST_FILES) {
	    print_ok($rei, 2 + $j, "Regexp::IgnoreHTML object was created");
	}
	
	# split
	$rei->split();
	if ($GENERATE_TEST_FILES) {
	    open(FILE, ">".$test_file_cleaned) 
		|| die("cannot open to write $test_file_cleaned");;
	    print FILE $rei->cleaned_text();
	    close(FILE);
	}
	else {
	    my $saved_results;
	    open(FILE, $test_file_cleaned) 
		|| die("cannot open to read $test_file_cleaned");
	    read(FILE, $saved_results, -s $test_file_cleaned);
	    close(FILE);
	    print_ok(($saved_results eq $rei->cleaned_text()), 3 + $j, 
		     "Generated cleaned text");
	}
	
	if ($GENERATE_TEST_FILES) {
	    open(FILE, ">".$test_file_delimited) 
		|| die("cannot open to write $test_file_delimited");;
	    print FILE $rei->delimited_text();
	    close(FILE);
	}
	else {
	    my $saved_results;
	    open(FILE, $test_file_delimited) 
		|| die("cannot open to read $test_file_delimited");
	    read(FILE, $saved_results, -s $test_file_delimited);
	    close(FILE);
	    print_ok(($saved_results eq $rei->delimited_text()), 4 + $j, 
		     "Generated delimited text");
	}
	
	my $counter1 = 
	    $rei->s('(bla)_(\d+)','<font color=red>$2</font>_$1','gi');
	my $counter2 = $rei->s('(\d+)','<font color=green>$1</font>','');
	my $counter3 = $rei->s('general','GENERAL','gi');
	my $counter4 = $rei->s('bla','blaaaa', 'i');
	
	if ($GENERATE_TEST_FILES) {
	    open(FILE, ">".$test_file_counters) 
		|| die("cannot open to write $test_file_counters");
	    print FILE $counter1."\n".$counter2."\n".
		$counter3."\n".$counter4."\n";
	    close(FILE);
	}
	else {
	    open(FILE, $test_file_counters) 
		|| die("cannot open to read $test_file_counters");
	    my ($saved_counter1, $saved_counter2, 
		$saved_counter3, $saved_counter4) = <FILE>;
	    
	    chomp($saved_counter1, $saved_counter2, 
		  $saved_counter3, $saved_counter4);
	    close(FILE);
	    print_ok($counter1 == $saved_counter1, 5 + $j, 
		     "Substitution action");
	    print_ok($counter2 == $saved_counter2, 6 + $j, 
		     "Second substitution action");
	    print_ok($counter3 == $saved_counter3, 7 + $j, 
		     "Third substitution action");
	    print_ok($counter4 == $saved_counter4, 8 + $j, 
		     "Third substitution action");
	}
	
	$rei->translation_position_factor(0);
	my $cleaned_text = $rei->cleaned_text();
	my $after_the_matach;
	my $buffer = "";
	my $last_position = 0;
	# for each word
	while ($cleaned_text =~ /Rani[\s\n]+Pinchuk/g) {
	    my $match = $&;
	    my $end_match_position = pos($cleaned_text) - 1;
	    my $match_length = length($match);
	    my $start_match_position = $end_match_position - $match_length + 1;
	    my $replacer = '<a href="mailto:rani@cpan.org">Rani Pinchuk</a>';
	    
	    $rei->replace(\$buffer,
			  \$last_position,
			  $start_match_position,
			  $end_match_position,
			  $replacer);
	}
	$buffer .= substr($rei->cleaned_text(), $last_position);
	$rei->cleaned_text($buffer);
	
	$rei->merge();
	if ($GENERATE_TEST_FILES) {
	    open(FILE, ">".$test_file_merged) 
		|| die("cannot open to write $test_file_merged");
	    print FILE $rei->text();
	    close(FILE);
	}
	else {
	    my $saved_results;
	    open(FILE, $test_file_merged)
		|| die("cannot open to read $test_file_merged");
	    read(FILE, $saved_results, -s $test_file_merged);
	    close(FILE);
	    print_ok(($saved_results eq $rei->text()), 9 + $j, 
		     "Merged to get back the text");
	}
	
    }
}


#############################################
# print_ok ($expression, $number, $comment)
#############################################
sub print_ok {
    my $expression = shift || 0;
    my $number = shift;
    my $string = shift || "";
    $string = "ok " . $number . " " . $string . "\n";
    if (! $expression) {
        $string = "not " . $string;
    }
    print $string;
} # print_ok
