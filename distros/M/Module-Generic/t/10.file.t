#!/usr/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use lib './lib';
    use_ok( 'Module::Generic::File', qw( file cwd tempfile tempdir ) );
    use Cwd ();
    use Digest::SHA;
    use Encode ();
    use File::Spec ();
    use Nice::Try;
    our $DEBUG = 0;
};

CORE::chdir( File::Spec->tmpdir );

my $f = Module::Generic::File->new( "plop$$.txt" );
isa_ok( $f, 'Module::Generic::File', 'creating object' );

is( $f->filepath, File::Spec->rel2abs( "plop$$.txt" ), 'abs' );

my $cwd = cwd();
is( $cwd, Cwd::cwd(), 'cwd' );

my $tmpdir = tempdir;
ok( ( -e( $tmpdir ) && -d( $tmpdir ) ), 'tempdir' );
ok( $tmpdir->chdir, 'chdir' );
is( cwd(), $tmpdir, 'chdir -> cwd' );
$tmpdir->debug( $DEBUG );
my $rv = $tmpdir->chmod( 0700 );
$rv or diag( $tmpdir->error );
ok( $rv, 'chmod' );
is( $tmpdir->finfo->mode, 0700, 'chmod' );
ok( $tmpdir->is_empty, 'is_empty' );
is( $tmpdir->code, 200, 'code' );
$tmpdir->cleanup(1);

# Theoretical move since the file does not yet exist
diag( "Moving file $f to $tmpdir" ) if( $DEBUG );
$f->debug( $DEBUG );
my $f2 = $f->move( $tmpdir ) || do
{
    diag( $f->error ) if( $DEBUG );
};
isa_ok( $f2, 'Module::Generic::File', 'moved object class' );
my $expected_location = File::Spec->catpath( $f->volume, $tmpdir, $f->basename );
is( "$f2", $expected_location, 'moved file new path' );
if( $expected_location eq "$f2" )
{
    diag( "File $f has now moved to $f2" ) if( $DEBUG );
    $f2->debug( $DEBUG );
    my $io = $f2->open( '+>' );
    diag( $f2->error ) if( !defined( $io ) && $DEBUG );
    isa_ok( $io, 'IO::File', 'opened filehandle object class' );
    $io->print( join( "\n", ( 'line 1', 'line 2', '' ) ) ) || BAIL_OUT( "Unable to write to file \"$f2\": $!" );
    my $pos = $io->tell;
    diag( "File $f2 size is: ", -s( $f2 ) ) if( $DEBUG );
    # XXX Update this with actual number returned
    is( $f2->length, 14, 'file size' );
    my $lines = $f2->content;
    isa_ok( $lines, 'Module::Generic::Array', 'content as array object' );
    is( $lines->length, 2, 'content lines' );
    my $files = $tmpdir->content;
    diag( $tmpdir->error ) if( !defined( $files ) && $DEBUG );
    is( $files->length, 1, 'directory files total' );
    is( $files->first, "$f2", 'directory content as absolute files path' );
    ok( $tmpdir->contains( $f2 ), 'contains' );
}

my $mydir = tempdir({debug => $DEBUG, cleanup => 1});
my $dircopy = $mydir;
diag( "Temporary directory is '$mydir'" ) if( $DEBUG );
for( 1..3 )
{
    $mydir = $mydir->child( $_ );
}
diag( "New path is '$mydir'" ) if( $DEBUG );
is( "$mydir", File::Spec->catpath( $mydir->volume, File::Spec->catdir( $dircopy, 1, 2, 3 ) ), "combined path" );
my $frags = $mydir->mkpath;
diag( "mkpath error: ", $mydir->error ) if( $DEBUG && !defined( $frags ) );
isa_ok( $frags, 'Module::Generic::Array', 'mkpath returned object' );
ok( -d( "$mydir" ), "$mydir has been created" );

