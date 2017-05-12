" Periods are allowed in identifiers
setlocal isident+=.

syntax keyword TangenceKeyword include smashed of

syntax match TangenceComment /#.*/

syntax match TangenceString /"\(\\.\|[^"]\)*"/

syntax keyword TangenceKeyword class nextgroup=TangenceClassName skipwhite
syntax match TangenceClassName /\i\+/ nextgroup=TangenceClassBlock skipwhite contained
syntax keyword TangenceKeyword struct nextgroup=TangenceStructName skipwhite
syntax match TangenceStructName /\i\+/ nextgroup=TangenceStructBlock skipwhite contained

syntax match TangenceType /\i\+/ contained
syntax match TangenceIdentifier /\i\+/ contained

syntax keyword TangenceKeyword isa nextgroup=TangenceType skipwhite

syntax keyword TangenceKeyword method nextgroup=TangenceIdentifier,TangenceArglist skipwhite
syntax keyword TangenceKeyword event  nextgroup=TangenceIdentifier,TangenceArglist skipwhite
syntax keyword TangenceKeyword prop   nextgroup=TangenceIdentifier skipwhite
syntax keyword TangenceKeyword field  nextgroup=TangenceIdentifier skipwhite

syntax keyword TangenceDim  scalar hash queue array objset
syntax keyword TangenceType bool int float str obj any
syntax region  TangenceType start=/\(list\|dict\)(/ end=/)/ contains=TangenceType

syntax region TangenceArglist start="(" end=")" contains=TangenceType,TangenceIdentifier skipwhite

syntax region TangenceClassBlock start="{" end="}" fold transparent contained

syntax region TangenceStructBlock start="{" end="}" fold transparent contained

if version >= 508 || !exists("did_tangence_syn_inits")
    if version < 508
	let did_tangence_syn_inits = 1
	command -nargs=+ HiLink hi link <args>
    else
	command -nargs=+ HiLink hi def link <args>
    endif

    HiLink TangenceComment    Comment
    HiLink TangenceKeyword    Keyword
    HiLink TangenceString     String
    HiLink TangenceClassName  Identifier
    HiLink TangenceStructName Identifier
    HiLink TangenceIdentifier Identifier
    HiLink TangenceDim        StorageClass
    HiLink TangenceType       Type
    
    delcommand HiLink
endif

set foldmethod=syntax
set foldcolumn=2
