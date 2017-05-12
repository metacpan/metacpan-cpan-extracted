# $Id: Fodder2.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
#     global test Fodder...

package Myco::Test::Fodder2;

use strict;
use warnings;

use base qw(Test::Unit::TestCase);

use Myco;

# Generate stack backtrace on exception if asked
$SIG{__DIE__} = \&Carp::confess if ($ENV{MYCO_TESTCONFESS});

### Reusable Test Scenerios

sub scenerio_PersonInCohort {
    my $self = shift;
    my $p = Myco::Person->create(first => "Joe", last => "Cool");
    my $c = Myco::Cohort->create(cohortid => "FOO53");
    push @{ $self->{erase_targets} }, $p, $c;
    return ($p, $c, $c->add_member($p, $c));
}

sub scenerio_PersonInProgram {
    my $self = shift;
    my $p = Myco::Person->create(first => "Joe", last => "Cool");
    my $ap = Myco::Admissions::Process->create(person => $p);
    my $pgm = Myco::Program->create(name => "BSBA");
    push @{ $self->{erase_targets} }, $p, $pgm;
    return ($p, $pgm, $pgm->enroll($p));
}

sub scenerio_AdmissionsReqTest {
    my $test = shift;

    my $p = Myco::Person->create(first => "Joe", last => "Cool",
				 language => 'English',
				 citizenship => 'USA');
    my $prog = Myco::Program->new(name => 'BS of BasketWeaving',
			     admission_reqs_classname => 'LEAD');
    $prog->save;

    my $ap = Myco::Admissions::Process->new(person => $p,
					    stage => 1,
					    program => $prog);
    $ap->save;
    my $reqeval = Myco::Admissions::ReqEvaluation->
                                      create(name => 'language',
					     requirements_classname => 'LEAD');
    push @{ $test->{erase_targets} }, $p, $prog, $reqeval;
    return ($p, $ap, $prog, $reqeval);

}


### Fixture Handling
# Override at will in test or testtemplate classes

sub init_fixture {
    my $self = shift()->SUPER::new(@_);
    $self->_config_fixture;
    return $self;
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
    unless (defined Myco->storage) {
	my $db = $ENV{PGDATABASE} || getpwuid $>;
	my $user = $ENV{PGUSER} || getpwuid $>;
	Myco->db_connect("dbi:Pg:dbname=$db", $user, '');
    }
}

sub _help_set_up {}

sub _help_tear_down {
    while (my $obj = shift @{ $_[0]->{erase_targets} }) {
	Myco->erase($obj);
    }
}

sub _destroy_fixture {
}

1;
