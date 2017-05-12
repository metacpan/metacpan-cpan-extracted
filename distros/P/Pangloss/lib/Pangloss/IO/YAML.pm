package Pangloss::IO::YAML;

use strict;
use warnings;

use YAML qw( LoadFile Dump );
use Error qw( :try );
use File::Spec;
use Data::Random qw( rand_words rand_chars );

use Pangloss::Users;
use Pangloss::Terms;
use Pangloss::Concepts;
use Pangloss::Languages;
use Pangloss::Categories;

use base      qw( Pangloss::Object );
use accessors qw( languages categories users concepts terms );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub init {
    my $self = shift;

    $self->languages( Pangloss::Languages->new )
         ->categories( Pangloss::Categories->new )
	 ->users( Pangloss::Users->new )
	 ->concepts( Pangloss::Concepts->new )
	 ->terms( Pangloss::Terms->new );

    return $self;
}

#------------------------------------------------------------------------------
# Save/Load

sub save {
    my $self = shift;
    die $self->class . "->save() not yet implemented!";
}

sub load {
    my $self = shift;
    my $file = shift || return;
    $self->{yaml_db} = LoadFile( $file );
    return $self->parse_db;
}

#------------------------------------------------------------------------------
# YAML DB parser

sub parse_db {
    my $self = shift;
    my $db   = shift || $self->{yaml_db};

    $self->emit( "parsing yaml database..." );

    my $src_lang = $self->get_or_create_source_lang;

    foreach my $concept (keys %$db) {
	$self->emit( "parsing concept '$concept'..." );
	my $c  = $self->get_or_create_concept( $concept );
	my $ct = $self->create_term( $c->key, $concept, $src_lang->key )
	  unless exists $db->{$concept}->{$src_lang->key};
	foreach my $lang (keys %{ $db->{$concept} }) {
	    my $term = $db->{$concept}->{$lang};
	    my $l    = $self->get_or_create_lang( $lang );
	    my $t    = $self->create_term( $c->key, $term, $l->key );
	}
    }

    return $self;
}

sub get_or_create_source_lang {
    my $self = shift;

    # we assume the db was written in english...
    # prolly a bad assumption, but it can be changed down the line.
    return $self->get_or_create_lang( 'en', 'English' );
}

sub get_or_create_lang {
    my $self = shift;
    my $key  = shift;
    my $name = shift;

    return $self->languages->get( $key )
      if $self->languages->exists( $key );

    my $l = Pangloss::Language->new
        ->iso_code( $key )
	->creator( 'admin' )
	->name( $name )
	->date( time );

    $self->languages->add( $l ); # die on error

    return $l;
}

sub get_or_create_concept {
    my $self    = shift;
    my $concept = shift;

    return $self->concepts->get( $concept )
      if $self->concepts->exists( $concept );

    my $c = Pangloss::Concept->new
          ->name( $concept )
	  ->creator( 'admin' )
	  ->date( time );

    $self->concepts->add( $c ); # die on error

    return $c;
}

sub create_term {
    my $self    = shift;
    my $concept = shift;
    my $name    = shift;
    my $lang    = shift;

    my $ct = Pangloss::Term->new
	  ->language( $lang )
	  ->concept( $concept )
	  ->name( $name )
	  ->creator( 'admin' )
	  ->date( time );

    try {
	$self->terms->add( $ct );
	return $ct;
    } catch Error with {
	warn 'error creating "' . $ct->key . '" - ' . shift() . "\n";
    };

    return;
}

1;
