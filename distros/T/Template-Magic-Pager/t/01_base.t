; use Test::More tests => 40
; use strict
; use warnings

; use Template::Magic::Pager
; my $results = [1..10]

; our $p = Template::Magic::Pager->new( total_results => $results
                                     , rows_per_page  => 4
                                     , page_number    => 2
                                     )
; is( $p->start_result => 5 )
; is( $p->end_result   => 8 )
; is( $p->_start_offset => 4 )
; is( $p->_end_offset   => 7 )
; is( ref $p->next => 'HASH' )
; is( ref $p->previous => 'HASH' )
; is( $p->next_page => 3 )
; is( $p->previous_page => 1 )
; is( $p->total_pages => 3 )
; is( join('-', @{$p->page_rows}) => '5-6-7-8' )

; my $page_number = 3
; my $rows_per_page = 4
; my $offset = $rows_per_page * ($page_number - 1) 
; $p = Template::Magic::Pager->new( total_results => 10
                                  , page_number   => $page_number 
                                  , rows_per_page => $rows_per_page  
                                  )
; is( $p->start_result => 9 )
; is( $p->end_result   => 10 )
; is( $p->_start_offset => 8 )
; is( $p->_end_offset   => 9 )
; ok( not $p->next)
; ok( $p->previous )
; is( $p->next_page => '' )
; is( $p->previous_page => 2 )
; is( $p->total_pages => 3 )

  
; $p = Template::Magic::Pager->new( total_results  => $results
                                  , rows_per_page  => 5
                                  , page_number    => 2
                                  )

; is( $p->start_result => 6 )
; is( $p->end_result   => 10 )
; is( $p->_start_offset => 5 )
; is( $p->_end_offset   => 9 )
; ok( not $p->next )
; ok( $p->previous )
; is( $p->next_page => '' )
; is( $p->previous_page => 1 )
; is( $p->total_pages => 2 )
; is( join('-', @{$p->page_rows}) => '6-7-8-9-10' )
   
; my $bigSel = [1..100]
; $p = Template::Magic::Pager->new( total_results => $bigSel
                                  , rows_per_page => 5
                                  )
; is( scalar @{$p->index} => 10 )
; ok( exists $p->index->[0]{current_page} )
; is( $p->index->[0]{page_number} => 1 )
      

; $p = Template::Magic::Pager->new( total_results => $bigSel
                                  , rows_per_page => 5
                                  , page_number   => 6
                                  )
; is( scalar @{$p->index} => 10 )
; ok( exists $p->index->[5]{current_page} )
; is( $p->index->[0]{page_number} => 1 ) 
; is( $p->index->[5]{page_number} => 6 )


; $p = Template::Magic::Pager->new( total_results => $bigSel
                                  , rows_per_page => 5
                                  , page_number   => 19
                                  )
; is( scalar @{$p->index} => 10 )
; is( ref $p->index->[8]{current_page} => 'HASH' )
; is( $p->index->[0]{page_number} => 11 ) 
; is( $p->index->[9]{page_number} => 20 )

























