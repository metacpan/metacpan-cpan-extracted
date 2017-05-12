use Test::More;
use Test::Mojo;
use MojoX::DirectoryListing;
use strict;
use warnings;
use Data::Dumper; $Data::Dumper::Sortkeys=$Data::Dumper::Indent=1;

sub can_test_forbidden {
    $< != 0 && $^O ne 'MSWin32' && $^O ne 'cygwin';
}

{
    my (@madefiles,@madedirs);

    sub mk_file {
	my $fname = shift;
	if (open my $fh, '>', $fname) {
	    if (!print $fh "This is file $fname\n") {
		warn "mk_file: Could not print to $fh/$fname  $!\n";
		close $fh;
		return 1;
	    }
	    close $fh;
	    push @madefiles, $fname;
	} else {
	    warn "mk_file: failed to create $fname  $!\n";
	    return 1;
	}
	return 0;
    }

    sub mk_dir ($) {
	my $dname = shift;
	if (mkdir $dname) {
	    unshift @madedirs, $dname;
	} else {
	    warn "mk_dir: failed to create $dname\n";
	    return 1;
	}
	return 0;
    }

    sub build_app1_filesystem {
	diag "building test filesystem";
	my $fail = 0;
	$fail += mk_dir "t/app1/$_" for qw(
		public private public/dir1 public/dir2
		public/dir2/dir3 private/dir4);

	$fail += mk_file "$_/forbidden.gif" for @madedirs;
	chmod 000, "$_/forbidden.gif" for @madedirs;
	$fail += mk_file "$_/middle.html" for @madedirs;
	$fail += mk_file "$_/young.vb" for @madedirs;

	# remarkably, creating .../old.txt fails for CPANTS tester
	# njh at bandsman but  middle.html  and  young.vb  succeed?
	# cf. http://www.cpantesters.org/cpan/report/
	#               07c059f4-b916-11e6-886b-73ce95f05882
	$fail += mk_file "$_/old.txt" for @madedirs;
	return $fail;
    }

    END {
	diag "tearing down test filesystem";
	chmod 0666, "$_/forbidden.gif" for @madedirs;
	unlink $_ for @madefiles;
	rmdir $_ for @madedirs;
    }
}

ok(0 == build_app1_filesystem(), 'built file hierarchy successfully');

# a string that identifies output produced by MojoX::DirectoryListing
my $identifier = qr/directory listing by MojoX::DirectoryListing/;

MojoX::DirectoryListing::set_public_app_dir( 't/app1/public' );


# test Server1: no directories served

my $t1 = Test::Mojo->new('t::app1::Server1');
$t1->get_ok('/test')->status_is(200)
    ->content_is('Server1', 'Server1 is active');
$t1->get_ok('/old.txt')->status_is(200)
    ->content_like(qr{public/old.txt}, 'access regular file');
$t1->get_ok('/dir2/dir3/middle.html')->status_is(200)
	->content_like( qr{public/dir2/dir3/middle.html},
			'access file in subdirectory' );
$t1->get_ok('/')
    ->status_isnt(200, 'directory not available when not served' );
    $DB::single =1 ; 
$t1->get_ok('/dir2/dir3')
    ->status_isnt(200, 'subdir not available when not served');
$t1->get_ok('/dir2')->status_isnt(200);



# test Server2: serve  /public  and  /public/dir2/dir3

my $t2 = Test::Mojo->new('t::app1::Server2');

$t2->get_ok('/test')->status_is(200)
    ->content_is('Server2', 'Server2 active');
$t2->get_ok('/old.txt')->status_is(200)
    ->content_like(qr{public/old.txt}, 'access regular file' );
$t2->get_ok('/dir2/dir3/middle.html')->status_is(200)
	->content_like( qr{public/dir2/dir3/middle.html},
			'access file in subdirectory' );
$t2->get_ok('/')->status_is(200)
	->content_like( $identifier , 'content served by this distro' )
	->content_like( qr/middle.*old.*young/s, 'files listed by name' )
	->content_like( qr/thead.*Name.*Modified.*Size.*Type.*thead/s,
			'all columns present' );
