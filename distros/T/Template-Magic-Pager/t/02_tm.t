; use Test::More tests => 3

; use strict
; use warnings

; use Template::Magic::Pager
; use Template::Magic
; our $no_page

; my $temp = do{local $/; <DATA>}
; my @rows = (1..100)
; our $pager = Template::Magic::Pager->new ( total_results => \@rows #
                                            , rows_per_page => 4
                                            , page_number   => 3
                                            ) 
; my $tm = Template::Magic->new 
; my $out = $tm->output(\$temp)
; is ( $$out , <<'EOO' )
start-->

Results 9 to 12 of 100 (page 3/25)
9101112
(PREV->2) 1 (1-4) 2 (5-8) [3] (9-12) 4 (13-16) 5 (17-20) 6 (21-24) 7 (25-28) 8 (29-32) 9 (33-36) 10 (37-40) (NEXT->4)

<--end
EOO

; @rows = (1..100)
; $pager = Template::Magic::Pager->new ( total_results => 100 #
                                       , rows_per_page => 4
                                       , page_number   => 3
                                       , page_rows     => [9..12]
                                       ) 


; $tm = Template::Magic->new
; $out = $tm->output(\$temp)
; is ( $$out , <<'EOO' )
start-->

Results 9 to 12 of 100 (page 3/25)
9101112
(PREV->2) 1 (1-4) 2 (5-8) [3] (9-12) 4 (13-16) 5 (17-20) 6 (21-24) 7 (25-28) 8 (29-32) 9 (33-36) 10 (37-40) (NEXT->4)

<--end
EOO

; @rows = ()
; $pager = Template::Magic::Pager->new ( total_results => \@rows
                                        , rows_per_page  => 4
                                        , page_number    => 3
                                        ) 
                               

; $tm = Template::Magic->new 
; $out = $tm->output(\$temp)

; is ( $$out , <<'EOO' )
start-->
No Result
<--end
EOO

   
__DATA__
start-->
{pager}
Results {start_result} to {end_result} of {total_results} (page {page_number}/{total_pages})
{page_rows}
({previous}PREV->{previous_page}{/previous}{NOT_previous}prev{/NOT_previous}) {index}{linked_page}{page_number} ({start_result}-{end_result}) {/linked_page}{current_page}[{page_number}] ({start_result}-{end_result}) {/current_page}{/index}({next}NEXT->{next_page}{/next}{NOT_next}next{/NOT_next})
{/pager}{NOT_pager}No Result{/NOT_pager}
<--end
