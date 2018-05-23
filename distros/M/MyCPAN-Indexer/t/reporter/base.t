#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Spec::Functions;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $class = 'MyCPAN::Indexer::Reporter::Base';
use_ok( $class );

my $reporter = $class->new;
isa_ok( $reporter, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
can_ok( $reporter, 'get_report_file_extension' );
my $rc = eval { $reporter->get_report_file_extension; 1 };
my $at = $@;
ok( ! defined $rc, 'eval catches an error' );
like( $at, 
	qr/You must/, 
	'Abstract get_report_file_extension croaks with right message' 
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
can_ok( $reporter, 'get_success_report_subdir' );
is( $reporter->get_success_report_subdir, 'success' );

can_ok( $reporter, 'get_error_report_subdir' );
is( $reporter->get_error_report_subdir,   'error' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my $info  = bless { 
	completed => 1,  
	dist_info => { dist_file => 'Foo-Bar-0.01.tgz' }, 
	}, 'Mock::run_info';
my $Notes = { Finished => 1, config => bless {}, 'Mock::config' };
my $config = bless( {
		success_report_dir => 'success',
		error_report_dir   => 'error',
		}, 'Mock::config' );
can_ok( $config, 'get' );
		
my $coordinator = bless { 
	info     => $info, 
	notes    => $Notes, 
	config   => $config,
	reporter => $reporter,
	}, 'Mock::coordinator';
	
$reporter->set_coordinator( $coordinator );

# some of these methods now depend concrete methods
bless $reporter, 'Mock::derived';

is( $reporter->get_report_subdir( $info ), 'success' );
is( $reporter->get_report_path( $info ), catfile( qw(success F Fo Foo-Bar-0.01.test) ) );

$info->{error} = 1;

is( $reporter->get_report_subdir( $info ), 'error' );
is( $reporter->get_report_path( $info ), catfile( qw(error F Fo Foo-Bar-0.01.test  ) ) );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
BEGIN {

	{
	package Mock::derived;
	use base qw(MyCPAN::Indexer::Reporter::Base);
	
	sub get_report_file_extension { 'test' }
	}
	
	{
	package Mock::run_info;
	
	sub run_info { $_[0]->{ $_[1] } || '' }
	}

	{
	package Mock::coordinator;
	use Data::Dumper;
	sub get_config { $_[0]->{config} }
	sub set_config { 1 }
	sub get_info   { $_[0]->{info}   }
	sub get_notes  { $_[0]->{notes}  }
	sub get_note   { 1 }
	sub set_note   { 1 }
	sub set_info { 1 }
	sub increment_note  { 1 }
	sub decrement_note  { 1 }
	sub push_onto_note  { 1 }
	sub unshift_onto_note  { 1 }
	sub get_note_list_element { 1 } 
	sub set_note_unless_defined	 { 1 }
	sub get_component { 1 }
	}

	{
	package Mock::config;
	
	my %Config = (
		error_report_subdir   => 'error',
		success_report_subdir => 'success',
		);
		
	sub get {  eval { $Config{$_[1] || '' } } || '' }
	}

}
