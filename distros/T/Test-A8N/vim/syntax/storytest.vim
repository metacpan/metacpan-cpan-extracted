" Vim syntax file
" Language:	Storytest Definition File
" Maintainer:	Chris Simmons (chriss@ca.sophos.com)
" Last Change:	2008 Jan 30

" Only load this syntax file when no other was loaded.
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" Tabs are evil in YAML files
setl expandtab
syn case match
syn keyword stSection TESTLINK_ID ID NAME SUMMARY PRECONDITIONS INSTRUCTIONS CONFIGURATION EXPECTED TAGS
syn match tabs /\t/
syn region stTestCase start="^-\+$" end="^-\+$"me=s-1 transparent fold

let fixtures = expand("~/.fixtures")
if filereadable(fixtures)
    execute 'source ' . fixtures
endif

hi link stSection TYPE
hi link tabs Error
hi link fixture_action SpecialKey
hi link fixture_test NonText

setlocal foldtext=TCFoldTestCase()
setlocal foldmethod=syntax
let b:current_syntax = "storytest"


function! TCFoldTestCase()
    let i = 1
    let lines = v:foldend - v:foldstart + 1
    let pretty = v:folddashes . lines . ' lines: '
    let a8n = ''
    let name = '???'
    while i <= 1000
	let line = getline(v:foldstart + i)
        if match(line, "^--*$") != -1
            return pretty . a8n . name
        elseif match(line, "^{{{") != -1
	    let a8n = "[A8N] "
	elseif match(line, 'NAME:') != -1
	    let name = substitute(line, '.*NAME:', '', '')
	endif
	let i = i + 1
    endwhile
    return pretty . a8n . name
endfunction

"map <C-h> <ESC>:execute '!fixturedoc --filename="' . expand("%") . '" --line=' . line(".")<CR>
map <C-h> <ESC>:call STFixtureDoc()<CR>
function! STFixtureDoc()
    let doc = tempname()
    execute ':silent !a8-fixturedoc --filename="' . expand("%") . '" --line=' . line(".") . ' > ' . doc . ' 2>&1'
    execute ':pedit! ' . doc
    execute ':redraw!'
endfunction


