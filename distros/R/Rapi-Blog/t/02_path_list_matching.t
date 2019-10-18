# -*- perl -*-

# This unit test checks the matching rules that are applied to scaffold options
# like static_paths and private_paths


use strict;
use warnings;

use Test::More;
use Path::Class qw(file dir);

use_ok('Rapi::Blog::Scaffold');


sub path_list_test($$) {
  my ($list, $template) = @_;
  my $re = Rapi::Blog::Scaffold->_compile_path_list_regex(@$list);
  $template =~ $re
}


my $list1 = [qw{ css/ img/ foo }];

ok( path_list_test $list1 => 'css/foo' );
ok( path_list_test $list1 => 'css/foo/' );
ok( path_list_test $list1 => 'img/something/blah.png' );
ok( path_list_test $list1 => 'foo' );
ok( ! path_list_test $list1 => 'baz/12' );
ok( ! path_list_test $list1 => 'foos' );
ok( ! path_list_test $list1 => 'foos/apples' );
ok( ! path_list_test $list1 => 'orange/css' );



my $list2 = [qw{ css/site.css some/other/path/foo.html blah.t /Arg something.yml}];

ok( path_list_test $list2 => 'css/site.css' );
ok( path_list_test $list2 => 'some/other/path/foo.html' );
ok( path_list_test $list2 => 'blah.t' );
ok( path_list_test $list2 => 'Arg' );
ok( ! path_list_test $list2 => 'f/Arg' );
ok( ! path_list_test $list2 => 'public/something.yml' );


# These fail, consider changing API to make them pass:
ok( ! path_list_test $list2 => 'css/site.css/more' );
ok( ! path_list_test $list2 => 'blahAt' ); 


my $list3 = ['css/','*.pdf'];

ok( path_list_test $list3 => 'css/site.css' );
ok( path_list_test $list3 => 'foo.pdf' );
ok( path_list_test $list3 => 'something/else/JOE.pdf' );
ok( ! path_list_test $list3 => 'haz/foo.pdf/boo' );

# We are case-sensitive. I'm 70/30 on this is better than ignoring case
ok( ! path_list_test $list3 => 'Apple.Pdf' );


my $list4 = ['*.{png,jpg,jpeg}','some/*/path/*.pdf' ];

ok( path_list_test $list4 => 'blar/foo/fred/logo.png' );
ok( ! path_list_test $list4 => 'blar/foo/fred/logo.png/greg.gif' );
ok( path_list_test $list4 => 'larry.jpg' );
ok( path_list_test $list4 => 'some/neat/path/info.pdf' );

# here is another, we currently match * to all characters, including /  -- is this best?
ok( path_list_test $list4 => 'some/more/neat/path/info.pdf' );



done_testing;

