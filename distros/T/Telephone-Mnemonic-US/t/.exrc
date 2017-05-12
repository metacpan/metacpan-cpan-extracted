if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
nmap gx <Plug>NetrwBrowseX
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
let &cpo=s:cpo_save
unlet s:cpo_save
set autowrite
set backspace=2
set exrc
set fileencodings=ucs-bom,utf-8,default,latin1
set helplang=en
set keywordprg=:help
set modelines=0
set path=.,..,../blib/lib/Telephone/Mnemonic,../script,../t,
set ruler
set secure
set shiftwidth=4
set showmatch
set tabstop=4
set window=0
" vim: set ft=vim :
