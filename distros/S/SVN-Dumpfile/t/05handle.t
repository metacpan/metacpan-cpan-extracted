use strict;
use warnings;

use Test::More tests => 17;
use SVN::Dumpfile;

isa_ok( SVN::Dumpfile->_is_valid_fh( new IO::Handle ), 'IO::Handle' );

isa_ok( SVN::Dumpfile->_is_valid_fh( *STDIN{IO} ), 'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh(*STDIN),       'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh( \*STDIN ),    'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh('STDIN'),      'IO::Handle' );

isa_ok( SVN::Dumpfile->_is_valid_fh( *STDOUT{IO} ), 'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh(*STDOUT),       'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh( \*STDOUT ),    'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh('STDOUT'),      'IO::Handle' );

ok( !SVN::Dumpfile->_is_valid_fh( *NONE{IO} ) );
ok( !SVN::Dumpfile->_is_valid_fh(*NONE) );
ok( !SVN::Dumpfile->_is_valid_fh( \*NONE ) );
ok( !SVN::Dumpfile->_is_valid_fh('NONE') );

eval "open (NONE, \"<$0\");";

isa_ok( SVN::Dumpfile->_is_valid_fh( *NONE{IO} ), 'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh(*NONE),       'IO::Handle' );
isa_ok( SVN::Dumpfile->_is_valid_fh( \*NONE ),    'IO::Handle' );
ok( !eval { SVN::Dumpfile->_is_valid_fh('NONE')->isa('IO::Handle') } );

