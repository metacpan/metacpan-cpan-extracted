#!perl -T

use strict;
use warnings;

use Test::More;

use File::Spec;
use FindBin;
use Cwd ();

use Template::Sandbox;
use Test::Exception;

plan tests => 23;

my ( $template, $template_root, $template_file, $expected );


#  TODO:  nasty nasty nasty, find out how Template::Toolkit etc do it.
{
    my ( @candidate_dirs );

    foreach my $startdir ( Cwd::cwd(), $FindBin::Bin )
    {
        push @candidate_dirs,
            File::Spec->catdir( $startdir, 't', 'test_templates' ),
            File::Spec->catdir( $startdir, 'test_templates' );
    }

    @candidate_dirs = grep { -d $_ } @candidate_dirs;

    plan skip_all => ( 'unable to find t/test_templates relative to bin: ' .
        $FindBin::Bin . ' or cwd: ' . Cwd::cwd() )
        unless @candidate_dirs;

    $template_root = $candidate_dirs[ 0 ];
}


#
#  1:  construct-option absolute template filename
$template_file = 'if_a_blue_else_red_endif.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new(
    template => $template_file,
    );
$template->add_var( a => 1 );
is( ${$template->run()}, "blue\n",
    'construct-option absolute template filename' );

#
#  2:  post-construct absolute template filename
$template_file = 'if_a_blue_else_red_endif.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$template->add_var( a => 0 );
is( ${$template->run()}, "red\n",
    'post-construct absolute template filename' );

#
#  3: construct-option relative template filename.
$template_file = 'if_a_blue_else_red_endif.txt';
$template = Template::Sandbox->new(
    template_root => $template_root,
    template      => $template_file,
    );
$template->add_var( a => 1 );
is( ${$template->run()}, "blue\n",
    'construct-option relative template filename' );

#
#  4: post-construct relative template filename
$template_file = 'if_a_blue_else_red_endif.txt';
$template = Template::Sandbox->new();
$template->set_template_root( $template_root );
$template->set_template( $template_file );
$template->add_var( a => 0 );
is( ${$template->run()}, "red\n",
    'post-construct relative template filename' );

#
#  5: construct-option missing template file.
$template_file = 'this_file_does_not_exist.txt';
throws_ok {
    $template = Template::Sandbox->new(
        template_root => $template_root,
        template      => $template_file,
        );
    }
    qr{Template initialization error: Unable to find matching template from candidates:\n.*t.*test_templates.*this_file_does_not_exist\.txt at .*Template.*Sandbox\.pm line},
    'construct-option missing template file';

#
#  6: post-construct missing template filename
$template_file = 'this_file_does_not_exist.txt';
$template = Template::Sandbox->new();
$template->set_template_root( $template_root );
throws_ok { $template->set_template( $template_file ) }
    qr{Template post-initialization error: Unable to find matching template from candidates:\n.*t.*test_templates.*this_file_does_not_exist\.txt at .*Template.*Sandbox\.pm line},
    'post-construct missing template file';

#
#  7: simple include
$template_file = 'simple_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Including a simple include file.
This is a simple included file.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'simple include' );

#
#  8: quoted simple include
$template_file = 'quoted_simple_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Including a simple quoted include file.
This is a simple included file.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'simple include' );

#
#  9: defines
$template_file = 'defines.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Outermost file has no defines,
Including next file with DEFINEA=10 and DEFINEB="11 is what I am".
DEFINEA = 10
DEFINEB = 11 is what I am
Inner with DEFINEA = 99 and DEFINEB unchanged.
DEFINEA = 99
DEFINEB = 11 is what I am
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'includes with defines' );

#
#  10: defines set by set_template()
$template_file = 'included_defines.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file,
    {
    DEFINEA => 44,
    DEFINEB => 'four-four',
    } );
$expected = <<END_OF_EXPECTED;
DEFINEA = 44
DEFINEB = four-four
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'defines set with set_template()' );

#
#  11: scoped vars
$template_file = 'scoped_vars.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$template->add_vars( {
    a => 1,
    b => 200,
    } );
$expected = <<END_OF_EXPECTED;
Outer a = 1, b = 200
Including inner file without setting a or b, but c=99.
a = 1
b = 200
c = 99
Including inner file with scoped vars a=12, b=42, c=98.
a = 12
b = 42
c = 98
Outer a = 1, b = 200
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'includes with scoped vars' );

#
#  12: directly recursive includes.
$template_file = 'recursive_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
throws_ok { $template->set_template( $template_file ) }
    qr{Template compile error: recursive include of .*t.*test_templates.*recursive_include\.txt at line 1, char 1 of '.*t.*test_templates.*recursive_include\.txt' at .*Template.*Sandbox\.pm line},
    'directly recursive include';

