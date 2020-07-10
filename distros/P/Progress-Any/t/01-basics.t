#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Progress::Any;
use Test::More 0.98;
use Test::Exception;
use Time::HiRes qw(sleep);

# XXX test finish()
# XXX test reset()
# XXX test update() argument: force_update

subtest "get_indicator, {total_,pos}, {total_,}target, percent_complete" => sub {
    %Progress::Any::indicators = ();

    my $p_ab = Progress::Any->get_indicator(task=>"a.b", target=>10);
    is($p_ab->pos, 0, "a.b's pos");
    is($p_ab->total_pos, 0, "a.b's total_pos");
    is($p_ab->target, 10, "a.b's target");
    is($p_ab->total_target, 10, "a.b's total target");
    is($p_ab->percent_complete, 0, "a.b's percent_complete");

    my $p_a  = Progress::Any->get_indicator(task=>"a");
    is($p_a->pos, 0, "a's target");
    is($p_a->total_pos, 0, "a's target");
    is_deeply($p_a->target, 0, "a's target");
    is_deeply($p_a->total_target, 10, "a's total target");
    is_deeply($p_a->percent_complete, 0, "a's percent_complete");

    my $p_ = Progress::Any->get_indicator(task=>"");
    is($p_->pos, 0, "root's target");
    is($p_->total_pos, 0, "root's target");
    is_deeply($p_->target, 0, "root's target");
    is_deeply($p_->total_target, 10, "root's total target");
    is_deeply($p_->percent_complete, 0, "root's percent_complete");

    my $p_abd = Progress::Any->get_indicator(task=>"a.b.d", target=>7, pos=>2);
    is($p_abd->pos, 2, "a.b.d's pos");
    is($p_abd->total_pos, 2, "a.b.d's total_pos");
    is($p_abd->target, 7, "a.b.d's target");
    is($p_abd->total_target, 7, "a.b.d's total target");
    is(sprintf("%.0f", $p_abd->percent_complete), 29, "a.b.d's percent_complete");
    is($p_ab->total_pos, 2, "a.b's total_pos");
    is($p_ab->total_target, 17, "a.b's total target");
    is(sprintf("%.0f", $p_ab->percent_complete), 12, "a.b's percent_complete");

    $p_a->target(0);
    is($p_a->total_pos, 2, "a's total pos");
    is($p_a->total_target, 17, "a's total target");
    is(sprintf("%.0f", $p_a->percent_complete), 12, "a's percent_complete");

    $p_->target(0);
    is($p_->total_pos, 2, "root's total pos");
    is($p_->total_target, 17, "root's total target");
    is(sprintf("%.0f", $p_->percent_complete), 12, "root's percent_complete");

    my $p_ac = Progress::Any->get_indicator(task=>"a.c", target=>5, pos=>1);
    is($p_ac->pos, 1, "a.c's pos");
    is($p_ac->total_pos, 1, "a.c's total_pos");
    is($p_ac->target, 5, "a.c's target");
    is($p_ac->total_target, 5, "a.c's total target");
    is(sprintf("%.0f", $p_ac->percent_complete), 20, "a.c's percent_complete");
    is($p_a->total_pos, 3, "a's pos");
    is($p_a->total_target, 22, "a's total target");
    is(sprintf("%.0f", $p_a->percent_complete), 14, "a's percent_complete");
    is($p_->total_pos, 3, "root's pos");
    is($p_->total_target, 22, "root's total target");
    is(sprintf("%.0f", $p_->percent_complete), 14, "root's percent_complete");

    my $p_abe = Progress::Any->get_indicator(task=>"a.b.e", target=>undef);
    is($p_abe->pos, 0, "a.b.e's pos");
    ok(!defined($p_abe->target), "a.b.e's target is undef");
    ok(!defined($p_abe->percent_complete), "a.b.e's percent_complete is undef");
    ok(!defined($p_ab->total_target), "a.b's total_target is undef");
    ok(!defined($p_ab->percent_complete), "a.b's percent_complete is undef");
    ok(!defined($p_a->total_target), "a's total_target is undef");
    ok(!defined($p_a->percent_complete), "a's percent_complete is undef");
    ok(!defined($p_->total_target), "root's total_target is undef");
    ok(!defined($p_->percent_complete), "root's percent_complete is undef");

    dies_ok { Progress::Any->get_indicator(task=>'a b') }
        'invalid task in get_indicator() -> dies';

    dies_ok { Progress::Any->get_indicator(task=>'foo', foo=>1) }
        'unknown arg in get_indicator() -> dies';

    dies_ok { Progress::Any->get_indicator(task=>'foo', target=>-1) }
        'invalid target in get_indicator() -> dies';

    dies_ok { Progress::Any->get_indicator(task=>'foo', pos=>-1) }
        'invalid pos in get_indicator() -> dies';
};

