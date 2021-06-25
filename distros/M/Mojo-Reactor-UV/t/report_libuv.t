use Mojo::Base -strict;
use Test::Needs 'Alien::libuv';
use Test::More;

diag "\nLibUV information:";
diag "version        = ", Alien::libuv->config('version');
diag "cflags         = ", Alien::libuv->cflags;
diag "cflags_static  = ", Alien::libuv->cflags_static;
diag "libs           = ", Alien::libuv->libs;
diag "libs_static    = ", Alien::libuv->libs_static;
diag "bin_dir        = ", $_ for Alien::libuv->bin_dir;
diag "Install type   = ", Alien::libuv->install_type;

pass('Reported LibUV information');

done_testing;