$t2->get_ok('/dir2/dir3')->status_is(200)
    ->content_like( $identifier, 'subdir served by this module' );
$t2->get_ok('/dir2/dir3?C=N&O=D', 'request for list in descending order')
    ->status_is(200, 'request ok')
    ->content_like( qr/young.*old.*middle/s, 'files in descending order' );

can_test_forbidden && 
    $t2->content_unlike( qr/forbidden/, 'forbidden files hidden' );
# !: forbidden tests fail when you test as root because no files are forbidden
# !: forbidden tests fail on Windows, too

$t2->get_ok('/?C=M', 'request for list from oldest to newest')
    ->status_is(200, 'request ok')
    ->content_like( qr/old.*middle.*young/s, 'files in  correct order' );
$t2->get_ok('/?C=M&O=D', 'request for list from oldest to newest')
    ->status_is(200, 'request ok')
    ->content_like( qr/young.*middle.*old/s, 
		    'files in  correct order' );
$t2->get_ok('/?C=S&O=A', 'request for list from smallest to largest')
    ->status_is(200, 'request ok')
    ->content_like( qr/old.*young.*middle/s, 
		    'files in  correct order' );
$t2->get_ok('/?C=S&O=D', 'request for list from largest to smallest')
    ->status_is(200, 'request ok')
    ->content_like( qr/middle.*young.*old/s, 'files in  correct order' );
$t2->get_ok('/?C=T', 'request for list order by type')
    ->status_is(200, 'request ok')
    ->content_like( qr/middle.*old.*young/s, 'files in correct order' );
$t2->get_ok('/?C=T&O=D', 'request for list ordered by type descending')
    ->status_is(200, 'request ok')
    ->content_like( qr/young.*old.*middle/s, 'files in correct order' );

$t2->get_ok('/dir2')->status_isnt(200);


# test Server3: public/dir2/dir3 as dir23, public/dir2, public/dir4
#         NOT:  public/ !
my $t3 = Test::Mojo->new('t::app1::Server3');
$t3->get_ok('/test')->status_is(200)->content_is('Server3');
$t3->get_ok('/old.txt')->status_is(200)->content_like(qr{public/old.txt});
$t3->get_ok('/dir2/dir3/middle.html')->status_is(200)
	->content_like(qr{public/dir2/dir3/middle.html});
$t3->get_ok('/')->status_isnt(200);
$t3->get_ok('/dir2/dir3')->status_isnt(200);
# diag $t3->tx->{res}{content}{asset}{content};
$t3->get_ok('/dir2')->status_is(200)->content_like( $identifier );
$t3->get_ok('/dir23')->status_is(200)
    ->content_like( $identifier,
		    'access dir lising through alias' );
$t3->get_ok('/dir23/middle.html')->status_is(200)
	->content_like(qr{public/dir2/dir3/middle.html},
			'served file using dir alias' );

# Server4 serves (now pay attention):
#    public/           hide file time, sort by name
#    public/dir1       hide file type, sort by size
#    public/dir2       hide file size, sort by type (descending), show forbidden
#    public/dir2/dir3  hide time,size,and type   sort by size
my $t4 = Test::Mojo->new('t::app1::Server4');
$t4->get_ok('/test')->content_is('Server4', 'Server4 is active');
$t4->get_ok('/')->status_is(200)
    ->content_like( qr/thead.*Name.*Size.*Type/s )
    ->content_like( qr/directory-listing-name/ )
    ->content_unlike( qr/Modified/, 'Last Modified column suppressed' )
    ->content_unlike( qr/directory-listing-time/ )
    ->content_like( qr/middle.*old.*young/s, 'ordered by name' );
$t4->get_ok('/dir1')->status_is(200)
    ->content_like( qr/thead.*Name.*Modified.*Size.*thead/s,
		    'output has column headings' )
    ->content_unlike( qr/Type.*thead/s , 'Type column suppressed' )
    ->content_like( qr/directory-listing-time/,
		    'listings include last modtime' )
    ->content_unlike( qr/directory-listing-type/ ,
		      'listings do not include file type')
    ->content_like( qr/old.*young.*middle/s , 'ordered by size' );