subtest "update, state, elapsed, start, stop, finish" => sub {
    plan skip_all => "Temp. put in RELEASE_TESTING due to fragility of timing"
        unless $ENV{RELEASE_TESTING};

    %Progress::Any::indicators = ();

    my $p = Progress::Any->get_indicator(task=>"a.b", target=>10);

    is($p->state, 'stopped', 'state before update() 1');
    is($p->pos, 0, 'pos before update() 1');

    sleep 0.05;
    is($p->elapsed, 0, "elapsed doesn't run before update() 1");
    $p->update;
    is($p->state, 'started', 'state after update() 1');
    is($p->pos, 1, 'pos after update() 1');
    my $p_a = Progress::Any->get_indicator(task=>"a");
    is($p_a->state, 'started', 'parent a is automatically started by update()');
    my $p_ = Progress::Any->get_indicator(task=>"");
    is($p_->state, 'started', 'parent root is automatically started by update()');

    sleep 1;
    is(sprintf("%.0f", $p->elapsed), "1", "elapsed runs after update() 1");
    $p->stop;

    sleep 1;
    is(sprintf("%.0f", $p->elapsed), "1", "elapsed doesn't run after stop()");
    $p->start;

    sleep 1;
    is(sprintf("%.0f", $p->elapsed), "2", "elapsed runs again after start()");
    $p->update(pos=>8);
    is($p->pos, 8, "update() 2 with specified pos");

    dies_ok { $p->update(foo=>1) } 'unknown arg in update() -> dies';
};

# XXX subtest remaining, set remaining, remaining_total

subtest "fill_template" => sub {
    plan skip_all => "Currently release testing only due to timing-related and fail on some CT machines"
        unless $ENV{RELEASE_TESTING};

    %Progress::Any::indicators = ();

    my $pa = Progress::Any->get_indicator(task=>"a", title=>"alf", target=>40);
    my $pb = Progress::Any->get_indicator(task=>"b", title=>"boo", target=>40);
    my $p_ = Progress::Any->get_indicator(task=>"", target=>0);

    $pa->update();
    sleep 0.05;

    is($pa->fill_template("%t"), "alf", "t");
    is($pa->fill_template("%3n"), "  a", "n, width");
    is($pa->fill_template("%-3m", message=>"b"), "b  ", "m, negative width");
    is($pa->fill_template("%m"), "", "m defaults to ''");
    is($pa->fill_template("%%"), "%", "%");
    is($pa->fill_template("%%"), "%", "%");
    is($pa->fill_template("%e"), "1s      ", "e, default");
    is($pa->fill_template("%2e"), "1s", "e, width");
    like($pa->fill_template("%p%%"), qr/^  [23]%$/, "p"); # on most systems it's 2% but on some 3%
    is($p_->fill_template("%p%%"), "  1%", "p root");
    is($pa->fill_template("%r"), "2s      ", "r");
    #is($p_->fill_template("%r"), "4s      ", "r root");
    is($pa->fill_template("%R"), "2s left         ", "R");
    $pa->target(undef);
    is($pa->fill_template("%R"), "1s elapsed      ", "R");
    is($pa->fill_template("%p"), "  ?", "p unknown");
    is($pa->fill_template("%T"), "?", "T unknown");

    is($pa->fill_template("%z"), "%z", "unknown template returns as-is");

};

DONE_TESTING:
done_testing;
