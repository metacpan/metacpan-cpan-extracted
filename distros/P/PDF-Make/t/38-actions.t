#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use PDF::Make::Document;
use PDF::Make::Action;

#-----------------------------------------------------------------------------
# Action type constants
#-----------------------------------------------------------------------------
subtest 'Action type constants' => sub {
    is(PDF::Make::Action::GOTO(),       0, 'GOTO constant');
    is(PDF::Make::Action::GOTOR(),      1, 'GOTOR constant');
    is(PDF::Make::Action::URI(),        2, 'URI constant');
    is(PDF::Make::Action::NAMED(),      3, 'NAMED constant');
    is(PDF::Make::Action::JAVASCRIPT(), 4, 'JAVASCRIPT constant');
    is(PDF::Make::Action::HIDE(),       5, 'HIDE constant');
    is(PDF::Make::Action::LAUNCH(),     6, 'LAUNCH constant');
};

#-----------------------------------------------------------------------------
# Named action constants
#-----------------------------------------------------------------------------
subtest 'Named action constants' => sub {
    is(PDF::Make::Action::NEXTPAGE(),  0, 'NEXTPAGE constant');
    is(PDF::Make::Action::PREVPAGE(),  1, 'PREVPAGE constant');
    is(PDF::Make::Action::FIRSTPAGE(), 2, 'FIRSTPAGE constant');
    is(PDF::Make::Action::LASTPAGE(),  3, 'LASTPAGE constant');
    is(PDF::Make::Action::PRINT(),     4, 'PRINT constant');
};

#-----------------------------------------------------------------------------
# Highlight mode constants
#-----------------------------------------------------------------------------
subtest 'Highlight mode constants' => sub {
    is(PDF::Make::Action::HIGHLIGHT_NONE(),    0, 'HIGHLIGHT_NONE constant');
    is(PDF::Make::Action::HIGHLIGHT_INVERT(),  1, 'HIGHLIGHT_INVERT constant');
    is(PDF::Make::Action::HIGHLIGHT_OUTLINE(), 2, 'HIGHLIGHT_OUTLINE constant');
    is(PDF::Make::Action::HIGHLIGHT_PUSH(),    3, 'HIGHLIGHT_PUSH constant');
};

#-----------------------------------------------------------------------------
# Action builders via Document
#-----------------------------------------------------------------------------
subtest 'URI action builder' => sub {
    my $doc = PDF::Make::Document->new();
    ok($doc, 'Created document');
    
    my $action = $doc->action_uri('https://example.com');
    ok($action, 'Created URI action');
    is($action->type, PDF::Make::Action::URI(), 'Action type is URI');
};

subtest 'GoTo action builder' => sub {
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $action = $doc->action_goto(1);  # page index 1 (second page)
    ok($action, 'Created GoTo action');
    is($action->type, PDF::Make::Action::GOTO(), 'Action type is GOTO');
};

subtest 'GoTo action with destination types' => sub {
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    
    my $fit = $doc->action_goto(0, 'Fit');
    ok($fit, 'Created GoTo Fit action');
    
    my $fith = $doc->action_goto(0, 'FitH', 0, 500);
    ok($fith, 'Created GoTo FitH action');
    
    my $fitv = $doc->action_goto(0, 'FitV', 100);
    ok($fitv, 'Created GoTo FitV action');
    
    my $xyz = $doc->action_goto(0, 'XYZ', 100, 200, 1.5);
    ok($xyz, 'Created GoTo XYZ action');
};

subtest 'Named action builder' => sub {
    my $doc = PDF::Make::Document->new();
    
    my $next = $doc->action_named('NextPage');
    ok($next, 'Created NextPage action');
    is($next->type, PDF::Make::Action::NAMED(), 'Action type is NAMED');
    
    my $prev = $doc->action_named('PrevPage');
    ok($prev, 'Created PrevPage action');
    
    my $first = $doc->action_named('FirstPage');
    ok($first, 'Created FirstPage action');
    
    my $last = $doc->action_named('LastPage');
    ok($last, 'Created LastPage action');
    
    my $print = $doc->action_named('Print');
    ok($print, 'Created Print action');
};