#
#  13: indirectly recursive includes.
$template_file = 'alternating_recursive_include1.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
throws_ok { $template->set_template( $template_file ) }
    qr{Template compile error: recursive include of .*t.*test_templates.*alternating_recursive_include1\.txt at line 1, char 1 of '.*t.*test_templates.*alternating_recursive_include2\.txt'\n  called from line 1, char 49 of '.*t.*test_templates.*alternating_recursive_include1\.txt' at .*Template.*Sandbox\.pm line},
    'indirectly recursive include';

#
#  14: bad param to include.
$template_file = 'bad_include_param.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
throws_ok { $template->set_template( $template_file ) }
    qr{Template compile error: Undefined value for keyword: 'paramwithoutavalue' on parse_args\( included_simple\.txt paramwithavalue='value' paramwithoutavalue, include \) at line 1, char 1 of '.*t.*test_templates.*bad_include_param\.txt' at .*Template.*Sandbox\.pm line},
    'error on bad param to include token';

#
#  15: no such include
$template_file = 'no_such_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
throws_ok { $template->set_template( $template_file ) }
    qr{Template compile error: Unable to find matching include from candidates:\n.*t.*test_templates.*this_include_intentionally_left__missing\.txt at line 1, char 1 of '.*t.*test_templates.*no_such_include\.txt' at .*Template.*Sandbox\.pm line},
    'error on no such include';

#  16: include of empty-string filename.
$template_file = 'empty_string_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
This should
be ok.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'include of empty-string filename' );

#
#  17: include from a subdir.
$template_file = 'subdir_include.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
This template lies inside a subdir.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'includes of file in subdir' );

#
#  18: construct-option template without read-permission.
#  19: post-construct template without read-permission.
#  20: include without read-permission.
SKIP:
{
    my ( $unreadable_file, $fh );

    $unreadable_file = 'unreadable.txt';
    $unreadable_file = File::Spec->catfile( $template_root, $unreadable_file );
    #  We have to assume to trust their filesystem, untaint blithely...
    $unreadable_file =~ /^(.*)$/;
    $unreadable_file = $1;
    chmod 0200, $unreadable_file;
    skip "Unable to make $unreadable_file unreadable prior to tests" => 3
        if -r $unreadable_file;

    #  Additional check because of people running tests as admin under cygwin.
    #  TODO: could extract localized file permission error text here for regexp
    $fh = IO::File->new( "< $unreadable_file" );
    if( $fh )
    {
        $fh->close();
        skip "Unable to make $unreadable_file unreadable prior to tests" => 3;
    }

    $template_file = 'unreadable.txt';
    $template_file = File::Spec->catfile( $template_root, $template_file );
    throws_ok
        {
            $template = Template::Sandbox->new(
                template => $template_file,
                );
        }
        qr{Template initialization error: Unable to read $unreadable_file: .*? at .*Template.*Sandbox\.pm line},
        'error on construct-option unreadable-but-existing template';

    $template_file = 'unreadable.txt';
    $template_file = File::Spec->catfile( $template_root, $template_file );
    $template = Template::Sandbox->new();
    throws_ok { $template->set_template( $template_file ) }
        qr{Template post-initialization error: Unable to read $unreadable_file: .*? at .*Template.*Sandbox\.pm line},
        'error on post-construct unreadable-but-existing template';

    $template_file = 'unreadable_include.txt';
    $template_file = File::Spec->catfile( $template_root, $template_file );
    $template = Template::Sandbox->new();
    throws_ok { $template->set_template( $template_file ) }
        qr{Template compile error: Unable to read $unreadable_file: .*? at line 2, char 1 of '.*t.*test_templates.*unreadable_include\.txt' at .*Template.*Sandbox\.pm line},
        'error on include of unreadable-but-existing file';

    #  TODO: should probably try to restore to previous setting.
    chmod 0644, $unreadable_file;
}

#
#  21: for loop with nested plain include
$template_file = 'for_include_plain.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Starting the for loop.
For loop contents.
For loop contents.
For loop contents.
For loop contents.
Ending the for loop.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'for loop nested plain include' );

#
#  22: for loop with nested include using special vars
$template_file = 'for_include_special_vars.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Starting the for loop.
For loop contents: 0.
For loop contents: 1.
For loop contents: 2.
For loop contents: 3.
Ending the for loop.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'for loop nested include using special vars' );

#
#  23: for loop with nested include using special vars in the context
$template_file = 'for_include_special_vars_context.txt';
$template_file = File::Spec->catfile( $template_root, $template_file );
$template = Template::Sandbox->new();
$template->set_template( $template_file );
$expected = <<END_OF_EXPECTED;
Starting the for loop.
For loop contents: 0.
For loop contents: 1.
For loop contents: 1.
For loop contents: 0.
Ending the for loop.
END_OF_EXPECTED
is( ${$template->run()}, $expected, 'for loop nested plain using special vars in context' );



#  TODO: if-constructs that are partly in one file and another.
#  TODO: for-loops that are partly in one file and another.
#  TODO: assigns to new var inside include looked at outside
#  TODO: assigns to existing var inside include looked at outside
#  TODO: assigns to var outside include looked at inside
