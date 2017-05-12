au BufRead,BufNewFile *.hbml            setfiletype hbml
au BufRead,BufNewFile * if &ft == 'conf' && getline(1) =~ '^#!.*\<shebangml\>' | set ft=hbml | endif

" ugh, what?
au BufRead,BufNewFile *.hbml if &ft == 'conf' | set ft=hbml | endif
