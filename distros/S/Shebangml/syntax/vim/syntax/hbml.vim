" Vim syntax file

syn clear

"syn keyword hbmlTag html ul li td table

"syn match   hbmlTag "\(\<\|\\\)[._:a-zA-Z0-9]\+\[[^\]]*\]" contains=hbmlAtt,hbmlBacon,hbmlAttShort

" ugh. does it not infer the 'contains' match?
syn region   hbmlTag start="\(\<\|\\\)[._:a-zA-Z0-9-]\+\[" end="]" contains=hbmlAtt,hbmlAttShort,hbmlAttError
"syn region hbmlAttSet start="\[" end="]" contains=hbmlAtt,hbmlAttShort,hbmlAttError contained
"syn match   hbmlTag "\(\<\|\\\)[._:a-zA-Z0-9]\+\[[^\]]*\]{" contains=hbmlAtt,hbmlBacon,hbmlAttShort

syn match   hbmlTag "\(\<\|\\\)[._:a-zA-Z0-9-]\+{" contains=hbmlBacon
" and the optional ender
syn match   hbmlTag         "}#[._:a-zA-Z0-9-]\+;" contains=hbmlBacon

syn match   hbmlComment  "^\s*#.*"
syn region  hbmlComment  start="^#{" end="^#}.*"
syn match hbmlBacon "[{}]" contained

" these two are trouble:
syn region hbmlThickBacon start="{{" end="}}}" oneline
syn region hbmlThickBacon start="{{{\?$" end="^\s*}}}\?"

" I guess this is the way to build what would otherwise be an anchor?
" The prefix highlighting contains the entire pattern and the latter
" bits contain that?
syn match hbmlAttShort "[=:@][a-zA-Z0-9_/.-][a-zA-Z0-9_/.:-]*" contained contains=hbmlAttShortV
syn match hbmlAttShortV   "[a-zA-Z0-9_/.-][a-zA-Z0-9_/.:-]*" contained

" well. whatever.  The only reason we would need an AttSet is to make
" this work.  Negative assertion lookahead?
syn match hbmlAttError /\<\w\+\> / contained

syn match hbmlAtt /[a-zA-Z0-9_/.-][a-zA-Z0-9_/.:-]*=[a-zA-Z0-9_/.:-]\+/ contained contains=hbmlAttV
syn match hbmlAttV    /=[a-zA-Z0-9_/.:-]\+/ contained contains=hbmlAttVeq
syn match hbmlAttVeq /=/ contained

" TODO should these be 'oneline'
syn region hbmlAtt start=/[a-zA-Z0-9_/.-][a-zA-Z0-9_/.:-]*="/ skip=/\\\\\|\\"/ end=/"/ contained contains=hbmlAttVs,hbmlAttVeq keepend oneline
syn region hbmlAttVs    start=/"/ skip=/\\\\\|\\"/ end=/"/ contained oneline
"syn match hbmlAttVeqs /[="]/
"syn match hbmlAttVeqs /\(="\)\|"/ contained
"syn match hbmlAttV /="[^"]*"/ contained contains=hbmlAttVeq

" uh...
"   {} and [] something-something

"syn region  hbmlString  start=+"+ skip=+\\\\\|\\"+ end=+"+ oneline
"syn region  hbmlString  start=+'+ skip=+\\\\\|\\'+ end=+'+ oneline

hi def link hbmlTag     Keyword
hi def link hbmlAtt     Type
hi def link hbmlAttSet  Keyword
hi def link hbmlAtts    Type
hi def link hbmlAttV    String
hi def link hbmlAttVs   String
hi def link hbmlAttVeq  Normal
hi def link hbmlAttVeqs Normal
hi def link hbmlAttError Error
hi def link hbmlComment Comment
hi def link hbmlBacon   Normal
hi def link hbmlAttShort Type
hi def link hbmlAttShortV Title
"hi def link hbmlTodo    Todo
hi def link hbmlThickBacon  String

let b:current_syntax = "hbml"

" vim: ts=8 sw=2
