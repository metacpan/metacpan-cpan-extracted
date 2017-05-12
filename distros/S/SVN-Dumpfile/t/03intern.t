# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use Test::More tests => 23;

use IO::Handle;
use SVN::Dumpfile;
ok( 1, 'Module loading' );    # If we made it this far, we're ok.

my $p = 'SVN::Dumpfile';

## test _is_valid_fh()
ok( $p->_is_valid_fh(*STDIN) );
ok( $p->_is_valid_fh(\*STDIN) );
ok( $p->_is_valid_fh(new IO::Handle) );

# test it with other values and refs
ok(  $p->_is_valid_fh(STDIN) );
ok(  $p->_is_valid_fh('STDIN') );
ok( !$p->_is_valid_fh('file name') );
ok( !$p->_is_valid_fh( { hash => 'ref' } ) );
ok( !$p->_is_valid_fh( [ 'array', 'ref' ] ) );
ok( !$p->_is_valid_fh( sub { shift() + 1 } ) );
ok( !$p->_is_valid_fh( do { my $s; \$s } ) );

## test _is_stdin()
ok( $p->_is_stdin() );
ok( $p->_is_stdin('') );
ok( $p->_is_stdin(undef) );
ok( $p->_is_stdin('-') );
ok( $p->_is_stdin('STDIN') );
ok( !$p->_is_stdin('filename') );

## test _is_stdout()
ok( $p->_is_stdout() );
ok( $p->_is_stdout('') );
ok( $p->_is_stdout(undef) );
ok( $p->_is_stdout('-') );
ok( $p->_is_stdout('STDOUT') );
ok( !$p->_is_stdout('filename') );