can_test_forbidden && 
    $t4->content_unlike( qr/forbidden/, 'forbidden files suppressed' );

$t4->get_ok('/dir2')->status_is(200)
    ->content_like( qr/thead.*Name.*Modified.*Type.*thead/s,
		    'output has column headings' )
    ->content_unlike( qr/thead.*Size.*thead/s, 'show-file-size => 0' )
    ->content_like( qr/directory-listing-type/,
		    'listings include file type' )
    ->content_unlike( qr/directory-listing-size/, 'size column suppressed' )
    ->content_like( qr/young.*old.*middle/s, 'order by type descending' );
can_test_forbidden &&
    $t4->content_like( qr/forbidden/, 'show-forbidden support' );
$t4->get_ok('/dir2/dir3')->status_is(200)
    ->content_like( qr/thead.*Name.*thead/s,
		    'column headings include Name' )
    ->content_unlike( qr/thead.*Size.*thead/s,
		      'column headings do not include Size' )
    ->content_unlike( qr/thead.*Modified.*thead/s,
		      'column headings do not include Last Modified' )
    ->content_unlike( qr/directory-listing-[ts]/,
		      'listings do not include time,size,or type' )
    ->content_like( qr/old.*young.*middle/s ,
		    'files ordered by suze' );

# Server5: serve  public/  as  /  and  private/  as  /hidden
# test private directories
my $t5 = Test::Mojo->new( 't::app1::Server5' );
$t5->get_ok('/test')->status_is(200)->content_is('Server5', 'Server5 active');
$t5->get_ok('/')->status_is(200)
    ->content_like( $identifier, '"/" served from this module' );
$t5->get_ok('/dir1')->status_isnt(200, '/dir1 not accessible');
$t5->get_ok('/dir1/old.txt')->status_is(200, 'file in public/dir1 accessible');
$t5->get_ok('/hidden')->status_is(200, '/hidden req ok')
    ->content_like( $identifier, '/hidden is a directory listing' )
    ->content_like( qr/middle.*old.*young/s, 'files found' );
$t5->get_ok('/hidden/middle.html')
    ->status_is(200, 'private file accessible' )
    ->content_like( qr{private/middle.html}, 
		    'private file has expected contents' );
    $DB::single=1;
$t5->get_ok('/hidden/dir4')
    ->status_isnt(200, 'unserved private subdirectory not accessible' );

# Server6: like Server5 but with recursive => 1
my $t6 = Test::Mojo->new( 't::app1::Server6' );
$t6->get_ok('/test')->status_is(200)->content_is('Server6', 'Server6 active');
$t6->get_ok('/')->status_is(200)
    ->content_like( $identifier, 'dir served by this module' );
$t6->get_ok('/dir1')->status_is(200, 'public subdir accessible');
#print Dumper $t6->app->routes;
#print Dumper $t6->tx->res;
$t6->get_ok('/dir1/old.txt')->status_is(200, 'file in public/dir1 accessible');
$t6->get_ok('/hidden')->status_is(200, '/hidden req ok')
    ->content_like( $identifier, '/hidden is a directory listing' )
    ->content_like( qr/middle.*old.*young/s, 'files found' );
$t6->get_ok('/hidden/middle.html')->status_is(200)
    ->content_like( qr{private/middle.html}, 'got private file' );
$t6->get_ok('/hidden/dir4')->status_is(200, 'private subdir accessible');

diag "$0 Mojolicious version: $Mojolicious::VERSION\n";

done_testing();

__END__

Checklist of things to test:

X    serve a public directory
X        access file in a public directory
X    serve a non-public directory
X        access file in a non-public directory
        access file in a non-public subdirectory
X    alias a public directory
X	access file in aliased directory

X    with and without file modification time
X    with and without file size
X    with and without file type

X    view forbidden files in listing
X    suppress forbidden files in listing

X    sorted by name
X    sorted by mod time
X    sorted by size
X    all of the above, descending order

X    sort order passed by parameter
X	sort by name
X	sort by mod time
X	sort by size
X	sort by file type
X	all of the above, also in descending order

X    recursive
    recursive with exclude

