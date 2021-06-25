#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use lib './lib';
    use_ok( 'Module::Generic::Finfo', ':all' ) || BAIL_OUT( "Unable to load Module::Generic::Finfo" );
    use constant FINFO_DEV => 0;
    use constant FINFO_INODE => 1;
    use constant FINFO_MODE => 2;
    use constant FINFO_NLINK => 3;
    use constant FINFO_UID => 4;
    use constant FINFO_GID => 5;
    use constant FINFO_RDEV => 6;
    use constant FINFO_SIZE => 7;
    use constant FINFO_ATIME => 8;
    use constant FINFO_MTIME => 9;
    use constant FINFO_CTIME => 10;
#     use constant FINFO_BLOCK_SIZE => 11;
#     use constant FINFO_BLOCKS => 12;
    our $DEBUG = 0;
    our $IS_WINDOWS_OS = ( $^O =~ /^(dos|mswin32|NetWare|symbian|win32)$/i );
};

my $file;
if( $IS_WINDOWS_OS )
{
    $file = '.\t\test.bat';
}
else
{
    $file = './t/test.pl';
}
my $f = Module::Generic::Finfo->new( $file, debug => $DEBUG );
isa_ok( $f, 'Module::Generic::Finfo' );

{
    no warnings 'Module::Generic::Finfo';
    my $failed = Module::Generic::Finfo->new( './not-existing.txt' );
    ok( defined( $failed ), 'Non-existing file' );
    ok( $failed->filetype == Module::Generic::Finfo::FILETYPE_NOFILE, 'Non-existing file type' );
};

ok( FILETYPE_REG == Module::Generic::Finfo::FILETYPE_REG && FILETYPE_SOCK == Module::Generic::Finfo::FILETYPE_SOCK, 'import of constants' );

my @finfo = CORE::stat( $file );
my $grname = scalar( CORE::getgrgid( $finfo[ FINFO_GID ] ) );
my $usrname = scalar( CORE::getpwuid( $finfo[ FINFO_UID ] ) );
is( $f->size, $finfo[ FINFO_SIZE ], 'size' );
is( $f->csize, $finfo[ FINFO_SIZE ], 'csize' );

is( $f->device, $finfo[ FINFO_DEV ], 'device' );

is( $f->filetype, Module::Generic::Finfo::FILETYPE_REG, 'file type' );

is( $f->fname, $file, 'file name' );

is( $f->gid, $finfo[ FINFO_GID ], 'gid' );

SKIP:
{
    if( $IS_WINDOWS_OS )
    {
        skip( "Not available on Windows platforms", 1 );
    }
    my $name_found = $f->group;
    diag( "Group name is defined? ", defined( $name_found ) ? 'yes' : 'no' ) if( $DEBUG );
    is( $name_found->scalar, $grname, 'group' );
};

is( $f->inode, $finfo[ FINFO_INODE ], 'inode' );

is( $f->mode, ( $finfo[ FINFO_MODE ] & 07777 ), 'mode' );

if( $IS_WINDOWS_OS )
{
    is( $f->name, 'test.bat', 'file base name' );
}
else
{
    is( $f->name, 'test.pl', 'file base name' );
}

is( $f->nlink, $finfo[ FINFO_NLINK ], 'nlink' );

is( $f->protection, hex( sprintf( '%04o', ( $finfo[ FINFO_MODE ] & 07777 ) ) ), 'File mode in hexadecimal' );

my $new = $f->stat( __FILE__ );
isa_ok( $new, 'Module::Generic::Finfo', 'stat' );

is( $f->uid, $finfo[ FINFO_UID ], 'uid' );

SKIP:
{
    if( $IS_WINDOWS_OS )
    {
        skip( "Not available on Windows platforms", 1 );
    }
    my $name_found = $f->user;
    is( $name_found->scalar, $usrname, 'user' );
};

diag( "Checking finfo atime (", $f->atime, ") against file atime (", $finfo[ FINFO_ATIME ], ")." ) if( $DEBUG );
is( $f->atime, $finfo[ FINFO_ATIME ], 'atime' );

is( $f->mtime, $finfo[ FINFO_MTIME ], 'mtime' );

is( $f->ctime, $finfo[ FINFO_CTIME ], 'ctime' );

ok( $f->is_file, 'is_file' );

ok( !$f->is_block, 'is_block' );

ok( !$f->is_char, 'is_char' );

ok( !$f->is_dir, 'is_dir' );

my $dir = Module::Generic::Finfo->new( './' );
ok( $dir->is_dir, 'is_dir2' );

ok( !$f->is_link, 'is_link' );

ok( !$f->is_pipe, 'is_pipe' );

ok( !$f->is_socket, 'is_socket' );

ok( $f->can_read, 'can_read' );

if( $f->uid == $> || $> == 0 )
{
    ok( $f->can_write, 'can_write' );
}
else
{
    ok( !$f->can_write, 'can_write' );
}

ok( $f->can_execute, 'can_execute' );

done_testing();
