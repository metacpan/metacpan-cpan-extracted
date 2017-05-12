#########1 Test File for MooseX::ShortCut::BuildInstance    6#########7#########8#########9
#!perl

$| = 1;

use Test::Most tests => 40;
use Test::Moose;
use Capture::Tiny 0.12 qw(
		capture_stderr
	);
use MooseX::Types::Moose qw( Str );
#~ use Types::Standard 1.000 -types;

use	lib '../../../../Log-Shiras/lib',
		'../../../lib',
		'../../', 'lib', 't';
#~ use Log::Shiras::Unhide qw( :debug :InternaLBuilDInstancE );
###LogSD	use Log::Shiras::Switchboard;#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
use MooseX::ShortCut::BuildInstance;
my( 
			$pet_rock_class, $paco, $pacos_evil_twin, $pacos_good_twin, 
			$anonymous_class, $anonymous_instance,
);
my 			$test_case = 1;
my 			@class_attributes = qw(
			);
my  		@class_methods = qw(
			);
my  		@exported_methods = qw(
				build_class
				build_instance
				should_re_use_classes
				set_class_immutability
			);
my			$answer_ref = [
				'',
				[
					"undef,",
				],
			];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "Start with the easy questions ..." ] );
map{ 
has_attribute_ok
			'MooseX::ShortCut::BuildInstance', $_,
										"Check that Data::Walk::Extracted has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		'MooseX::ShortCut::BuildInstance', $_,
} 			@class_methods;
map{
can_ok		'main', $_,
} 			@exported_methods;

###LogSD	$phone->talk( level => 'info', message => [ "Now the harder questions..." ] );
lives_ok{
			$pet_rock_class = build_class(
				package => 'Pet::Rock',
				superclasses =>['Vegetable'],
				add_methods	=>{ is_important => sub{ print "I'm the best" }, },
				add_roles_in_sequence =>['Identity'],
			);
}										"Build a Pet::Rock class (with an Identity)";
does_ok		$pet_rock_class, 'Identity',"Ensure the Pet::Rock really does have an Identity";
is			$pet_rock_class->meta->name, 'Pet::Rock',
										"Make sure this is a Pet::Rock class";
lives_ok{
			$paco = $pet_rock_class->new(
				type_of_mineral => 'Quartz',
				name => 'Paco',
			);
}										'Get my own pet rock Paco';
is_deeply	[ $paco->meta->superclasses ], ['Vegetable'],
										"See if Paco is a Vegetable class (Not really right)";
			my	$error_message;
			$error_message = capture_stderr{
lives_ok{
			$pacos_evil_twin = build_instance(
				package => 'Pet::Rock',
				superclasses =>['Mineral'],
				add_roles_in_sequence =>['Identity'],
				add_attributes =>{ owner =>{ is => 'ro', isa => Str } },
				add_methods =>{
					rochambeau => sub{
						my ( $self, $challenge ) = @_;
						### <where> - Champion: $self->name
						### <where> - challenged in rochambeau by: $challenge
						return ( $challenge =~ /(sissers|lizard)/i ) ? 'won' : 'lost';
					},
					is_important => sub{ print "I'm the best" },
				},
				type_of_mineral => 'Quartz',
				name => 'Fransisco',
			);
}										"Get Paco's doppleganger";
			};
like		$error_message, qr/^You already built the class: Pet::Rock/m,
										"Check that a (correct) warning was issued for the overwritten class!";
is_deeply	[ $paco->meta->superclasses ], ['Mineral'],
										"See if Paco (not Fransisco) is a Mineral class now (dangerous magic!)";
lives_ok{	should_re_use_classes( 1 ) }
										"Set class re-use to on";
			$error_message = capture_stderr{
lives_ok{
			$pacos_good_twin = build_instance(
				package => 'Pet::Rock',
				superclasses =>['Mineral'],
				roles =>['Identity'],
				type_of_mineral => 'Quartz',
				name => 'Pancho',
				owner => 'Dr. Sheldon Cooper',
			);
}										"Get Paco's doppleganger( excersizing some of the Original class magic not here)";
			};
lives_ok{
			my @error_list = split /\n/, $error_message;
			$error_message = [];
			for my $line ( @error_list ){
				print $line . "\n";
				if( $line !~ /^(###|'?\s{0,3})/ ){
					push @$error_message, $line;
				}
			}
}										"Massage the STDERR output";
is			scalar( @$error_message ), 0,
										"Check that no warning was issued for the overwritten class!";
does_ok		$pacos_good_twin, 'Identity',
										"Ensure that Paco's twin really does have an Identity";
is			$pacos_good_twin->meta->name, 'Pet::Rock',
										"Make sure the twin is also a Pet::Rock class";
is_deeply	[ $paco->meta->superclasses ], ['Mineral'],
										"Make sure that Paco is a Mineral class";
is_deeply	[ $pacos_good_twin->meta->superclasses ], ['Mineral'],
										"Make sure that Pancho (Paco's twin) is also a Mineral class";
###LogSD	$phone->talk( level => 'trace', message => [ 'Paco:', $paco ] );
is			$paco->name, 'Paco',		"Make sure Paco knows his name";
is			$pacos_good_twin->name, 'Pancho',
										"Make sure Pancho knows his name";
is			$pacos_good_twin->rochambeau( 'paper' ), 'lost',
										"See if 'Pancho' beats paper in rochambeau (No)";
is			$pacos_good_twin->rochambeau( 'sissers' ), 'won',
										"See if 'Pancho' beats sissers in rochambeau (Yes)";
is			$pacos_good_twin->owner, 'Dr. Sheldon Cooper',
										"Who owns 'Pancho'? - Dr. Sheldon Cooper";
is			$MooseX::ShortCut::BuildInstance::anonymous_class_count, 0,
										"Check if any anonymous classes have been built";
lives_ok{
			$anonymous_class = build_class(
				superclasses =>['Mineral'],
				add_methods	=>{ is_important => sub{ print "I'm the best" }, },
				add_roles_in_sequence =>['Identity'],
			);
}										"Build a Pet::Rock class (without the package name)";
like		$anonymous_class->meta->name, qr/^ANONYMOUS_SHIRAS_MOOSE_CLASS_\d*$/,
										"Make sure this is an anonymous class";
is			$MooseX::ShortCut::BuildInstance::anonymous_class_count, 1,
										"... and that the counter is incremented";
lives_ok{
			$pet_rock_class = build_class(
				package => 'Individual',
				add_methods	=>{ is_important => sub{ print "I'm the best" }, },
				add_roles_in_sequence =>['Identity'],
				type_of_mineral => 'Quartz',
			);
}										"Build an Individual class (without a Mineral superclass)";
###LogSD	$phone->talk( level => 'trace', message => [ 'pet rock class:', $pet_rock_class->meta->linearized_isa ] );
is			$pet_rock_class->meta->name, 'Individual',
										"Make sure this is an Individual class";
does_ok		$pet_rock_class, 'Identity',"Ensure the Individual really does have an Identity";
###LogSD	$phone->talk( level => 'debug', message => [ 'the isa:', $pet_rock_class->isa( 'Mineral' ) ] );
ok			!$pet_rock_class->isa( 'Mineral'),
										"Check that the class (doesnt) have a 'Mineral' superclass";
ok			!$pet_rock_class->can( 'type_of_mineral' ),
										"Test that there is no 'type_of_mineral'";
lives_ok{
			$pet_rock_class = build_class(
				package => 'Rock',
				superclasses =>['Mineral'],
				type_of_mineral => 'Quartz',
			);
}										"Build a Rock class (without the Identity role)";
###LogSD	$phone->talk( level => 'trace', message => [ 'pet rock class:', $pet_rock_class->meta->linearized_isa ] );
is			$pet_rock_class->meta->name, 'Rock',
										"Make sure this is a Rock class";
ok			!$pet_rock_class->DOES( 'Identity' ),
										"Ensure the Rock does not have an Identity";
###LogSD	$phone->talk( level => 'debug', message => [ 'the isa:', $pet_rock_class->isa( 'Mineral' ) ] );
ok			$pet_rock_class->isa( 'Mineral'),
										"Check that the class does have a 'Mineral' superclass";
ok			$pet_rock_class->can( 'type_of_mineral' ),
										"Test that there is a 'type_of_mineral'";
lives_ok{ 	$anonymous_instance = build_instance() }
										"Attempt an anonymous instance (without any superclass or role)";
explain 								"...Test Done";
done_testing(40);

###LogSD	package Print::Log;
###LogSD	use Data::Dumper;
###LogSD	sub new{
###LogSD		bless {}, shift;
###LogSD	}
###LogSD	sub add_line{
###LogSD		shift;
###LogSD		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
###LogSD						@{$_[0]->{message}} : $_[0]->{message};
###LogSD		my ( @print_list, @initial_list );
###LogSD		no warnings 'uninitialized';
###LogSD		for my $value ( @input ){
###LogSD			push @initial_list, (( ref $value ) ? Dumper( $value ) : $value );
###LogSD		}
###LogSD		for my $line ( @initial_list ){
###LogSD			$line =~ s/\n$//;
###LogSD			$line =~ s/\n/\n\t\t/g;
###LogSD			push @print_list, $line;
###LogSD		}
###LogSD		printf( "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:(\t%s ):\n", 
###LogSD					$_[0]->{level}, $_[0]->{name_space},
###LogSD					$_[0]->{line}, $_[0]->{filename},
###LogSD					join( "\n\t\t", @print_list ) 	);
###LogSD		use warnings 'uninitialized';
###LogSD	}

###LogSD	1;