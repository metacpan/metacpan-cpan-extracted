#!perl -w

; use strict
; use Test::More tests => 3
; use Template::Magic


; our @array = qw(a b c d)
; my $tm = new Template::Magic


; my $template0 = << 'EOT' ;
start{array OF foo foo_ix}
in block {foo}
ix {foo_ix}{/array}
end
EOT

; my $output0 = $tm->output(\$template0)
; my $expected0 = << 'EOE';
start
in block a
ix 0
in block b
ix 1
in block c
ix 2
in block d
ix 3
end
EOE
; is( $$output0
    , $expected0
    )


; my $template1 = << 'EOT' ;
start{array OF foo foo_ix 1}
in block {foo}
ix {foo_ix}{/array}
end
EOT
; my $output1 = $tm->output(\$template1)
; my $expected1 = << 'EOE';
start
in block a
ix 1
in block b
ix 2
in block c
ix 3
in block d
ix 4
end
EOE
; is( $$output1
    , $expected1
    )

    
    
; my $templateX = << 'EOT' ;
start{array OF foo}
in block {foo}{/array}
end
EOT

; my $outputX = $tm->output(\$templateX)
; my $expectedX = << 'EOE';
start
in block a
in block b
in block c
in block d
end
EOE
; is( $$outputX
    , $expectedX
    )
