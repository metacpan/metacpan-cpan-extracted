# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$OP = {file => {'mod'=>'=s',
                'desc'=>'the input file',
                'mand' => 1,
                'default'=>'/bin/cat'
               }};

$OP2 = {dir => {'mod'=>'=s',
                'desc'=>'the input directory',
                'mand' => 1,
                'default'=>'/bin'
               }};

##############################################################################
$op = Script::Toolbox->new( $OP );
is( ref($op), 'Script::Toolbox', 'New' );

($new,$old) = $op->SetOpsDef($OP2);
is( ref($new), 'Script::Toolbox::Util::Opt',	'SetOpsDef 1' );
is( ref($old), 'Script::Toolbox::Util::Opt',	'SetOpsDef 2' );
is( $old->get('file'), '/bin/cat',	'SetOpsDef 3' );
is( $new->get('dir'),  '/bin',		'SetOpsDef 4' );

is( $op->SetOpt('dir', '/usr'), '/bin', 'SetOpt 1' );
is( $op->GetOpt('dir'),'/usr',  'SetOpt 2' );

unlink "/tmp/05_GetSet.log";
