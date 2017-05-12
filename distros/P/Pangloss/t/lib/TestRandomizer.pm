package TestRandomizer;

use strict;
use warnings;

use Error qw( :try );
use Data::Random qw( rand_words rand_chars rand_set );
use TestWordList;

use Pangloss::Users;
use Pangloss::Terms;
use Pangloss::Concepts;
use Pangloss::Languages;
use Pangloss::Categories;

use base      qw( Pangloss::Object );
use accessors qw( app langs cats users concepts terms );

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
# Instance vars

# aliases
sub application { shift->app( @_ )   }
sub languages   { shift->langs( @_ ) }
sub categories  { shift->cats( @_ )  }

#------------------------------------------------------------------------------
# Model Creator

# guaranteed to have 1 admin user
sub create_random_model {
    my $self = shift;
    my %num  = @_;

    $self->emit( "creating random model..." );
    $self->create_admin_user
         ->create_random_languages( $num{languages} )
         ->create_random_categories( $num{categories} )
	 ->create_random_users( $num{users}, $num{translators}, $num{proofreaders} )
	 ->emit( "done." );

    return $self;
}

#------------------------------------------------------------------------------
# Random Collection Creators

sub create_random_languages {
    my $self  = shift;
    my $num   = shift;
    my $langs = $self->langs;
    $self->emit( "creating $num random languages..." );
    for (1 .. $num) {
	$self->create_random_language;
    }
    return $self;
}

sub create_random_categories {
    my $self = shift;
    my $num  = shift;
    my $cats = $self->cats;
    $self->emit( "creating $num random categories..." );
    for (1 .. $num) {
	$self->create_random_category;
    }
    return $self;
}

sub create_random_users {
    my $self = shift;
    my $num  = shift;
    my $xlators  = shift || 0;
    my $proofers = shift || 0;

    $self->emit( "creating $num random users ($xlators translators, $proofers proofreaders)..." );

    for (1 .. $num) {
	my %args;
	if ($xlators) {
	    $args{translator} = 1;
	    $xlators--;
	} elsif ($proofers) {
	    $args{proofreader} = 1;
	    $proofers--;
	}
	$self->create_random_user( %args );
    }

    return $self;
}

sub create_admin_user {
    my $self = shift;

    return if $self->users->exists( 'admin' );

    $self->emit( "creating admin user..." );

    my $user = Pangloss::User->new
	->id('admin')
	->name('admin user')
	->creator('admin')
	->date( random_time() );

    $user->privileges->admin(1);

    $self->users->add( $user ); # die on error

    return $self;
}

#------------------------------------------------------------------------------
# Random Business Object Creators

sub create_random_language {
    my $self = shift;

    my $lang = Pangloss::Language->new
      ->iso_code( join '', rand_chars( size => 2, set => 'loweralpha' ) )
      ->name( rand_name(3) )
      ->creator( 'admin' )
      ->date( random_time() );

    try {
	$self->langs->add( $lang );
    } catch Error with {
	warn "error adding language: " . $lang->key . " " . shift();
    };

    return $lang;
}

sub create_random_category {
    my $self = shift;

    my $cat = Pangloss::Category->new
      ->name( rand_name(4) )
      ->creator( $self->choose_random_creator )
      ->date( random_time() );

    try {
	$self->cats->add( $cat );
    } catch Error with {
	warn "error adding category: " . $cat->key . " " . shift();
    };

    return $cat;
}

sub create_random_concept {
    my $self = shift;

    my $concept = Pangloss::Concept->new
      ->category( $self->choose_random_category )
      ->name( rand_name(5) )
      ->creator( $self->choose_random_creator )
      ->date( random_time() );

    try {
	$self->concepts->add( $concept );
    } catch Error with {
	warn "error adding concept: " . $concept->key . " " . shift();
    };

    return $concept;
}

sub create_random_status {
    my $self = shift;
    my $lang = shift;

    my $status = Pangloss::Term::Status->new
      ->code( $self->choose_random_status_code )
      ->creator( $self->choose_random_proofreader( $lang ) )
      ->date( random_time() );

    return $status;
}

