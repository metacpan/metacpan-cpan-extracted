# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;
use strict;
use diagnostics;

BEGIN { plan tests => 85 };

use SQL::Snippet::ExampleRepository;

use DBI;
my $dbh = DBI->connect('dbi:Sponge:');

use Term::Interact;
my $ui = Term::Interact->new;

ok(1); # Preliminaries are now out of the way...

### This is the order we'll follow for testing #############################
# snippet methods
# pop methods (1/1):
#   snippet->pop context
# pop_name methods (1/1):
#   snippet->pop->pop_name context
# parm methods (1/3):
#   snippet->parm context
# parm methods (2/3):
#   snippet->pop->pop_name->parm context
# parm_name methods (1/3):
#   snippet->parm->parm_name context
# parm_name methods (2/3):
#   snippet->pop->pop_name->parm->parm_name context
# lim methods (1/2):
#   snippet->shared_lim context
# lim methods (2/2):
#   snippet->pop->pop_name->lim context
# lim_name methods (1/2):
#   snippet->shared_lim->lim_name context
# lim_name methods (2/2):
#   snippet->pop->pop_name->lim->lim_name context
# parm methods (3/3):
#   snippet->pop->pop_name->lim->lim_name->parm context
# parm_name methods (3/3):
#   snippet->pop->pop_name->lim->lim_name->parm->parm_name context
# complex methods
# full-on autoinstantiation tests
############################################################################


### snippet methods

    # Test the new method
    my $snippet = SQL::Snippet::ExampleRepository->new();
    ok( $snippet ? 1 : 0 );

    # make sure snippet has no parm, shared_lim, or pop snippets
    # built in at creation
    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the interact default
    ok( $snippet->interact ? 1 : 0 );

    # Test the interact method
    $snippet->interact( 0 );
    ok( $snippet->interact ? 0 : 1 );
    $snippet->interact( 1 );
    ok( $snippet->interact ? 1 : 0 );

    # Test dbh method
    $snippet->dbh( $dbh );
    ok( $snippet->dbh eq $dbh ? 1 : 0 );

    # Test the sql_syntax default
    ok( $snippet->sql_syntax eq 'oracle' ? 1 : 0 );

    # Test the sql_syntax method
    $snippet->sql_syntax( 'postgresql' );
    ok( $snippet->sql_syntax eq 'postgresql' ? 1 : 0 );
    $snippet->sql_syntax( 'oracle' );
    ok( $snippet->sql_syntax eq 'oracle' ? 1 : 0 );

    # Test the ui method
    $snippet->ui( $ui );
    ok( $snippet->ui eq $ui ? 1 : 0 );

    # Test the get_shared_lim_notes method
    # (see this test under the "Comprehensive tests" section)


### pop methods (1/1):
###   snippet->pop context

    # Test the pop->new method
    #   and
    # Test the pop->list method
    $snippet->pop->new( 'individual' );
    ok( grep 'individual' => $snippet->pop->list ? 1 : 0 );

    # Test the pop->remove method
    $snippet->pop->remove( 'individual' );
    ok( grep 'individual' => $snippet->pop->list ? 0 : 1 );

    # for clean testing, make sure the snippet has been cleansed of
    # any parm, shared_lim, or pop snippets
    ok( confirm_clean($snippet) ? 1 : 0 );


