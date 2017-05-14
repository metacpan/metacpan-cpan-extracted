package Myco::Query::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
###############################################################################

=head1 NAME

Myco::Query::Test -

unit tests for features of Myco::Query

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Query::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Query::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Query.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Query;
use Myco::Query::Part::Clause;
use Myco::Query::Part::Filter;
use Myco::Entity::Meta::Attribute;
use Myco::Entity::Meta::Attribute::UI;
use strict;
use warnings;
use Data::Dumper;

### Class Data

# This class tests features of:
use constant FILTER => 'Myco::Query::Part::Filter';
use constant CLAUSE => 'Myco::Query::Part::Clause';
use constant ATTR_META => 'Myco::Entity::Meta::Attribute';
use constant UI_META => 'Myco::Entity::Meta::Attribute::UI';
use constant ENTITY => 'Myco::Entity::SampleEntity';
use constant ADDRESS => 'Myco::Entity::SampleEntityAddress';
my $class = 'Myco::Query';

# It may be helpful to number tests... use myco-testrun's -d flag to view
#   test-specific debug output (see example tests, myco-testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   simple_accessor => 'name',

   skip_persistence => 0,     # skip persistence tests?  (defaults to false)
   standalone => 0,           # don't compile Myco entity classes

   defaults =>
   {
    name => 'name',
   },
  );

##############################################################################
# Hooks into Myco test framework.
##############################################################################

sub new {
    # create fixture object and handle related needs (esp. DB connection)
    shift->init_fixture(test_unit_params => [@_],
			myco_params => \%test_parameters,
			class => $class);
}

sub set_up {
    my $test = shift;
    $test->help_set_up(@_);
}

sub tear_down {
    my $test = shift;
    $test->help_tear_down(@_);
}


##############################################################################
###
### Unit Tests for Myco::Query
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

sub test_get_closure {
    my $test = shift;
	
    my $q = $class->new( name => 'default',
                         description => 'the default query',
                         remotes => { '$sample_base_entity_' => ENTITY },
                         result_remote => '$sample_base_entity_',
                         params => {
                                    chk => ['$sample_base_entity_', 'chicken']
                                   },
                         filter =>
                         { parts => [ { remote => '$sample_base_entity_',
                                        attr => 'chicken',
                                        oper => '==',
                                        param => '$params{chk}' }
                                    ]
                         },
                       );

    my $widget = $q->get_closure( 'chk' );

    $test->assert( $widget =~ /name="chk".+/,
                   "CGI widget was generated using widget spec" );

}

########################
# Tests how ::Query handles clauses with corresponding params that are optional
sub test_optional_params {
    my $test = shift;

    return if $test_parameters{skip_persistence};
	
    # Pre-destroy from previous failed tests
    Myco->destroy( Myco->select(ENTITY) );

    my $e_id = ENTITY->new(name => 'Da Man', fish => 'Trout')->save;

    my $clause1 = CLAUSE->new( remote => '$e_',
                               attr => 'name',
                               oper => 'eq',
                               param => 'name',
                               part_join_oper => '&' );
    my $clause2 = CLAUSE->new( remote => '$e_',
                               attr => 'fish',
                               oper => 'eq',
                               param => 'fish' );
    my $q = Myco::Query->new
      ( name => 'dummy',
        remotes => { '$e_' => ENTITY, },
        result_remote => '$e_' ,
        params => {
                   # 1 at the end means optional
                   name => [ qw($e_ name) ] ,
                   fish => [ qw($e_ fish 1) ] ,
                  },
        filter => { parts => [ $clause1, $clause2 ] }
      );

    my ($myguy) = eval { $q->run_query( name => 'Da Man' ) };
    $test->assert( ! $@, "no error encountered, or was there...$@" );
    $test->assert( $myguy->id == $e_id,
		   'query ignored the clause involving my optional param' );

    # Okay - add another optional param
    $q->set_params(
                   { %{$q->get_params},
                     chk => [ qw($e_ chicken 1) ] }
                  );
    # And do a Re-Run - like that dude in that 70s blaxploitation tv comedy
    my ($sameguy) = eval { $q->run_query( name => 'Da Man' ) };
    $test->assert( $sameguy->id == $myguy->id,
                   'now he\'s ignoring the chicken!');

    # Try actually passing in the chicken
    $sameguy->set_chicken(1);
    $sameguy->save;
    my ($sameguyagain) = eval {
        $q->run_query( name => 'Da Man', chk => 1 );
    };
    $test->assert( $sameguyagain->id == $sameguy->id,
                   'now he\'s NOT ignoring sameguy\'s chicken!');

    # Now try a query w/an optional ref param
    $q->set_params(
                   {
                    %{$q->get_params},
                    samp_ent => [ qw($e_ another_sample_entity) ],
                   }
                  );
    my $another_sample_entity = ENTITY->new
                                 ( another_sample_entity => $sameguyagain );
    $sameguyagain->set_another_sample_entity($another_sample_entity);
    $sameguyagain->save;

    # Run it without required '$another_sample_entity' - catch exception.
    eval {
        $q->run_query( name => 'Da Man', chk => 1 );
    };
    $test->assert( $@ && $@ eq 'Missing required query parameters',
                   "Caught exception: $@" );

    # Add a new clause to chew upon 'another_sample_entity'
    $q->get_filter->add_part
      ( CLAUSE->new( remote => '$e_',
                     attr => 'another_sample_entity',
                     oper => '==',
                     param => 'samp_ent' )
      );

    # Remember to add a join oper to the previous clause
    $clause2->set_part_join_oper('&');

    # Now run it with the new ref param
    my ($sameguyyetagain) = eval {
        $q->run_query( name => 'Da Man',
                       chk => 1,
                       samp_ent => $another_sample_entity
                     );
    };
    $test->assert( $sameguyyetagain->id == $sameguyagain->id,
                   'got him again');

    Myco->destroy( Myco->select(ENTITY), Myco->select('Myco::Query') );
}

