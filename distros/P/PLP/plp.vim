" Vim syntax file
" Language:	PLP (Perl in HTML)
" Maintainer:	Shiar <perl@shiar.org>
" Last Change:	2009 October 19
" Cloned From:	aspperl.vim
" Author:	Juerd <juerd@juerd.nl>

" Add to filetype.vim the following line (without quote sign):
" au BufNewFile,BufRead *.plp setf plp

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'perlscript'
endif

if version < 600
  so <sfile>:p:h/html.vim
  syn include @PLPperl <sfile>:p:h/perl.vim
else
  runtime! syntax/html.vim
  unlet b:current_syntax
  syn include @PLPperl syntax/perl.vim
endif

syn cluster htmlPreproc add=PLPperlblock

syn keyword perlControl PLP_END
syn keyword perlStatementInclude include Include
syn keyword perlStatementFiles ReadFile WriteFile Counter
syn keyword perlStatementScalar EscapeHTML Entity AutoURL DecodeURI EncodeURI

syn cluster PLPperlcode contains=perlStatement.*,perlFunction,perlOperator,perlVarPlain,perlVarNotInMatches,perlShellCommand,perlFloat,perlNumber,perlStringUnexpanded,perlString,perlQQ,perlControl,perlConditional,perlRepeat,perlComment,perlPOD,perlHereDoc,perlPackageDecl,perlElseIfError,perlFiledescRead,perlMatch
  
syn region  PLPperlblock keepend matchgroup=Delimiter start=+<:=\=+ end=+:>+ contains=@PLPperlcode

syn region  PLPinclude keepend matchgroup=Delimiter start=+<(+ end=+)>+

let b:current_syntax = "plp"

