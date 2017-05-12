package TestFramework;

use YAML qw( LoadFile );
use Error qw( :try );
use File::Spec;
use Data::Random qw( rand_words rand_chars rand_set );

use TestStore;
use TestRandomizer;

use Pangloss::Users;
use Pangloss::Terms;
use Pangloss::Concepts;
use Pangloss::Languages;
use Pangloss::Categories;

use base      qw( Pangloss::Object );
use accessors qw( app langs cats users concepts terms model number );

our $DEFAULT_FILE = File::Spec->catfile(qw( t tmp framework.pl ));

sub init {
    my $self = shift;

    $self->number( {} )
         ->languages( Pangloss::Languages->new )
	 ->categories( Pangloss::Categories->new )
	 ->users( Pangloss::Users->new )
	 ->concepts( Pangloss::Concepts->new )
	 ->terms( Pangloss::Terms->new );

    $self->model( TestRandomizer->new
		    ->languages( $self->languages )
		    ->categories( $self->categories )
		    ->users( $self->users )
		    ->concepts( $self->concepts )
		    ->terms( $self->terms ) );

    return $self;
}

#------------------------------------------------------------------------------
# Instance vars

# aliases
sub application { shift->app( @_ )   }
sub languages   { shift->langs( @_ ) }
sub categories  { shift->cats( @_ )  }

#------------------------------------------------------------------------------
# Save/Load

sub save {
    my $self = shift;
    return $self->save_to_store if (TestStore->STORE);
    return $self->save_to_file;
}

sub load {
    my $class = shift->class;
    return $class->load_from_store if (TestStore->STORE);
    return $class->load_from_file;
}

#------------------------------------------------------------------------------
# File

sub save_to_file {
    my $self = shift;
    my $file = shift || $DEFAULT_FILE;

    open( CACHE, '>:utf8', $file )
      || die "error opening (w) $framework_file: $!";
    print CACHE Data::Dumper->Dump( [$self], ['::framework'] );
    close CACHE;
}

sub load_from_file {
    my $class = shift->class;
    my $file  = shift || $DEFAULT_FILE;
    return unless -e $file;
    require $file;
    return $::framework;
}

#------------------------------------------------------------------------------
# Store

sub save_to_store {
    my $self  = shift;
    my $store = shift || TestStore->STORE;

    foreach my $collection (qw( languages categories users concepts terms )) {
	$self->emit( "storing $collection collection..." );
	$store->insert( $self->$collection );
	$store->bind_name( $collection => $self->$collection );
    }

    my $stamp = bless {}, 'Stamp';
    $store->insert( $stamp );
    $store->bind_name( 'pg_framework' => $stamp );

    return $self;
}

sub load_from_store {
    my $class = shift->class;
    my $store = shift || TestStore->STORE;
    my $stamp = $store->get_object_named( 'pg_framework' ) || return;

    my $self = $class->new;
    foreach my $collection (qw( languages categories users concepts terms )) {
	$self->emit( "getting stored $collection collection..." );
	$self->$collection( $store->get_object_named( $collection ) );
    }

    return $self;
}


#------------------------------------------------------------------------------
# Model Creator

# guaranteed to have 1 admin user, plus all the concepts,
# languages, and terms listed in the yaml file given.
sub create_random_model_from {
    my $self = shift;
    my $file = shift || return;

    $self->emit( "creating partially-random model from $file..." );

    $self->model->create_random_model( %{ $self->number } );

    $self->parse_yaml_db( $file )
         ->emit( "done." );

    return $self;
}

#------------------------------------------------------------------------------
# YAML DB parser

sub parse_yaml_db {
    my $self = shift;
    my $file = shift;

    my $model = $self->model;
    my $yaml_io = Pangloss::IO::YAML::Random->new
	->languages( $self->langs )
        ->categories( $self->cats )
	->users( $self->users )
        ->concepts( $self->concepts )
        ->terms( $self->terms )
	->choose({
		  random_time       => sub { $model->random_time(@_) },
		  random_category   => sub { $model->choose_random_category(@_)   },
		  random_creator    => sub { $model->choose_random_creator(@_)    },
		  random_status     => sub { $model->create_random_status(@_)     },
		  random_translator => sub { $model->choose_random_translator(@_) },
	         })
	->load( $file );

    return $self;
}

#------------------------------------------------------------------------------
# YAML input randomizer

package Pangloss::IO::YAML::Random;

use base qw( Pangloss::IO::YAML );

sub choose {
    my $self = shift;
    if (@_) { $self->{-choose} = $_[0]; return $self; }
    else    { return $self->{-choose}; }
}

sub get_or_create_lang {
    my $self = shift;
    $self->SUPER::get_or_create_lang( @_ )
	 ->date( $self->choose->{random_time}->() );
}

sub get_or_create_concept {
    my $self = shift;
    $self->SUPER::get_or_create_concept( @_ )
	 ->category( $self->choose->{random_category}->() )
	 ->creator( $self->choose->{random_creator}->() )
	 ->date( $self->choose->{random_time}->() );
}

sub create_term {
    my $self    = shift;
    my $concept = shift;
    my $name    = shift;
    my $lang    = shift;
    my $term = $self->SUPER::create_term( $concept, $name, $lang ) || return;
    $term->status( $self->choose->{random_status}->( $lang ) )
	 ->creator( $self->choose->{random_translator}->( $lang ) )
	 ->date( $self->choose->{random_time}->() );
}

1;
