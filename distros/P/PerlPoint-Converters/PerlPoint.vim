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
sy match Kommentar /^\/\/.*/ contains=fldopen
sy match Tag /\\[A-Z][A-Z]*[a-zA-Z_="{} :/]*<[^>]*>/
sy match Makro /^[+][A-Z][A-Z]*:/
sy match Condi /^?.*/
sy match bullet /^*/
sy match numlist /^#/
sy match shift /^[<>][0-9]*/

sy keyword fldopen contained 
sy keyword fldclosed contained 

sy match fldopen ".*{{{[1-9]"
sy match fldclose ".*}}}[1-9]"

hi link Header2 Todo
hi link fldopen Ignore
hi link fldclose Ignore
hi Header1 term=bold  ctermfg=1  gui=bold guifg=white guibg=blue
hi Header term=bold  ctermfg=1  guifg=black guibg=grey
hi Tag term=bold  ctermfg=1  gui=NONE guifg=SeaGreen
hi Makro term=bold  ctermfg=1  gui=NONE guifg=red
hi link Kommentar Comment
hi link Condi String
hi bullet term=bold  ctermfg=1  gui=NONE guifg=red
hi numlist term=bold  ctermfg=1  gui=NONE guifg=red
hi link shift Comment