### pop_name methods (1/1):
###   snippet->pop->pop_name context

    # UNIMPLEMENTED
    # # Test the pop->pop_name->create_select method

    # Test the pop->pop_name->select method
    $snippet->pop->new( 'recruit' );
    $snippet->pop->recruit->select( 'SELECT count (*)' );
    ok( $snippet->pop->recruit->select eq 'SELECT count (*)' ? 1 : 0 );

    # Test the pop->pop_name->query method
    $snippet->pop->new( 'alum' );
    $snippet->pop->alum->select( 'SELECT count(*)' );
    ok(
        $snippet->pop->alum->query
        eq
        join("\n", 'SELECT count(*)', 'FROM applicant', "WHERE app_status_code = 'A'")
        ? 1
        : 0
    );

    $snippet->pop->remove( 'alum' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the pop->pop_name->selectable method
    # TODO: add testing for more complex syntax after addign syntax enforcement to
    #       SQL::Snippet source.
    my $selectable = $snippet->pop->recruit->selectable;
       # did it default correctly (according to values in the ExampleRepository)?
    ok(
        scalar @$selectable == 2
          and
        grep 'person_id' => @$selectable
          and
        grep 'referral_id' => @$selectable
        ? 1
        : 0
    );
    $snippet->pop->recruit->selectable( ['foo'] );
    $selectable = $snippet->pop->recruit->selectable;
    ok(
        scalar @$selectable == 1
          and
        $selectable->[0] eq 'foo'
        ? 1
        : 0
    );
    $snippet->pop->remove( 'recruit' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test pop->pop_name->prompt_parm method
    $snippet->pop->new( 'offer' );
    my $prompt_parm = $snippet->pop->offer->prompt_parm;
       # did it default correctly (according to values in the ExampleRepository)?
    ok(
        scalar @$prompt_parm == 2
          and
        grep 'offer_dec_codes' => @$prompt_parm
          and
        grep 'offer_excld_dec_codes' => @$prompt_parm
        ? 1
        : 0
    );
    $snippet->pop->offer->prompt_parm( ['foo'] );
    $prompt_parm = $snippet->pop->offer->prompt_parm;
    ok(
        scalar @$prompt_parm == 1
          and
        $prompt_parm->[0] eq 'foo'
        ? 1
        : 0
    );
    $snippet->pop->remove( 'offer' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test pop->pop_name->table method
    $snippet->pop->new( 'member' );
    $snippet->pop->member->select( 'SELECT count(*)' );
    $snippet->pop->member->query;   # table is not filled in until query method is invoked
    ok( $snippet->pop->member->table eq 'applicant' ? 1 : 0 );
    $snippet->pop->member->table( 'foo' );
    ok( $snippet->pop->member->table eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'member' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test pop->pop_name->sql method
    $snippet->pop->new( 'member' );
    $snippet->pop->member->select( 'SELECT count(*)' );
    $snippet->pop->member->query;   # sql is not filled in until query method is invoked
    ok( $snippet->pop->member->sql eq "and app_status_code = 'M'" ? 1 : 0 );
    $snippet->pop->member->sql( 'foo' );
    ok( $snippet->pop->member->sql eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'member' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # UNIMPLEMENTED
    # # Test the pop->pop_name->group_by method

    # UNIMPLEMENTED
    # # Test the pop->pop_name->order_by method

    # UNIMPLEMENTED
    # # Test the pop->pop_name->having method

    # UNIMPLEMENTED
    # # Test the pop->pop_name->desc method


### parm methods (1/3):
###   snippet->parm context

    # Test the pop->new method
    #   and
    # Test the pop->list method
    $snippet->parm->new( 'gender' );
    ok( grep 'gender' => $snippet->parm->list ? 1 : 0 );

    # Test the pop->remove method
    $snippet->parm->remove( 'gender' );
    ok( grep 'gender' => $snippet->parm->list ? 0 : 1 );

    ok( confirm_clean($snippet) ? 1 : 0 );


### parm methods (2/3):
###   snippet->pop->pop_name->parm context

    # Test the pop->new method
    #   and
    # Test the pop->list method
    $snippet->pop->new( 'individual' );
    $snippet->pop->individual->parm->new( 'gender' );
    ok( grep 'gender' => $snippet->pop->individual->parm->list ? 1 : 0 );

    # Test the pop->remove method
    $snippet->pop->individual->parm->remove( 'gender' );
    ok( grep 'gender' => $snippet->pop->individual->parm->list ? 0 : 1 );
    $snippet->pop->remove( 'individual' );

    ok( confirm_clean($snippet) ? 1 : 0 );


### parm_name methods (1/3):
###   snippet->parm->parm_name context

    # Test the parm->parm_name->value method
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( 'foo' );
    ok( $snippet->parm->gender->value eq 'foo' ? 1 : 0 );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # UNIMPLEMENTED
    # # Test the parm->parm_name->label method

    # UNIMPLEMENTED
    # # Test the parm->parm_name->desc method


### parm_name methods (2/3):
###   snippet->pop->pop_name->parm->parm_name context

    # Test the parm->parm_name->value method
    $snippet->pop->new( 'offer' );
    $snippet->pop->offer->parm->new( 'offer_dec_codes' );
    $snippet->pop->offer->parm->offer_dec_codes->value( 'foo' );
    ok( $snippet->pop->offer->parm->offer_dec_codes->value eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'offer' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # UNIMPLEMENTED
    # # Test the parm->parm_name->label method

    # UNIMPLEMENTED
    # # Test the parm->parm_name->desc method


### lim methods (1/2):
###   snippet->shared_lim context

    # Test the lim->new method
    #   and
    # Test the lim->list method
    $snippet->shared_lim->new( 'gender' );
    ok(
        scalar $snippet->shared_lim->list == 1
          and
        grep 'gender', $snippet->shared_lim->list
        ? 1
        : 0
    );

    # Test the lim->remove method
    $snippet->shared_lim->remove( 'gender' );
    ok( scalar $snippet->shared_lim->list == 0 ? 1 :0 );

    ok( confirm_clean($snippet) ? 1 : 0 );


### lim methods (2/2):
###   snippet->pop->pop_name->lim context

    # Test the lim->new method
    #   and
    # Test the lim->list method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );    # creates a very simple snippet, no repository lookup is done
                                                        # to set its attributes.  Only the parms passed to new are used
                                                        # to set attributes.
    ok(
        scalar $snippet->pop->individual->lim->list == 1
          and
        grep 'gender', $snippet->pop->individual->lim->list
        ? 1
        : 0
    );

    # Test the lim->remove method
    $snippet->pop->individual->lim->remove( 'gender' );
    ok( scalar $snippet->pop->individual->lim->list == 0 ? 1 :0 );
    $snippet->pop->remove( 'individual' );

    ok( confirm_clean($snippet) ? 1 : 0 );

### lim_name methods (1/2):
###   snippet->shared_lim->lim_name context

    # Test the lim->lim_name->selectable method
    $snippet->shared_lim->new( 'gender' );
    $snippet->pop->new( 'alum' );
    $snippet->pop->alum->select( 'SELECT count(*)' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','F'] );    # head off any user interaction by specifying this in advance
    $snippet->pop->alum->query;             # the query method causes the lim to be fleshed out
    ok( $snippet->shared_lim->gender->selectable->[0] eq 'gender' ? 1 : 0 );
    $snippet->shared_lim->gender->selectable( ['foo'] );
    ok( $snippet->shared_lim->gender->selectable->[0] eq 'foo' ? 1 : 0 );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender' );
    $snippet->pop->remove( 'alum');

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->prompt_parm method
    $snippet->shared_lim->new( 'gender' );
    $snippet->pop->new( 'alum');
    $snippet->pop->alum->select( 'SELECT count(*)' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','F'] );
    $snippet->pop->alum->query;
    ok( $snippet->shared_lim->gender->prompt_parm->[0] eq 'gender' ? 1 : 0 );
    $snippet->shared_lim->gender->prompt_parm( ['foo'] );
    ok( $snippet->shared_lim->gender->prompt_parm->[0] eq 'foo' ? 1 : 0 );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender' );
    $snippet->pop->remove( 'alum');

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->table method
    $snippet->shared_lim->new( 'gender' );
    $snippet->pop->new( 'alum');
    $snippet->pop->alum->select( 'SELECT count(*)' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','F'] );
    $snippet->pop->alum->query;
    ok( $snippet->shared_lim->gender->table eq 'personal' ? 1 : 0 );
    $snippet->shared_lim->gender->table( 'foo' );
    ok( $snippet->shared_lim->gender->table eq 'foo' ? 1 : 0 );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender' );
    $snippet->pop->remove( 'alum');

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->sql method
    $snippet->shared_lim->new( 'gender' );
    $snippet->pop->new( 'alum');
    $snippet->pop->alum->select( 'SELECT count(*)' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','F'] );
    $snippet->pop->alum->query;
    my $sql = $snippet->shared_lim->gender->sql;
    ok(
        scalar @$sql == 2
          and
        $sql->[0] eq 'and personal.id(+) = applicant.person_id'
          and
        $sql->[1] eq "and (personal.gender in ('U','F') or personal.gender is null)"
        ? 1
        : 0
    );
    $snippet->shared_lim->gender->sql( 'foo' );
    ok( $snippet->shared_lim->gender->sql eq 'foo' ? 1 : 0 );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender' );
    $snippet->pop->remove( 'alum');

    ok( confirm_clean($snippet) ? 1 : 0 );


    # UNIMPLEMENTED
    # # Test the lim->lim_name->desc method

    # Test the lim->lim_name->note method
    $snippet->shared_lim->new( 'gender' );
    $snippet->pop->new( 'alum');
    $snippet->pop->alum->select( 'SELECT count(*)' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','F'] );
    $snippet->pop->alum->query;
    ok( $snippet->shared_lim->gender->note eq "This population limited to Gender(s): 'U','F'" ? 1 : 0 );
    $snippet->shared_lim->gender->note( 'foo' );
    ok( $snippet->shared_lim->gender->note eq 'foo' ? 1 : 0 );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender' );
    $snippet->pop->remove( 'alum');

    ok( confirm_clean($snippet) ? 1 : 0 );


### lim_name methods (2/2):
###   snippet->pop->pop_name->lim->lim_name context

    # Test the lim->lim_name->selectable method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','M'] );
    ok( $snippet->pop->individual->lim->gender->selectable->[0] eq 'gender' ? 1 : 0 );
    $snippet->pop->individual->lim->gender->selectable( ['foo'] );
    ok( $snippet->pop->individual->lim->gender->selectable->[0] eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'individual' );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->prompt_parm method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','M'] );
    ok( $snippet->pop->individual->lim->gender->prompt_parm->[0] eq 'gender' ? 1 : 0 );
    $snippet->pop->individual->lim->gender->prompt_parm( ['foo'] );
    ok( $snippet->pop->individual->lim->gender->prompt_parm->[0] eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'individual' );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->table method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','M'] );
    $snippet->pop->individual->select( 'SELECT count(*)' );
    $snippet->pop->individual->query;
    ok( $snippet->pop->individual->lim->gender->table eq 'personal' ? 1 : 0 );
    $snippet->pop->individual->lim->gender->table( 'foo' );
    ok( $snippet->pop->individual->lim->gender->table eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'individual' );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # Test the lim->lim_name->sql method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','M'] );
    $snippet->pop->individual->select( 'SELECT count(*)' );
    $snippet->pop->individual->query;
    $sql = $snippet->pop->individual->lim->gender->sql;
    ok(
        scalar @$sql == 2
          and
        $sql->[0] eq 'and personal.id(+) = person.id'
          and
        $sql->[1] eq 'and (personal.gender in (\'U\',\'M\') or personal.gender is null)'
        ? 1
        : 0
    );
    $snippet->pop->individual->lim->gender->sql( 'foo' );
    ok( $snippet->pop->individual->lim->gender->sql eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'individual' );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # UNIMPLEMENTED
    # # Test the lim->lim_name->desc method

    # Test the lim->lim_name->note method
    $snippet->pop->new( 'individual');
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( ['U','M'] );
    $snippet->pop->individual->select( 'SELECT count(*)' );
    $snippet->pop->individual->query;
    ok( $snippet->pop->individual->lim->gender->note eq "This population limited to Gender(s): 'U','M'" ? 1 : 0 );
    $snippet->pop->individual->lim->gender->note( 'foo' );
    ok( $snippet->pop->individual->lim->gender->note eq 'foo' ? 1 : 0 );
    $snippet->pop->remove( 'individual' );
    $snippet->parm->remove( 'gender' );

    ok( confirm_clean($snippet) ? 1 : 0 );


### parm methods (3/3):
###   snippet->pop->pop_name->lim->lim_name->parm context

    # Test the pop->new method
    #   and
    # Test the pop->list method
    $snippet->pop->new( 'individual' );
    $snippet->pop->individual->lim->new( 'gender' );
    $snippet->pop->individual->lim->gender->parm->new( 'gender' );
    ok( grep 'gender' => $snippet->pop->individual->lim->gender->parm->list ? 1 : 0 );

    # Test the pop->remove method
    $snippet->pop->individual->lim->gender->parm->remove( 'gender' );
    ok( grep 'gender' => $snippet->pop->individual->lim->gender->parm->list ? 0 : 1 );
    $snippet->pop->remove( 'individual' );

    ok( confirm_clean($snippet) ? 1 : 0 );


### parm_name methods (3/3):
###   snippet->pop->pop_name->lim->lim_name->parm->parm_name context

    # Test the parm->parm_name->value method
    $snippet->pop->new( 'offer' );
    $snippet->pop->offer->lim->new( 'gender' );
    $snippet->pop->offer->lim->gender->parm->new( 'foo' );
    $snippet->pop->offer->lim->gender->parm->foo->value( 'bar' );
    ok( $snippet->pop->offer->lim->gender->parm->foo->value eq 'bar' ? 1 : 0 );
    $snippet->pop->remove( 'offer' );

    ok( confirm_clean($snippet) ? 1 : 0 );

    # UNIMPLEMENTED
    # # Test the parm->parm_name->label method

    # UNIMPLEMENTED
    # # Test the parm->parm_name->desc method


### complex methods

    # Test the get_shared_lim_notes method
    $snippet->shared_lim->new( 'gender' );
    $snippet->shared_lim->new(
        'c_limit',
        note        => "This population limited to c_limit: 'foo'",
        valid_pop   => 'offer',
        prompt_parm => 'c_limit',
        selectable  => 'c_limit',
    );  # our own custom lim
    $snippet->parm->new( 'gender' );
    $snippet->parm->gender->value( 'U' );
    $snippet->parm->new( 'c_limit' );
    $snippet->parm->c_limit->value( 'foo' );
    $snippet->pop->new( 'offer' );
    $snippet->pop->offer->parm->new( 'offer_dec_codes' );
    $snippet->pop->offer->parm->offer_dec_codes->value( ['O','AO'] );
    $snippet->pop->offer->parm->new( 'offer_excld_dec_codes' );
    $snippet->pop->offer->parm->offer_excld_dec_codes->value( ['W','R'] );
    $snippet->pop->offer->select( 'SELECT count(*)' );
    $snippet->pop->offer->query;
    my $scalar_lim_notes = $snippet->get_shared_lim_notes;
    ok(
        (
            $scalar_lim_notes
            eq
            "This population limited to c_limit: 'foo'" . "\n" .
            "This population limited to Gender(s): 'U'" . "\n"
        )
        ? 1
        : 0
    );
    my @array_lim_notes = $snippet->get_shared_lim_notes;
    ok(
        scalar @array_lim_notes == 2
          and
        grep "This population limited to Gender(s): 'U'", @array_lim_notes
          and
        grep "This population limited to c_limit: 'foo'", @array_lim_notes
        ? 1
        : 0
    );
    $snippet->shared_lim->remove( 'gender' );
    $snippet->parm->remove( 'gender', 'c_limit' );
    $snippet->pop->remove( 'offer' );

    ok( confirm_clean($snippet) ? 1 : 0 );

### full-on autoinstantiation tests

    # confirm that snippet has no pop obj
    ok( confirm_clean($snippet) ? 1 : 0 );
    $snippet->pop->offer->lim->gender->parm->gender->value( 'M' );
    ok( $snippet->pop->offer->lim->gender->parm->gender->value eq 'M' ? 1 : 0 );


### helper subs
sub confirm_clean {
    my $snippet = shift;

    for (keys %{$snippet->{parm}}) {
        return 0 if ref eq 'SQL::Snippet::Parm';
    }
    for (keys %{$snippet->{shared_lim}}) {
        return 0 if ref eq 'SQL::Snippet::Lim';
    }
    for (keys %{$snippet->{pop}}) {
        return 0 if ref eq 'SQL::Snippet::Pop';
    }

    return 1;
}
