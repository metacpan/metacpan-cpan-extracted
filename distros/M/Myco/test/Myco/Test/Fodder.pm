# $Id: Fodder.pm,v 1.1.1.1 2005/12/09 18:08:47 sommerb Exp $
#
#     global test Fodder... and test framework support

package Myco::Test::Fodder;

use strict;
use warnings;
use Test::Unit::Assertion::Boolean;
use Carp;

use base qw(Test::Unit::TestCase);

### Class data ###
my $_dbi;   # DBI connection object

#use Myco;

# Generate stack backtrace on exception if asked
$SIG{__DIE__} = \&Carp::confess if ($ENV{MYCO_TESTCONFESS});


###
### Test Framework Support
###

### Fixture Handling
# Override at will in test class or EntityTest base class

sub init_fixture {
    my $referent = shift;
    my %params = @_ > 0 && (@_ % 2 == 0) ? @_ : ();
    my $test = $referent->SUPER::new(exists $params{test_unit_params}
				     ? @{ $params{test_unit_params} } : @_);
    $test->_config_fixture(@_);
    return $test;
}

sub new_testable_entity {
    my $test = shift;
    my $class = $test->get_class;
    my ($obj);
    # instantiate entity obj, using default attribs from test class, if any
    if (my $new_params = $test->get_params->{defaults}) {
        # Change a hash ref to an arrayref.
        $new_params = [ map { [ $_ => $new_params->{$_} ]}
                        sort keys %$new_params ]
          if UNIVERSAL::isa($new_params, 'HASH');

        # Process parameters.
        my %params = @_;
        my @params;
        foreach (@$new_params) {
            if (exists $params{$_->[0]}) {
                push @params, $_->[0], delete $params{$_->[0]}
            } elsif (UNIVERSAL::isa($_->[1], 'CODE')) {
                push @params, $_->[0], $_->[1]->($test);
            } else {
                push @params, @$_;
            }
        }

        # Construct the new object.
	$obj = $class->new(@params, %params);
    } else {
	$obj = $class->new(@_);
    }
    return $obj;
}

sub db_out {
    my ($test, $msg) = @_;
    print "\nDEBUG(".$test->get_name."): \n".$msg."\n" if $test->get_gen_db_out;
}


sub _accessor {
    my ($test, $key, $val) = @_;
    $test->{myco}{$key} = $val if defined $val;
    return $test->{myco}{$key};
}

sub get_params { shift->_accessor('params') }
sub set_params { shift->_accessor('params', @_) }
sub get_class { shift->_accessor('class') }
sub set_class { shift->_accessor('class', @_) }
sub get_type_persistence { shift->_accessor('type_persistence') }
sub set_type_persistence { shift->_accessor('type_persistence', @_) }
sub get_db_level { shift->_accessor('db_level') }
sub set_db_level { shift->_accessor('db_level', @_) }
sub get_gen_db_out { shift->_accessor('gen_db_out') }
sub set_gen_db_out { shift->_accessor('gen_db_out', @_) }
sub get_name { shift->_accessor('name') }
sub set_name { shift->_accessor('name', @_) }

sub get_should_skip {
    # this is simplistic... could be expanded if need be
    my $test = shift;
    my $skip;
    return 1 if ( defined($skip = $test->_accessor('should_skip'))
		  and $skip eq 'persistence'
		  and $test->get_type_persistence);
    0;
}
sub should_skip { shift->get_should_skip }
sub set_should_skip { shift->_accessor('should_skip', @_) }

sub set_destroy_targets { shift->_accessor('erase_targets', @_) }
sub get_destroy_targets { shift->_accessor('erase_targets') }
sub destroy_upon_cleanup {
    my $test = shift;
    my $targets = $test->get_destroy_targets
                    || $test->set_destroy_targets( [] );
    push @$targets, @_;
}

sub help_set_up {
    $_[0]->_help_set_up;
}

sub help_tear_down {
    $_[0]->_help_tear_down;
}

sub DESTROY {
    $_[0]->_destroy_fixture;
}


## Default _do_the_work_ methods
sub _config_fixture {
    my $test = shift;
    my %cfg_params = @_ > 0 && (@_ % 2 == 0) ? @_ : ();
    if (exists $cfg_params{myco_params}) {
	$test->set_params( $cfg_params{myco_params} );
    }
    $test->set_params( {} ) unless defined $test->get_params;
    my $tparams = $test->get_params;

    my $testname = $test->{'Test::Unit::TestCase_name'};

    $test->set_name($testname);
    $test->set_class( $cfg_params{class} ) if $cfg_params{class};

    if ($ENV{MYCO_TESTMEM}) {
	$test->set_should_skip('persistence');
	# Legacy - remove after converting all test subs that rely on it
	$test->{skipTest} = 1;
	return;
    }

    if (defined $ENV{MYCO_TEST_DEBUG}) {{
	my $db_level = $ENV{MYCO_TEST_DEBUG};
	$test->set_db_level($db_level);
        last unless $testname;
	my ($testnum) = $testname =~ /^test_(\d+)[^\s:]+/;
	last unless defined $testnum;
	$test->set_gen_db_out(1)
	  if $db_level == $testnum || $db_level < 0;
    }}

    # Run with full Myco object system compiled?
    if ($tparams->{standalone}) {
        die "test param 'skip_persistence' must be set "
            ."if param 'standalone' is set\n" unless $tparams->{skip_persistence};
    } else {
	eval "require Myco"
	  or die "could not load class Myco: $@";
	
	# Set up connection to persistence storage
	unless ($tparams->{skip_persistence}) {

	       use Myco::Config qw(:database);
           my $user = DB_USER;
           my $pw = DB_PASSWORD;
           my $dsn = DB_DSN;

            $test->{myco}{data_source} = $dsn;
            $test->{myco}{username} = $user;
            $test->{myco}{password} = $pw;

            unless (defined Myco->storage) {
                $_dbi = DBI->connect($dsn, $user, $pw);
                unless ($_dbi) {
                    die "Couldn't establish DB connection\n"
                      ."   dsn:  $dsn\n"
                      ."   user:  $user\n"
                      ."   pass:  $pw\n"
                      ."  DBI error:  ". ($DBI::errstr ? $DBI::errstr : '')
                      ."\n";
                }
                Myco->db_connect( $dsn, $user, $pw, { dbh => $_dbi } );
            }
	}
    }
}

sub _help_set_up {
    my $test = shift;
    $test->set_should_skip('persistence')
      if $test->get_params->{skip_persistence};
}

sub _help_tear_down {
    my $test = shift;

    ## Destroy targetted objects
#    if ($test->get_type_persistence) {
	# Legacy - merging in anything in $test->{erase_targets}
	$test->destroy_upon_cleanup(@{ $test->{erase_targets} })
	  if $test->{erase_targets};

	my $targets;
	return unless ($targets = $test->get_destroy_targets);
	for my $obj (@$targets) {
	    $obj = $obj->($test) if ref $obj eq 'CODE';
	    Myco->destroy($obj) if ref $obj;

	}
#    }
}

sub _destroy_fixture {
}


1;
