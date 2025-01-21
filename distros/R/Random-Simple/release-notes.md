# How to do a new release of a module

### Start clean
`make realclean`

### Generate the Makefile again
`perl Makefile.PL`

### Install the XS version
`make install`

### Run the tests
`make test`

### Run the tests faster
`prove -I lib -lv t/*.t`

### Make the .tar.gz
`make tardist`

### Upload .tar.gz to PAUSE
https://pause.cpan.org/pause/authenquery
