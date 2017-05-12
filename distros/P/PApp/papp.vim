" Vim syntax file for the "papp" file format (_p_erl _app_lication)
"
" Language:	papp
" Maintainer:	Marc Lehmann <schmorp@schmorp.de>
" Last Change:	2001 May 10
" Filenames:    *.papp *.pxml *.pxsl
" URL:		http://papp.plan9.de/

" You can set the "papp_include_html" variable so that html will be
" rendered as such inside phtml sections (in case you actually put html
" there - papp does not require that). Also, rendering html tends to keep
" the clutter high on the screen - mixing three languages is difficult
" enough(!). PS: it is also slow.

" configurable variables
" let papp_cdata_contains_perl = 1

syntax clear
if exists("b:current_syntax")
  finish
endif
let s:papp_cpo_save = &cpo
set cpo&vim

syn case match

" source is basically xml, with included html (this is common) and perl bits
syn include @PAppPerl syntax/perl.vim
unlet b:current_syntax

syn cluster papp contains=papp_gettext,papp_perl,papp_pre,papp_precond

" assume xml-style-text on toplevel, taken directly from syntax/xml.vim
syn match xmlError "[<&]"

syn region  xmlString contained start=+"+ end=+"+ contains=@papp,xmlEntity display
syn region  xmlString contained start=+'+ end=+'+ contains=@papp,xmlEntity display
syn match   xmlAttribPunct "[:.]" contained display
syn match   xmlEqual "=" display
syn match   xmlAttrib +[-'"<]\@<!\<[a-zA-Z:_][-.0-9a-zA-Z0-9:_]*\>\(['">]\@!\|$\)+ contained contains=xmlAttribPunct display
syn match   xmlNamespace +\(<\|</\)\@<=[^ /!?<>"':]\+[:]\@=+ contained display 
syn match   xmlTagName +[<]\@<=[^ /!?<>"']\++ contained contains=xmlNamespace,xmlAttribPunct
syn region  xmlTag matchgroup=xmlTag start=+<[^ /!?<>"':]\@=+ matchgroup=xmlTag end=+>+ contains=xmlError,xmlTagName,xmlAttrib,xmlEqual,xmlString
syn match   xmlEndTag +</[^ /!?<>"']\+>+ contains=xmlNamespace,xmlAttribPunct
syn match   xmlEntity "&[^; \t]*;" contains=xmlEntityPunct
syn match   xmlEntityPunct  contained "[&.;]"
syn region  xmlComment start=+<!+ end=+>+ contains=xmlCommentPart,xmlCommentError extend
syn match   xmlCommentError contained "[^><!]"
syn region  xmlCommentPart start=+--+ end=+--+ contained contains=xmlTodo
syn region  xmlCdata start=+<!\[CDATA\[+ end=+]]>+ contains=xmlCdataStart,xmlCdataEnd,@xmlCdataHook keepend extend
syn match   xmlCdataStart +<!\[CDATA\[+  contained contains=xmlCdataCdata
syn keyword xmlCdataCdata CDATA          contained
syn match   xmlCdataEnd   +]]>+          contained

syn cluster xmlCdataHook contains=@papp

if exists("papp_cdata_contains_perl")
   syn cluster xmlCdataHook add=@PAppPerl
endif

" translation entries
syn region papp_gettext start=/__"/ end=/"/ contains=@perlInterpDQ

" embedded perl sections
syn region papp_perl matchgroup=papp_delim start="<[:?]" end="[:]>" keepend contains=papp_reference,papp_cb,@PAppPerl

" preprocessor commands
syn region papp_precond matchgroup=papp_pre excludenl oneline start="^#\s*\(if\|elif\|elsif\)" end="$" keepend contains=@perlExpr display
syn match papp_pre /^#\s*\(else\|endif\|??\).*$/ excludenl display

" callbacks
syn region papp_cb matchgroup=papp_delim start="{:" end=":}" keepend contains=@PAppPerl contained

" agni
syn region papp_reference matchgroup=papp_delim start="\$\?{{" end="}}" keepend display containedin=@PAppPerl contained

syn sync clear
"syn sync fromstart " maybe this is the only thing that works
"syn sync linebreaks=3

syn sync match NONE groupthere papp_perl "^<[:?]"

" The special highlighting of PApp core functions only in papp_ph_perl section

syn keyword papp_core containedin=papp_perl
     \ surl slink echo
     \ redirect internal_redirect abort_to content_type
     \ abort_with_file abort_with setlocale
     \ SURL_PUSH SURL_UNSHIFT SURL_POP SURL_SHIFT
     \ SURL_EXEC SURL_SAVE_PREFS SURL_SET_LOCALE SURL_SUFFIX
     \ SURL_STYLE_URL SURL_STYLE_GET SURL_STYLE_STATIC
     \
     \ ef_mbegin ef_sbegin ef_cbegin ef_begin ef_end
     \ ef_submit ef_reset ef_field ef_cb_begin ef_cb_end
     \ ef_string ef_password ef_text ef_checkbox ef_radio
     \ ef_button ef_hidden ef_selectbox ef_relation
     \ ef_set ef_enum ef_file ef_constant

" The default highlighting.

hi def link papp_delim          Delimiter
hi def link papp_pre		PreProc
hi def link papp_gettext	String
hi def link papp_reference	Type
hi def link papp_core	 	Keyword

hi def link xmlTag              Function
hi def link xmlTagName          Function
hi def link xmlEndTag           Identifier
hi def link xmlNamespace        Tag
hi def link xmlEntity           Statement
hi def link xmlEntityPunct      Type

hi def link xmlAttribPunct      Comment
hi def link xmlAttrib           Type

hi def link xmlString           String
hi def link xmlComment          Comment
hi def link xmlCommentPart      Comment
hi def link xmlCommentError     Error
hi def link xmlError            Error

hi def link xmlProcessingDelim  Comment
hi def link xmlProcessing       Type

hi def link xmlCdata            String
hi def link xmlCdataCdata       Statement
hi def link xmlCdataStart       Type
hi def link xmlCdataEnd         Type

hi def link xmlDocTypeDecl      Function
hi def link xmlDocTypeKeyword   Statement
hi def link xmlInlineDTD        Function

let b:current_syntax = "papp"

let &cpo = s:papp_cpo_save
unlet s:papp_cpo_save