subtest 'basename' => sub
{
    my $tests = 
    [
        {
            file   => 'foo.txt',
            ext    => [qw( .txt .png )],
            expect => 'foo',
        },
        {
            file   => 'foo.png',
            ext    => [qw( .txt .png )],
            expect => 'foo',
        },
        {
            file   => 'foo.txt',
            ext    => [qr/\.txt/, qr/\.png/],
            expect => 'foo',
        },
        {
            file   => 'foo.png',
            ext    => [qr/\.txt/, qr/\.png/],
            expect => 'foo',
        },
        {
            file   => 'foo.txt',
            ext    => [qw( .jpeg foo.txt )],
            expect => '',
        },
        {
            file   => 'foo/.txt/bar.txt',
            ext    => [qr/\.txt/, qr/\.png/],
            expect => 'bar',
        },
    ];
    foreach my $t ( @$tests )
    {
        my $f = Module::Generic::File->new( $t->{file}, debug => $DEBUG ) || do
        {
            fail( "create object for \"$t->{file}\"" );
            next;
        };
        my $rv = $f->basename( $t->{ext} );
        isnt( $rv, undef() );
        isa_ok( $rv, 'Module::Generic::Scalar', 'returning a scalar object' );
        is( $rv, $t->{expect}, "$t->{file} -> $t->{expect}" );
    }
};

subtest 'children' => sub
{
    my $tmpdir = tempdir({cleanup => 1});
    diag( "Temporary directory is set to '$tmpdir'" ) if( $DEBUG );;
    diag( "Creating object for \"$tmpdir\" with debug set to $DEBUG" ) if( $DEBUG );
    my $d = file( $tmpdir, debug => $DEBUG )->mkpath->first;
    diag( "Error creating object for \"$tmpdir\": ", Module::Generic::File->error ) if( $DEBUG && !defined( $d ) );
    isa_ok( $d, 'Module::Generic::File', 'mkpath resulting object' );
    ok( ( -e( $d ) && -d( $d ) ), 'temporary directory created' );
    my @files = ();
    my $n_files = 3;
    for( 1..$n_files )
    {
        my $f = $d->child( "file${_}.txt" )->touch;
        $f->debug( $DEBUG );
        push( @files, $f ) if( $f );
        isa_ok( $f, 'Module::Generic::File', "File No ${_} created is object" );
        SKIP:
        {
            skip( "File No ${_} could not be touched, skipping.", 3 ) if( !$f );
            next FILES if( !$f );
            ok( $f->exists, "touched file No ${_} exists" );
            is( $f->code, 201, 'code created' );
            ok( $f->is_part_of( $d ), 'is_part_of' );
        }
    }
    
    SKIP:
    {
        ok( scalar( @files ) == $n_files, 'test files touched' );
        scalar( @files ) == $n_files or skip( "File No ${_} could not be touched, skipping.", 4 );
        my $ok_isa    = 0;
        my $ok_exists = 0;
        my $is_empty  = 0;
        my $ok_contained = 0;
        for( @files )
        {
            if( $_->isa( 'Module::Generic::File' ) )
            {
                $ok_isa++;
                $ok_exists++ if( $_->exists );
                $is_empty++ if( $_->is_empty );
                $ok_contained++ if( $tmpdir->contains( $_ ) );
            }
        }
        is( $ok_isa, $n_files, 'touched files are objects' );
        is( $ok_exists, $n_files, 'touched files exist' );
        is( $is_empty, $n_files, 'touched files are empty' );
        is( $ok_contained, $n_files, 'contains' );
    };
};

subtest 'collapse_dots' => sub
{
    # Based on RFC 3986 sectin 5.2.4 algorithm, flattening the dots such as '.' and '..' in uri path
    my $tests =
    [
        '/'                                                         => '/',
        '/../a/b/../c/./d.html'                                     => '/a/c/d.html',
        '/../a/b/../c/./d.html?foo=../bar'                          => '/a/c/d.html?foo=../bar',
        '/foo/../bar'                                               => '/bar',
        '/foo/../bar/'                                              => '/bar/',
        '/../foo'                                                   => '/foo',
        '/../foo/..'                                                => '/',
        '/../../'                                                   => '/',
        '/../../foo'                                                => '/foo',
        '/some.cgi/path/info/http://www.example.org/tag/john+doe'   => '/some.cgi/path/info/http://www.example.org/tag/john+doe',
        '/a/b/../../index.html'                                     => '/index.html',
        '/a/../b'                                                   => '/b',
        '/a/.../b'                                                  => '/a/.../b',
        './a//b'                                                    => '/a//b',
        '/path/page/#anchor'                                        => '/path/page/#anchor',
        '/path/page/../#anchor'                                     => '/path/#anchor',
        '/path/page/#anchor/page'                                   => '/path/page/#anchor/page',
        '/path/page/../#anchor/page'                                => '/path/#anchor/page',
    ];
    
    my $dummy = file( 'dummy.txt' );
    isa_ok( $dummy, 'Module::Generic::File', 'instantiating object' );
    for( my $i = 0; $i < scalar( @$tests ); $i += 2 )
    {
        my $test = $tests->[$i];
        my $check = $tests->[$i + 1];
        my $res = $dummy->collapse_dots( $test );
        ok( $res eq $check, "$test => $check" . ( $res ne $check ? " [failed with $res]" : '' ) );
    }
};

