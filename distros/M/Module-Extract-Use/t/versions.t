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
my $file = catfile( qw(corpus PackageVersion.pm) );
ok( -e $file, "Test file [$file] is there" );

my $details = $extor->get_modules_with_details( $file );
is( scalar @$details, 3 );
#diag( Dumper( $details ) ); use Data::Dumper;

is_deeply( $details, expected() );
print Dumper( $details ), "\n"; use Data::Dumper;
}


sub expected {
	return  [
          {
            'content' => 'use HTTP::Size 1.23;',
            'pragma'  => '',
            'version' => '1.23',
            'imports' => [],
            'module'  => 'HTTP::Size'
          },
          {
            'content' => 'use YAML::Syck 1.54 qw(LoadFile);',
            'pragma'  => '',
            'version' => '1.54',
            'imports' => [ qw(LoadFile) ],
            'module'  => 'YAML::Syck'
          },
          {
            'content' => 'use LWP::Simple 6.1 qw(getstore);',
            'pragma'  => '',
            'version' => '6.1',
            'imports' => [ qw(getstore) ],
            'module'  => 'LWP::Simple'
          }
        ];

	}
