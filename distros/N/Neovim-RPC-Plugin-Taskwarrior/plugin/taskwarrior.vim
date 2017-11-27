" NVIM_LISTEN_ADDRESS=127.0.0.1:6666

function! TW_done() range
    call Nvimx_notify( 'tw_done', getline( a:firstline, a:lastline ) )
endfunction

function! TW_delete() range
    call rpcrequest( g:nvimx_channel, 'tw_delete', getline( a:firstline, a:lastline ) )
endfunction

function! TW_show(...)
    if a:0
        call rpcrequest( g:nvimx_channel, 'tw_show', a:1 )
    else
        let filter = input( "filter: ", "" )
        call rpcrequest( g:nvimx_channel, 'tw_show', filter )
    endif

endfunction

function! TW_toggle_focus()
    call rpcrequest( g:nvimx_channel, 'tw_toggle_focus' )
endfunction

function! TW_info() range
    call rpcrequest( g:nvimx_channel, 'tw_info', getline( a:firstline, a:lastline ) )
endfunction

function! TW_mod(...) range
    if a:0
        call rpcrequest( g:nvimx_channel, 'tw_mod', a:1, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    else
        let filter = input( "mod: ", " " )
        call rpcrequest( g:nvimx_channel, 'tw_mod', filter, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    endif
endfunction

function! TW_append(...) range
    if a:0
        call rpcrequest( g:nvimx_channel, 'tw_append', a:1, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    else
        let filter = input( "mod: ", " " )
        call rpcrequest( g:nvimx_channel, 'tw_append', filter, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    endif
endfunction

function! TW_wait(...) range
    if a:0
        call rpcrequest( g:nvimx_channel, 'tw_mod', a:1, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    else
        let filter = input( "wait: ", "eow" )
        call rpcrequest( g:nvimx_channel, 'tw_wait', filter, a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
    endif
endfunction

au FileType task map  <buffer> <leader>d :call TW_done()<CR>
au FileType task vmap <buffer> <leader>d :call TW_done()<CR>

au FileType task map  <buffer> <leader>D :call TW_delete()<CR>
au FileType task vmap <buffer> <leader>D :call TW_delete()<CR>

au FileType task map <buffer> <leader>ll :call TW_show(' ')<CR>
au FileType task map <buffer> <leader>lf :call TW_show('+focus')<CR>
au FileType task map <buffer> <leader>lq :call TW_show()<CR>

au FileType task map  <leader>m :call TW_mod()<CR>
au FileType task vmap <leader>m :call TW_mod()<CR>
au FileType task map  <leader>a :call TW_append()<CR>
au FileType task vmap <leader>a :call TW_append()<CR>

au FileType task map <leader>f :call TW_toggle_focus()<CR>

" info
au FileType task map  <buffer> <leader>i :call TW_info()<CR>
au FileType task vmap <buffer> <leader>i :call TW_info()<CR>

" priority
au FileType task map  <buffer> <leader>pl :call TW_mod('priority:L')<CR>
au FileType task map  <buffer> <leader>pm :call TW_mod('priority:M')<CR>
au FileType task map  <buffer> <leader>ph :call TW_mod('priority:H')<CR>
au FileType task vmap <buffer> <leader>pl :call TW_mod('priority:L')<CR>
au FileType task vmap <buffer> <leader>pm :call TW_mod('priority:M')<CR>
au FileType task vmap <buffer> <leader>pm :call TW_mod('priority:M')<CR>

" wait
au FileType task map  <buffer> <leader>W :call TW_wait()<CR>
au FileType task vmap <buffer> <leader>W :call TW_wait()<CR>

au FileType task set nowrap
au FileType task TableModeEnable

map <leader>tS :TableSort!<CR>

function! Task()
    call Nvimx_load_plugin('Taskwarrior')
endfunction
