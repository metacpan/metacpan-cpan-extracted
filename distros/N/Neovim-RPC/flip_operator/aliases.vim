" NVIM_LISTEN_ADDRESS=127.0.0.1:6666

function! Perl_flipOperator() range
    Nvimx_notify('load_plugin', 'FlipOperator' )
    Nvimx_request('flip_operator', a:firstline, a:lastline, getline( a:firstline, a:lastline ) )
endfunction

au FileType perl map  <buffer> <leader>fo (v):call Perl_flipOperator()<CR>
au FileType perl vmap <buffer> <leader>fo :call Perl_flipOperator()<CR>

" General Neovim::RPC stuff

let g:nvimx_jobid = get(g:, 'nvimx_jobid', 0)

function! Nvimx_start()
    if !g:nvimx_jobid
        let g:nvimx_jobid = jobstart(['../bin/nvimx.pl', v:servername ])
        if !g:nvimx_jobid
            echo "could not start nvimx"
        endif
    endif
endfunction

function! Nvimx_termstart()
    " we don't want two instances running...
    call Nvimx_stop()
    new
    execute "terminal ../bin/nvimx.pl " . v:servername 
endfunction

function! Nvimx_stop()
    if g:nvimx_jobid 
        call jobstop( g:nvimx_jobid )
        let g:nvimx_jobid=0
    endif
endfunction

function! Nvimx_restart()
    call Nvimx_stop()
    call Nvimx_start()
endfunction

function! Nvimx_notify(...)
    call call( 'rpcnotify',  [g:nvimx_channel]  + a:000 )
endfunction

function! Nvimx_request(...)
    call call( 'rpcrequest',  [g:nvimx_channel]  + a:000 )
endfunction

call Nvimx_start()