CORE::chdir( File::Spec->tmpdir );
my $tmpname = $f->tmpname( suffix => '.txt' );
diag( "temporary file name: $tmpname" ) if( $DEBUG );
my $f3 = $f->abs( $tmpname );
$f3->debug( $DEBUG );
diag( "$tmpname is $f3" ) if( $DEBUG );
my $sys_tmpdir = $f->sys_tmpdir;
my $f4 = $f3->move( $sys_tmpdir )->touch;
is( $f4, File::Spec->catfile( File::Spec->tmpdir, $f3->basename ), 'move' );
my $io = $f4->open;
ok( $io, 'open file in read mode' );
$f4->debug( $DEBUG );
if( $io )
{
    ok( $f4->can_read, 'can read' );
    ok( !$f4->can_write, 'cannot write' );
    $f4->close;
    ok( !$f4->opened, 'close' );
}

is( $f4->code, 201, 'code' );
is( $f4->length, 0, 'no content' );


ok( $f4->changed, 'changed' );
ok( $f4->delete, 'delete' );
ok( !$f4->exists, 'file does not exist anymore' );
is( $f4->code, 410, 'code: file is gone' );

my $here = cwd();
is( $here, Cwd::cwd(), 'cwd' );
ok( !$f4->chdir, 'file cannot chdir' );

use utf8;
my $data = <<EOT;
Mignonne, allons voir si la rose
Qui ce matin avoit desclose
Sa robe de pourpre au Soleil,
A point perdu cette vesprée
Les plis de sa robe pourprée,
Et son teint au vostre pareil.
EOT
my $f5 = tempfile({ suffix => '.txt', auto_remove => 1 })->move( File::Spec->tmpdir );
if( $f5 )
{
    SKIP:
    {
        try
        {
            require Digest::SHA;
            # $data = Encode::decode_utf8( $data ) if( !Encode::is_utf8( $data ) );
            my $digest_sha256 = Digest::SHA::sha256_hex( $data );
            diag( "digest sha 256 is '$digest_sha256'" ) if( $DEBUG );
            $f5->debug( $DEBUG );
            $f5->open( '+>', { binmode => 'utf8' } );
            $f5->seek( 0, 0 ) || do
            {
                diag( $f5->error ) if( $DEBUG );
            };
            $f5->truncate( $f5->tell );
            $f5->append( $data );
            diag( "File $f5 is ", $f5->length, " bytes big." ) if( $DEBUG );
            is( $f5->length, length( Encode::encode_utf8( $data ) ), 'size' );
            my $digest = $f5->digest( 'sha256' );
            is( $digest, $digest_sha256, 'digest sha256' );
            $f5->close;
        }
        catch( $e )
        {
            diag( "The following error occurred: $e" ) if( $DEBUG );
            skip( "Digest::SHA not available on your system" );
        }
    }

    SKIP:
    {
        try
        {
            require Digest::SHA2;
            # $data = Encode::decode_utf8( $data ) if( !Encode::is_utf8( $data ) );
            my $digest_sha512 = Digest::SHA2::sha512_hex( $data );
            diag( "digest md5 is '$digest_sha512'" ) if( $DEBUG );
            $f5->debug( $DEBUG );
            $f5->open( '+>', { binmode => 'utf8' } );
            $f5->seek( 0, 0 ) || do
            {
                diag( $f5->error ) if( $DEBUG );
            };
            $f5->truncate( $f5->tell );
            $f5->append( $data );
            is( $f5->length, length( Encode::encode_utf8( $data ) ), 'size' );
            my $digest = $f5->digest( 'sha512' );
            is( $digest, $digest_sha512, 'digest sha512' );
            $f5->close;
        }
        catch( $e )
        {
            diag( "The following error occurred: $e" ) if( $DEBUG );
            skip( "Digest::SHA2 not available on your system" );
        }
    }

    SKIP:
    {
        try
        {
            require Digest::MD5;
            # $data = Encode::decode_utf8( $data ) if( !Encode::is_utf8( $data ) );
            my $digest_md5 = Digest::MD5::md5_hex( Encode::encode_utf8( $data ) );
            diag( "digest md5 is '$digest_md5'" ) if( $DEBUG );
            $f5->debug( $DEBUG );
            $f5->open( '+>', { binmode => 'utf8' } );
            $f5->seek( 0, 0 ) || die( $f5->error );
            diag( "Getting position in file, calling tell for file $f5" ) if( $DEBUG );
            $f5->truncate( $f5->tell );
            $f5->append( $data );
            is( $f5->length, length( Encode::encode_utf8( $data ) ), 'size' );
            my $digest = $f5->digest( 'md5' );
            is( $digest, $digest_md5, 'digest md5' );
            $f5->close;
        }
        catch( $e )
        {
            diag( "The following error occurred: $e" ) if( $DEBUG );
            skip( "Digest::MD5 not available on your system" );
        }
    }
    
    $f5->empty;
    is( $f5->length, 0, 'empty' );
    ok( $f5->is_empty, 'is_empty' );
}