sub create_random_user {
    my $self = shift;
    my %args = @_;

    my $user = Pangloss::User->new
      ->id( rand_words )
      ->name( rand_name(3) )
      ->creator( 'admin')
      ->date( random_time() );

    if ($args{translator}) {
	my @langs = $self->choose_random_languages;
	$user->privileges->add_translate_languages( @langs);
    }

    if ($args{proofreader}) {
	my @langs = $self->choose_random_languages;
	$user->privileges->add_proofread_languages( @langs );
    }

    try {
	$self->users->add( $user );
    } catch Error with {
	warn "error adding user: " . $user->key . " " . shift();
	return;
    };

    return $user;
}

sub create_random_translator {
    my $self  = shift;
    my @langs = @_;
    my $user  = $self->create_random_user;
    $user->privileges->add_translate_languages( @langs );
    return $user;
}

sub create_random_proofreader {
    my $self  = shift;
    my @langs = @_;
    my $user  = $self->create_random_user;
    $user->privileges->add_proofread_languages( @langs );
    return $user;
}

#------------------------------------------------------------------------------
# Random Choosers

sub choose_random_language {
    my $self = shift;
    my @codes = $self->langs->keys;
    return $codes[ int rand @codes ];
}

sub choose_random_languages {
    my $self = shift;
    return rand_set( set => [ $self->langs->keys ] );
}

sub choose_random_status_code {
    my $self  = shift;
    my @codes = values %{ Pangloss::Term::Status->status_codes };
    return $codes[ int rand @codes ];
}

sub choose_random_creator {
    my $self = shift;
    my $iter = $self->random_user_iterator;
    while (my $user = $iter->()) {
	# lets say only admins can create for now...
	return $user->key if $user->is_admin;
    }
    return 'admin';
}

sub choose_random_translator {
    my $self = shift;
    my @lang = shift;
    my $iter = $self->random_user_iterator;
    while (my $user = $iter->()) {
	return $user->key if $user->not_admin && $user->can_translate( @lang );
    }
    # that didn't work - so create one?
    if (@lang) {
	my $user = $self->create_random_translator( @lang );
	return $user->key if $user;
    }
    return 'admin';
}

sub choose_random_proofreader {
    my $self = shift;
    my @lang = shift;
    my $iter = $self->random_user_iterator;
    while (my $user = $iter->()) {
	return $user->key if $user->not_admin && $user->can_proofread( @lang );
    }
    # that didn't work - so create one?
    if (@lang) {
	my $user = $self->create_random_proofreader( @lang );
	return $user->key if $user;
    }
    return 'admin';
}

sub choose_random_category {
    my $self = shift;
    my $iter = $self->random_category_iterator;
    while (my $cat = $iter->()) {
	return $cat->key;
    }
    return undef;
}

sub choose_random_concept {
    my $self = shift;
    my $iter = $self->random_concept_iterator;
    while (my $cat = $iter->()) {
	return $cat->key;
    }
    return undef;
}

#------------------------------------------------------------------------------
# Random Iterators

sub random_collection_iterator {
    my $self = shift;
    my $type = shift;
    my @keys = $self->$type->keys;
    return sub {
	return unless @keys;
	my $idx = int rand(@keys);
	my $key = splice( @keys, $idx, 1 );
	#warn "randomly getting [$key] from $type\n";
	return $self->$type->get($key);
    };
}

sub random_user_iterator {
    return shift->random_collection_iterator( 'users' );
}

sub random_category_iterator {
    return shift->random_collection_iterator( 'cats' );
}

sub random_concept_iterator {
    return shift->random_collection_iterator( 'concepts' );
}


#------------------------------------------------------------------------------
# Random Utils

sub rand_name {
    my $thing = shift;
    my $size  = $thing unless ref($thing);
    $size   ||= shift || 2;
    join ' ', rand_words( size => int rand($size)+1 );
}

sub random_time {
    my $thing = shift;
    return int rand(time) + 1;
}


1;
