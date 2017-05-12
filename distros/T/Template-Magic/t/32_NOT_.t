#!perl -w
; use strict
; use warnings
; use Template::Magic::HTML
; use Test::More tests => 1

; sub test_undef {}


; my $template = << ''
start <!--{label}--><!--{/label}--><!--{NOT_label}-->NOT_label <!--{/NOT_label}--><!--{test_undef}-->test<!--{/test_undef}--><!--{NOT_test_undef}-->NOT_test_undef <!--{/NOT_test_undef}-->end

; my $tm = Template::Magic::HTML->new
; my $out = $tm->output(\$template)
; is $$out, "start NOT_label NOT_test_undef end\n"




