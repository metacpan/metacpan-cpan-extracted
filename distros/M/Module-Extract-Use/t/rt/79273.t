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
my $file = catfile( qw(corpus RT79273.pm) );
ok( -e $file, "Test file [$file] is there" );

my $details = $extor->get_modules_with_details( $file );
is( scalar @$details, 2, 'There are the right number of hits' );

is_deeply( $details, expected(), 'The data structures match' );
}

sub expected {
	return  [
          {
            'content' => 'use parent \'CGI::Snapp\';',
            'pragma' => 'parent',
            'version' => undef,
            'imports' => [qw(CGI::Snapp)],
            'module' => 'parent'
          },
          {
            'content' => 'use Capture::Tiny \'capture\';',
            'pragma' => '',
            'version' => undef,
            'imports' => [qw(capture)],
            'module' => 'Capture::Tiny'
          },
	];
	}