sub test_match_oper {
    my $test = shift;

	return if $test_parameters{skip_persistence};
	
    # Pre-destroy from previous failed tests
    Myco->destroy( Myco->select(ENTITY) );

    my $e_id = ENTITY->new(first => 'Thisizda', last => 'Da Man')->save;
    my $q = Myco::Query->new
      ( name => 'dummy',
        remotes => { '$e_' => ENTITY, },
        result_remote => '$e_' ,
        params => {
                   # 1 at the end means optional
                   first => [ qw($e_ first 1) ],
                   last => [ qw($e_ last) ],
                  },
        filter => { parts => [ { remote => '$e_',
                                 attr => 'first',
                                 oper => 'match',
                                 param => [ 'first', '~*', '^{}.*' ],
                                 part_join_oper => '&' },
                               { remote => '$e_',
                                 attr => 'last',
                                 oper => 'match',
                                 param => [ 'last', '~*', '.*{}' ] }
                             ] }
      );
    my ($dude) = $q->run_query( first => 'Thisiz', last => 'Man' );
    $test->assert( $dude->id == $e_id, 'got back dude with match query' );

    Myco->destroy( Myco->select(ENTITY), Myco->select('Myco::Query') );

}

# Tests logic involved in using a remote as the right part of a filter
# statement - i.e. its not passed as a param. Further distinction is needed 
# between right operands and params, which ain't always the same

sub test_remote_as_param_or_I_mean_as_right_operand_yeah_thats_the_ticket {
    my $test = shift;

	return if $test_parameters{skip_persistence};
	
    # pre-cleanup
    my $e_ = Myco->remote(ENTITY);
    Myco->destroy( Myco->select($e_, $e_->{last} eq 'Millionaire'),
                   Myco->select('Myco::Query') );

    # This tests a detailed query that uses a remote object set comparison
    # as a param intead of an object attribute as parameter.

    my $addr = ADDRESS->new( address_key => 'home', city => 'Quincy',
                             state => 'MA', zip => '02170',
                             street => '23 East Elm Ave' );
    $addr->save;

    my $e_id = ENTITY->new( first => 'Joe', last => 'Millionaire',
                            address => $addr )->save;

    my $q = $class->new( name => 'detailed_search',
                         remotes => { '$e_' => ENTITY,
                                      '$addr_' => ADDRESS },
                         result_remote => '$e_',
                         params => {
                                    first_initial => [ qw($e_ first) ],
                                    last_initial => [ qw($e_ first) ],
                                    zip => [ qw($addr_ zip 1) ],
                                    city => [ qw($addr_ city 1) ],
                                    state => [ qw($addr_ state 1) ],
                                   },
                         filter =>
                         { parts =>
                           [ { remote => '$e_',
                               attr => 'first',
                               oper => 'match',
                               param => [ 'first_initial',
                                          '~*', '^{}.*'],
                               part_join_oper => '&' },
                             { remote => '$e_',
                               attr => 'last',
                               oper => 'match',
                               param => [ 'last_initial',
                                          '~*', '^{}.*'],
                               part_join_oper => '&' },
                             { remote => '$addr_',
                               attr => 'city',
                               oper => 'eq',
                               param => 'city',
                               part_join_oper => '&' },
                             { remote => '$addr_',
                               attr => 'state',
                               oper => 'eq',
                               param => 'state',
                               part_join_oper => '&' },
                             { remote => '$addr_',
                               attr => 'zip',
                               oper => 'eq',
                               param => 'zip',
                               part_join_oper => '&' },
                             { remote => '$e_',
                               attr => 'address',
                               oper => '==',
                               param => '$addr_' }
                           ]
                         }
                       );

    # Okay - first thing is to check if compiling one of the
    # clauses with 'remote' as param outside of the query's context produces
    # bad results. It should, since ::Clause requires the remotes hash to be
    # passed to it from ::Query to determine this.

    my $filter = $q->get_filter;
    my $filter_parts = $filter->get_parts;
    my $fifth_filter_part = $filter_parts->[5];
    my $clause_string;
    eval { $clause_string = $fifth_filter_part->get_clause };
    $test->assert( $@ && $@ =~ /param looks like a remote/, $@ );

    my $guy;
    ($guy) = $q->run_query(first_initial => 'Jo',
			   last_initial => 'Mi',
			   zip => '02170',
			   city => 'Quincy',
			   state => 'MA');
    $test->assert( $guy->id == $e_id, 'detailed query worked!' );

    # Now test how this query handles optional parameters
    ($guy) = $q->run_query( first_initial => 'Jo',
                            last_initial => 'Mi',
                            city => 'Quincy' );
    $test->assert( $guy->id == $e_id,
                   'detailed query worked w/optional params!' );

    # Now try with several similar objects to see how set comparisons work
    for my $state ( qw(NY LA CA RI RI) ) {
        my $addr = ADDRESS->new( address_key => 'home',
                                 city => 'Quincy',
                                 state => $state,
                                 zip => '02170',
                                 street => '23 East Elm Ave' );
        $addr->save;
        ENTITY->new( first => 'Joe',
                     last => 'Millionaire',
                     address => $addr )->save;
    }

    # Should be 6 Joe Millionaires in there from different states
    my @guys = $q->run_query( first_initial => 'Jo', last_initial => 'Mi' );

    # cleanup
    Myco->destroy( Myco->select($e_, $e_->{last} eq 'Millionaire'),
                   Myco->select('Myco::Query') );
}

1;
__END__
