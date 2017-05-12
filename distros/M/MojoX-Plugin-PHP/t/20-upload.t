use Test::More;
use Test::Mojo;
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );




my $size = -s "t/testapp.conf";
$t->post_ok( '/handle_upload.php' =>
	     form => { my_file => { 
		 file => 't/testapp.conf',
		 name => 'test_file_name',
		 "Content-type" => "text/plain; charset=UTF-8",
		       } } )
    ->status_is(200);
my $content = $t->tx->res->body;
ok( $content =~ /\$_FILES =/, 'content looks like correct format' );
ok( $content =~ /\bmy_file\b/, 'content got correct file upload param name' );

# what is this test for? in Catalyst you send a post like
#   Content_Type => 'form-data', 
#   Content => [ PARAMNAME => [ FILENAME, UPLOADNAME, "Content-type"=>CTYPE ] ]
# and  $_FILES[PARAMNAME]['name'] is set to  UPLOADNAME
#   
#ok( $content =~ /\bname\b.*test_file_name/, 'file upload recorded filename' );
ok( $content =~ /\bname\b.*testapp.conf/, 'file upload recorded filename' );

ok( $content =~ /\bsize\b\D*(\d+)/ && $1 == $size,
    'file upload recorded correct file size' );
my $tmp_name = PHP::eval_return( "\$_FILES['my_file']['tmp_name']" );
ok( $tmp_name, "can recover file temp name $tmp_name from PHP" );
ok( PHP::eval_return( "is_uploaded_file('$tmp_name')" ),
    "PHP believes $tmp_name is uploaded file" );





### files may be deleted when the request is complete.
### need to perform the test inside PHP to read, move file
ok( PHP::eval_return( "is_file('$tmp_name')" ),
    "PHP believes $tmp_name is file" );
ok( -f $tmp_name, "Perl believes $tmp_name is a file" );
ok($size == -s $tmp_name, "$tmp_name has the right size" );





### multiple uploads

my $size2 = -s "MANIFEST";
$t->post_ok( '/handle_upload.php',
	     form => {
		 foo => 123,
		 my_file1 => {
		     file => 't/testapp.conf',
		     name => 'test_file_namex',
		     "Content-type" => 'text/plain; charset=UTF-8',
		 },
		 my_file2 => { 
		     file => 'MANIFEST',
		     name => 'manifest',
		     "Content-type" => 'application/octet-stream',
		 },
		 bar => 19
	     } )->status_is(200);
$content = $t->tx->res->body;

ok( $content,  'got content for POST with file upload' );
ok( $content =~ /\$_FILES =/, 'content looks like correct format' );
ok( $content =~ /\bmy_file1\b/,
    'content got correct 1st file upload param name' );
ok( $content =~ /\bmy_file2\b/,
    'content got correct 2nd file upload param name' );

#ok( $content =~ /my_file1.*\bname\b\W*test_file_namex/s,
#    'file upload recorded filename1' );
ok( $content =~ /my_file1.*\bname\b\W*testapp.conf/s,
    'file upload recorded filename1' );
ok( $content =~ /my_file2.*\bname\b\W*manifest/si,
    'file upload recorded filename2' );

ok( $content =~ /size\D*$size\b/,
    'file upload recorded correct file1 size' );
ok( $content =~ /size\D*$size2\b/,
    'file upload recorded correct file2 size' );
ok( PHP::eval_return( q^is_uploaded_file($_FILES['my_file1']['tmp_name'])^ ),
    "PHP believes file1 is uploaded file" );
ok( PHP::eval_return( q^is_uploaded_file($_FILES['my_file2']['tmp_name'])^ ),
    "PHP believes file2 is uploaded file" );

## how to test that  foo  and  bar  parameters were delivered to $_REQUEST?
## need a modified  /handle_upload  that also dumps $_GET, $_POST, $_REQUEST




### array upload

my $size3 = -s "Makefile.PL";
$t->post_ok( '/handle_upload.php',
	     form => {
		 foo => 123,
		 'farray[]' => [
		     {
			 file => 't/testapp.conf',
			 name => 'test_file_namex',
			 "Content-type" => 'text/plain; charset=UTF-8',
		     },
		     {
			 file => 'MANIFEST',
			 name => 'manifest',
			 "Content-type" => 'application/octet-stream',
		     },
		     {
			 file => 'Makefile.PL',
			 name => 'makefile.pl',
			 "Content-type" => 'application/octet-stream',
		     },
		     ],
		 bar => 19
	     } )->status_is(200);
$content = $t->tx->res->body;

ok( $content,  'got content for array upload' );
ok( $content =~ /\bfarray\W+array\b/s, 'farray param is an array' );
ok( $content =~ /\btmp_name\W+array/s &&
    $content =~ /\berror\W+array/s &&
    $content =~ /\bname\W+array/s &&
    $content =~ /\bsize\W+array/s, 'upload data is in arrays' );

my ($sizes) = $content =~ /\bsize\W+array(.*?)\)/s;
ok( $sizes =~ /\b0\W+$size\b/, 'got right size for file 1' );
ok( $sizes =~ /\b1\W+$size2\b/, 'got right size for file 2' );
ok( $sizes =~ /\b2\W+$size3\b/, 'got right size for file 3' );
ok( PHP::eval_return( q^is_uploaded_file($_FILES['farray']['tmp_name'][0])^ ),
    "PHP believes file[0] is uploaded file" );
ok( PHP::eval_return( q^is_uploaded_file($_FILES['farray']['tmp_name'][2])^ ),
    "PHP believes file[2] is uploaded file" );

####################################################

$t->post_ok( '/output_upload.php',
	     form => {
		 foo => 123,
		 output => {
		     file => 't/testapp.conf',
		     name => 'test_file_namex',
		     "Content-type" => 'text/plain; charset=UTF-8'
		 }
	     } )->status_is(200);
$content = $t->tx->res->body;
ok( $content,  'content avaialble from output_upload.php' );

ok( $content =~ /is_uploaded_file \[1\] result = 1/,
    'php reports file uploaded successfully' );
ok( $content =~ /move_uploaded_file result = 1/,
    'php reports file upload file moved successfully' );
ok( $content =~ /is_uploaded_file \[2\] result = 0/,
    'php reports file not found after it was moved' );
my ($len) = $content =~ /length read = (\d+)/;
ok( $len ne '', 'php reports file length' );
ok( $len == -s "t/testapp.conf",
    'php length agrees with known file length' );

done_testing();