subtest 'JavaScript action builder' => sub {
    my $doc = PDF::Make::Document->new();
    
    my $action = $doc->action_javascript('app.alert("Hello!");');
    ok($action, 'Created JavaScript action');
    is($action->type, PDF::Make::Action::JAVASCRIPT(), 'Action type is JAVASCRIPT');
};

subtest 'GoToR (external PDF) action builder' => sub {
    my $doc = PDF::Make::Document->new();
    
    my $action = $doc->action_gotor('other.pdf', 0);
    ok($action, 'Created GoToR action');
    is($action->type, PDF::Make::Action::GOTOR(), 'Action type is GOTOR');
    
    my $newwin = $doc->action_gotor('other.pdf', 1, 1);
    ok($newwin, 'Created GoToR action with NewWindow');
};

#-----------------------------------------------------------------------------
# Action chaining
#-----------------------------------------------------------------------------
subtest 'Action chaining' => sub {
    my $doc = PDF::Make::Document->new();
    
    my $goto = $doc->action_goto(0);
    my $js   = $doc->action_javascript('app.alert("Navigated!");');
    
    # Chain: first goto, then execute JS
    my $result = $goto->chain($js);
    ok($result, 'Chained actions');
    isa_ok($result, 'PDF::Make::Action', 'Chain returns action');
};

#-----------------------------------------------------------------------------
# Link annotations with actions
#-----------------------------------------------------------------------------
subtest 'Link annotation with URI action' => sub {
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    
    my $action = $doc->action_uri('https://perl.org');
    my $annot = $doc->add_link_with_action(100, 700, 200, 720, $action);
    ok($annot, 'Created link annotation with action');
    ok($annot > 0, 'Annotation has valid object number');
};

subtest 'Link annotation with named action' => sub {
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    
    my $annot = $doc->add_link_named_action(100, 700, 200, 720, 'NextPage');
    ok($annot, 'Created link annotation with named action');
    ok($annot > 0, 'Annotation has valid object number');
};

subtest 'Link annotation with highlight modes' => sub {
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    
    my $action = $doc->action_uri('https://example.com');
    
    my $none = $doc->add_link_with_action(100, 700, 200, 720, $action, 'None');
    ok($none, 'Link with None highlight');
    
    my $invert = $doc->add_link_with_action(100, 600, 200, 620, $action, 'Invert');
    ok($invert, 'Link with Invert highlight');
    
    my $outline = $doc->add_link_with_action(100, 500, 200, 520, $action, 'Outline');
    ok($outline, 'Link with Outline highlight');
    
    my $push = $doc->add_link_with_action(100, 400, 200, 420, $action, 'Push');
    ok($push, 'Link with Push highlight');
};

#-----------------------------------------------------------------------------
# Full PDF generation with actions
#-----------------------------------------------------------------------------
subtest 'Generate PDF with link annotations' => sub {
    my $doc = PDF::Make::Document->new();
    my $page = $doc->add_page(612, 792);
    
    # Add URI link
    my $uri_action = $doc->action_uri('https://perl.org');
    my $link1 = $doc->add_link_with_action(100, 695, 200, 715, $uri_action);
    ok($link1 > 0, 'Added URI link');
    
    # Add navigation buttons
    my $prev = $doc->add_link_named_action(50, 50, 100, 70, 'PrevPage');
    ok($prev > 0, 'Added PrevPage link');
    
    my $next = $doc->add_link_named_action(500, 50, 560, 70, 'NextPage');
    ok($next > 0, 'Added NextPage link');
    
    ok(1, 'PDF with actions created');
};

subtest 'Action write and object number' => sub {
    my $doc = PDF::Make::Document->new();
    
    my $action = $doc->action_uri('https://test.com');
    is($action->obj_num, 0, 'Action obj_num is 0 before write');
    
    my $num = $action->write();
    ok($num > 0, 'Action write returns object number');
    is($action->obj_num, $num, 'Action obj_num updated after write');
    
    # Second write should return same number
    my $num2 = $action->write();
    is($num2, $num, 'Second write returns same object number');
};

done_testing();
