#!/usr/bin/perl
use strict;

use Test::More tests => 6;
use File::Basename;
use File::Spec::Functions qw(catfile);

my $class = "Module::Extract::Use";
use_ok( $class );

my $extor = $class->new;
isa_ok( $extor, $class );
can_ok( $extor, 'get_modules_with_details' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that has repeated use lines
# I should only get unique names
{
my $file = catfile( qw(corpus PackageImports.pm) );
ok( -e $file, "Test file [$file] is there" );

my $details = $extor->get_modules_with_details( $file );
is( scalar @$details, 10, 'There are the right number of hits' );
#diag( Dumper( $details ) ); use Data::Dumper;

is_deeply( $details, expected(), 'The data structures match' );
}


sub expected {
	return  [
          {
			'direct'  => 1,
            'pragma'  => '',
            'version' => undef,
            'imports' => [],
            'module'  => 'URI',
            'content' => 'use URI;',
          },
          {
			'direct'  => 1,
            'content' => 'use CGI qw(:standard);',
            'pragma'  => '',
            'version' => undef,
            'imports' => [
                           ':standard'
                         ],
            'module'  => 'CGI'
          },
          {
			'direct'  => 1,
            'content' => 'use LWP::Simple 1.23 qw(getstore);',
            'pragma'  => '',
            'version' => '1.23',
            'imports' => [
                           'getstore'
                         ],
            'module'  => 'LWP::Simple'
          },
          {
			'direct'  => 1,
            'content' => 'use File::Basename (\'basename\', \'dirname\');',
            'pragma'  => '',
            'version' => undef,
            'imports' => [
                           'basename',
                           'dirname'
                         ],
            'module'  => 'File::Basename'
          },
          {
			'direct'  => 1,
            'content' => 'use File::Spec::Functions qw(catfile rel2abs);',
            'pragma'  => '',
            'version' => undef,
            'imports' => [
                           'catfile',
                           'rel2abs'
                         ],
            'module'  => 'File::Spec::Functions'
          },
          {
			'direct'  => 1,
            'content' => 'use autodie \':open\';',
            'pragma'  => 'autodie',
            'version' => undef,
            'imports' => [
                           ':open'
                         ],
            'module'  => 'autodie'
          },
          {
			'direct'  => 1,
            'content' => 'use strict q\'refs\';',
            'pragma'  => 'strict',
            'version' => undef,
            'imports' => [
                           'refs'
                         ],
            'module'  => 'strict'
          },
          {
			'direct'  => 1,
            'content' => 'use warnings q<redefine>;',
            'pragma'  => 'warnings',
            'version' => undef,
            'imports' => [
                           'redefine'
                         ],
            'module'  => 'warnings'
          },
          {
			'direct'  => 1,
            'content' => 'use Buster "brush";',
            'pragma'  => '',
            'version' => undef,
            'imports' => [
                           'brush'
                         ],
            'module'  => 'Buster'
          },
          {
			'direct'  => 1,
            'content' => 'use Mimi qq{string};',
            'pragma'  => '',
            'version' => undef,
            'imports' => [
                           'string'
                         ],
            'module'  => 'Mimi'
          }
        ];

	}