my $f6 = tempfile({ suffix => '.txt' });
diag( "Temporary file is $f6" ) if( $DEBUG );
$f6->auto_remove(1);
$f6->open( 'w+', { binmode => 'utf8' } );
ok( $f6, 'file opened with w+' );
my $rv = $f6->write( $data );
ok( $rv, 'write' );
my $lines = $f6->lines;
isa_ok( $lines, 'Module::Generic::Array', 'lines returned as array object' );
$f6->close;
is( $lines->length, scalar( split( /\n/, $data ) ), 'number of lines' );

my $text = $f6->load({ binmode => 'utf8' });
is( $text, $data, 'load' );
$f6->append( "\nPierre de Ronsard\n" );
my $new_text = $f6->load_utf8;
is( $new_text, "${data}\nPierre de Ronsard\n", 'append' );

my $tmpfile2 = Module::Generic::File->tempfile( cleanup => 1 );
isa_ok( $tmpfile2, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File->tempfile' );
diag( "Temporary file created is: $tmpfile2" ) if( $DEBUG );
is( $tmpfile2->extension->length, 0, 'no extension' );

my $tmpfile3 = Module::Generic::File->tempfile( suffix => '.txt', cleanup => 1 );
isa_ok( $tmpfile3, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File->tempfile( %options )' );
diag( "Temporary file created is: $tmpfile3" ) if( $DEBUG );
is( $tmpfile3->extension->length, 3, 'extension length' );
is( $tmpfile3->extension->scalar, 'txt', 'extension -> txt' );

my $tmpfile4 = Module::Generic::File->tempfile({ suffix => '.txt', cleanup => 1 });
isa_ok( $tmpfile4, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File->tempfile( \%options )' );
diag( "Temporary file created is: $tmpfile4" ) if( $DEBUG );
is( $tmpfile4->extension->length, 3, 'extension length' );
is( $tmpfile4->extension->scalar, 'txt', 'extension -> txt' );

my $tmpfile5 = Module::Generic::File::tempfile( cleanup => 1 );
isa_ok( $tmpfile5, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File::tempfile' );
diag( "Temporary file created is: $tmpfile5" ) if( $DEBUG );
is( $tmpfile5->extension->length, 0, 'no extension' );

my $tmpfile6 = Module::Generic::File::tempfile( suffix => '.txt', cleanup => 1 );
isa_ok( $tmpfile6, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File::tempfile( %options )' );
diag( "Temporary file created is: $tmpfile6" ) if( $DEBUG );
is( $tmpfile6->extension->length, 3, 'extension length' );
is( $tmpfile6->extension->scalar, 'txt', 'extension -> txt' );

my $tmpfile7 = Module::Generic::File::tempfile({ suffix => '.txt', cleanup => 1 });
isa_ok( $tmpfile7, 'Module::Generic::File', 'tempfile accessed using Module::Generic::File::tempfile( \%options )' );
diag( "Temporary file created is: $tmpfile7" ) if( $DEBUG );
is( $tmpfile7->extension->length, 3, 'extension length' );
is( $tmpfile7->extension->scalar, 'txt', 'extension -> txt' );

my $tmpfile8 = $tmpfile7->tempfile( cleanup => 1 );
isa_ok( $tmpfile8, 'Module::Generic::File', 'tempfile accessed using $obj->tempfile' );
diag( "Temporary file created is: $tmpfile8" ) if( $DEBUG );
is( $tmpfile8->extension->length, 0, 'no extension' );

my $tmpfile9 = $tmpfile7->tempfile( suffix => '.txt', cleanup => 1 );
isa_ok( $tmpfile9, 'Module::Generic::File', 'tempfile accessed using $obj->tempfile( %options )' );
diag( "Temporary file created is: $tmpfile9" ) if( $DEBUG );
is( $tmpfile9->extension->length, 3, 'extension length' );
is( $tmpfile9->extension->scalar, 'txt', 'extension -> txt' );

my $tmpfile10 = $tmpfile7->tempfile({ suffix => '.txt', cleanup => 1 });
isa_ok( $tmpfile10, 'Module::Generic::File', 'tempfile accessed using $obj->tempfile( \%options )' );
diag( "Temporary file created is: $tmpfile10" ) if( $DEBUG );
is( $tmpfile10->extension->length, 3, 'extension length' );
is( $tmpfile10->extension->scalar, 'txt', 'extension -> txt' );


my $tmpdir1 = Module::Generic::File->tempdir( cleanup => 1 );
isa_ok( $tmpdir1, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File->tempdir' );
diag( "Temporary directory created is: $tmpdir1" ) if( $DEBUG );

my $tmpdir2 = Module::Generic::File->tempdir( cleanup => 1 );
isa_ok( $tmpdir2, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File->tempdir( %options )' );
diag( "Temporary directory created is: $tmpdir2" ) if( $DEBUG );

my $tmpdir3 = Module::Generic::File->tempdir({ cleanup => 1 });
isa_ok( $tmpdir3, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File->tempdir( \%options )' );
diag( "Temporary directory created is: $tmpdir3" ) if( $DEBUG );

my $tmpdir4 = Module::Generic::File::tempdir( cleanup => 1 );
isa_ok( $tmpdir4, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File::tempdir' );
diag( "Temporary directory created is: $tmpdir4" ) if( $DEBUG );

my $tmpdir5 = Module::Generic::File::tempdir( cleanup => 1 );
isa_ok( $tmpdir5, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File::tempdir( %options )' );
diag( "Temporary directory created is: $tmpdir5" ) if( $DEBUG );

my $tmpdir6 = Module::Generic::File::tempdir({ cleanup => 1 });
isa_ok( $tmpdir6, 'Module::Generic::File', 'tempdir accessed using Module::Generic::File::tempdir( \%options )' );
diag( "Temporary directory created is: $tmpdir6" ) if( $DEBUG );

my $tmpdir7 = $tmpdir1->tempdir( cleanup => 1 );
isa_ok( $tmpdir7, 'Module::Generic::File', 'tempdir accessed using $object->tempdir' );
diag( "Temporary directory created is: $tmpdir7" ) if( $DEBUG );

my $tmpdir8 = $tmpdir1->tempdir( cleanup => 1 );
isa_ok( $tmpdir8, 'Module::Generic::File', 'tempdir accessed using $object->tempdir( %options )' );
diag( "Temporary directory created is: $tmpdir8" ) if( $DEBUG );

my $tmpdir9 = $tmpdir1->tempdir({ cleanup => 1 });
isa_ok( $tmpdir9, 'Module::Generic::File', 'tempdir accessed using $object->tempdir( \%options )' );
diag( "Temporary directory created is: $tmpdir9" ) if( $DEBUG );

# require Module::Generic;
# my $this = Module::Generic->new( debug => 3 );
# my $tmpfile11 = $this->new_tempfile( suffix => ".txt", tmpdir => 1, cleanup => 0 );
# diag( "Temporary file is '$tmpfile11'." );

done_testing();


__END__

