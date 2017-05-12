" Syntax for pp2html
" ==================
"
" simple syntax highlighting for PerlPoint Files,
" not perfect, but sufficient ...
"
" by Lorenz Domke (lorenz.domke@gmx.de)
"

" clear all previous syntax stuff
syntax sync clear

sy match Header1 /^=[^=].*/
sy match Header2 /^==[^=].*/
sy match Header /^===.*/
sy match Kommentar /^\/\/.*/
sy match Tag /\\[A-Z][A-Z]*<[^>]*>/
sy match Makro /^[+][A-Z][A-Z]*:/


hi link Header2 Todo
hi Header1 term=bold  ctermfg=1  gui=bold guifg=white guibg=blue
hi Header term=bold  ctermfg=1  guifg=black guibg=grey
hi Tag term=bold  ctermfg=1  gui=NONE guifg=SeaGreen
hi Makro term=bold  ctermfg=1  gui=NONE guifg=red
hi link Kommentar Comment

