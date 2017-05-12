" Vim syntax file loader
" Language:    SQL::Bibliosoph
" Maintainer:  Matias Alejo Garcia <matias at confronte.com>
" Last Change: Fri May 11 09:05:56 ART 2007
" Version:     1.0

" Description: Based on mysql
"
" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" Default to the standard Vim distribution file
let filename = 'mysql'

" Source the appropriate file
exec 'runtime syntax/'.filename.'.vim'

syn region Todo	 start="--\["  end="\]" contains=ALL
syn region Error start="-- \["  end="\]" contains=ALL

let b:current_syntax = "bb"
" vim:sw=4:ff=unix:
