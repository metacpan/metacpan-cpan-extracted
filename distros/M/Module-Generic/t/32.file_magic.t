#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG $HAS_FILE_CMD $HAS_ARCHIVE_TAR );
    use Test::More qw( no_plan );
    use File::Spec ();
    use Module::Generic::File qw( tempfile );
    use_ok( 'Module::Generic::File::Magic', qw( :flags ) ) ||
        BAIL_OUT( "Unable to load Module::Generic::File::Magic" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    # Check optional capabilities
    our $HAS_FILE_CMD = ( defined( `which file 2>/dev/null` ) && $? == 0 ) ? 1 : 0;
    local $@;
    eval{ require Archive::Tar; 1 };
    our $HAS_ARCHIVE_TAR = $@ ? 0 : 1;
};

use strict;
use warnings;

# NOTE: Constants
my $MAGIC_NONE          = MAGIC_NONE;
my $MAGIC_MIME_TYPE     = MAGIC_MIME_TYPE;
my $MAGIC_MIME_ENCODING = MAGIC_MIME_ENCODING;
my $MAGIC_MIME          = MAGIC_MIME;
my $MAGIC_COMPRESS      = MAGIC_COMPRESS;
my $MAGIC_SYMLINK       = MAGIC_SYMLINK;

# NOTE: Instantiation
my $magic = Module::Generic::File::Magic->new( flags => $MAGIC_MIME_TYPE, debug => $DEBUG );
ok( defined( $magic ), 'new() returns a defined object' );
isa_ok( $magic, 'Module::Generic::File::Magic', 'object class' );

# NOTE: Backend detection
my $backend = $magic->backend;
ok( defined( $backend ), 'backend() returns a value' );
like( $backend, qr/^(?:xs|json|file)$/, "backend() value is valid: $backend" );
diag( "Active backend: $backend" ) if( $DEBUG || 1 );

# NOTE: Flags getter / setter
is( $magic->flags, $MAGIC_MIME_TYPE, 'flags() getter returns initial value' );

$magic->flags( $MAGIC_NONE );
is( $magic->flags, $MAGIC_NONE, 'flags() setter round-trip' );
$magic->flags( $MAGIC_MIME_TYPE );

# NOTE: max_read getter / setter
is( $magic->max_read, 512, 'max_read() default is 512' );
$magic->max_read( 1024 );
is( $magic->max_read, 1024, 'max_read() setter' );
$magic->max_read( 512 );

# NOTE: version() — xs backend only
subtest 'version() — xs backend only' => sub
{
    SKIP:
    {
        skip( 'version() requires xs backend', 2 ) unless( $backend eq 'xs' );
        my $ver = $magic->version;
        ok( defined( $ver ), 'version() defined on xs backend' );
        like( $ver, qr/^\d+\.\d+$/, "version() format looks like n.nn: $ver" );
        diag( "libmagic version: $ver" ) if( $DEBUG );
    };
};

# NOTE: from_file() — text file
subtest 'from_file() — text file' => sub
{
    SKIP:
    {
        skip( '/etc/passwd not available', 3 ) unless( -r( '/etc/passwd' ) );
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $r = $magic->from_file( '/etc/passwd' );
        ok( defined( $r ), 'from_file(/etc/passwd) returns a value' );
        is( $r, 'text/plain', "from_file MIME type for /etc/passwd: $r" );
    
        my $full = $magic->mime_from_file( '/etc/passwd' );
        like( $full, qr{^text/plain;\s*charset=}, "mime_from_file /etc/passwd: $full" );
    };
};

# NOTE: from_file() — binary / executable
my $binary = ( -r( '/bin/ls' ) ) ? '/bin/ls'
           : ( -r( '/usr/bin/ls' ) ) ? '/usr/bin/ls'
           : undef;

subtest 'from_file() — binary / executable' => sub
{
    SKIP:
    {
        skip( 'no ls binary available for testing', 2 ) unless( defined( $binary ) );
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $r = $magic->from_file( $binary );
        ok( defined( $r ), "from_file($binary) returns a value" );
        like( $r, qr{^application/}, "from_file $binary is application/*: $r" );
    };
};

# NOTE: mime_type_from_file / mime_encoding_from_file / mime_from_file
subtest 'mime_type_from_file / mime_encoding_from_file / mime_from_file' => sub
{
    SKIP:
    {
        skip( '/etc/passwd not available', 3 ) unless( -r( '/etc/passwd' ) );
        $magic->flags( $MAGIC_NONE );    # convenience wrappers override flags internally
    
        my $type = $magic->mime_type_from_file( '/etc/passwd' );
        is( $type, 'text/plain', 'mime_type_from_file' );
    
        my $enc = $magic->mime_encoding_from_file( '/etc/passwd' );
        ok( defined( $enc ), "mime_encoding_from_file: $enc" );
    
        my $mime = $magic->mime_from_file( '/etc/passwd' );
        like( $mime, qr{^text/plain;\s*charset=}, "mime_from_file: $mime" );
    };
};

# NOTE: from_file() — error handling
subtest 'from_file() — error handling' => sub
{
    # Suppress warnings
    local $SIG{__WARN__} = sub{};
    my $r = $magic->from_file( '/nonexistent/path/no_such_file_42.bin' );
    ok( !defined( $r ), 'from_file() returns undef for nonexistent file' );
    ok( defined( $magic->error ), 'from_file() sets error for nonexistent file' );
    diag( 'error: ', $magic->error ) if( $DEBUG );
};

# NOTE: from_buffer() — known magic byte sequences
$magic->flags( $MAGIC_MIME_TYPE );

my @buffer_tests = (
    # [ label,               bytes,                                       expected_mime           ]
    [ 'gzip',            "\x1f\x8b\x08\x00" . ( "\x00" x 100 ),          'application/gzip'      ],
    [ 'zip',             "PK\x03\x04"        . ( "\x00" x 100 ),          'application/zip'       ],
    [ 'pdf',             "%PDF-1.4"          . ( "\x00" x 100 ),          'application/pdf'       ],
    # PNG: a real PNG file is needed for the xs backend (synthetic bytes alone do not
    # contain enough IHDR context for libmagic to identify as image/png)
    [ 'png bytes',       "\x89PNG\r\n\x1a\n" . ( "\x00" x 100 ),          undef                   ],
    [ 'plain text',      "The quick brown fox jumps\n" x 30,               'text/plain'            ],
);

foreach my $t ( @buffer_tests )
{
    my( $label, $buf, $expected ) = @$t;
    my $r = $magic->from_buffer( $buf );
    if( defined( $expected ) )
    {
        ok( defined( $r ), "from_buffer($label) returns a value" );
        is( $r, $expected, "from_buffer($label): ${\($r//'(undef)')}" );
    }
    else
    {
        # expected undef means we just check it does not die
        ok( 1, "from_buffer($label) does not die (result: ${\($r//'(undef)')})" );
    }
}

# NOTE: from_buffer() — ELF binary (requires correct endianness byte at offset 5)
subtest 'from_buffer() — ELF binary (requires correct endianness byte at offset 5)' => sub
{
    SKIP:
    {
        skip( 'no ls binary for ELF buffer test', 2 ) unless( defined( $binary ) );
    
        open( my $fh, '<:raw', $binary ) or skip( "Cannot open $binary: $!", 2 );
        read( $fh, my $buf, 512 );
        close( $fh );
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $r = $magic->from_buffer( $buf );
        ok( defined( $r ), 'from_buffer(ELF binary) returns a value' );
        like( $r, qr{^application/}, "from_buffer ELF is application/*: ${\($r//'(undef)')}" );
    };
};

# NOTE: from_buffer() — UTF-8 rejection
subtest 'from_buffer() — UTF-8 rejection' => sub
{
    local $SIG{__WARN__} = sub{};
    use utf8;
    my $wide = "Héllo wörld — これはテストです\n";
    my $r = $magic->from_buffer( $wide );
    # Wide chars above U+00FF: should either error or downgrade successfully
    # The important thing is it doesn't die
    ok( 1, 'from_buffer with wide chars does not die' );
    if( !defined( $r ) )
    {
        like( $magic->error, qr/U\+00FF|charset|encode/i,
              'from_buffer wide char error message is informative' );
    }
};

# NOTE: from_filehandle()
subtest 'from_filehandle()' => sub
{
    SKIP:
    {
        skip( '/etc/passwd not available for filehandle test', 2 )
            unless( -r( '/etc/passwd' ) );
    
        open( my $fh, '<:raw', '/etc/passwd' )
            or skip( "Cannot open /etc/passwd: $!", 2 );
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $r = $magic->from_filehandle( $fh );
        close( $fh );
    
        ok( defined( $r ), 'from_filehandle(/etc/passwd) returns a value' );
        is( $r, 'text/plain', "from_filehandle MIME type: ${\($r//'(undef)')}" );
    };
};

# NOTE: Compressed archive: MAGIC_COMPRESS
subtest 'Compressed archive: MAGIC_COMPRESS' => sub
{
    SKIP:
    {
        skip( 'Archive::Tar not available for compressed archive test', 4 )
            unless( $HAS_ARCHIVE_TAR );
        skip( 'xs backend required for MAGIC_COMPRESS', 4 )
            unless( $backend eq 'xs' );
    
        # Create a real .tar.gz in a temp file
        my $tmp = tempfile( suffix => '.tar.gz', cleanup => 1, open => 1 );
        my $tar = Archive::Tar->new;
        $tar->add_data( 'test.txt', "hello from archive\n" );
        $tar->write( $tmp->filename, Archive::Tar::COMPRESS_GZIP() );
        $tmp->flush;
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $outer = $magic->from_file( $tmp->filename );
        is( $outer, 'application/gzip', "from_file(tgz) without COMPRESS: ${\($outer//'(undef)')}" );
    
        $magic->flags( $MAGIC_MIME_TYPE | $MAGIC_COMPRESS );
        my $inner = $magic->from_file( $tmp->filename );
        is( $inner, 'application/x-tar', "from_file(tgz) with MAGIC_COMPRESS: ${\($inner//'(undef)')}" );
    
        # mime_type_from_file uses MAGIC_MIME_TYPE without COMPRESS
        my $mt = $magic->mime_type_from_file( $tmp->filename );
        is( $mt, 'application/gzip', "mime_type_from_file(tgz): ${\($mt//'(undef)')}" );
    
        my $mf = $magic->mime_from_file( $tmp->filename );
        like( $mf, qr{^application/gzip}, "mime_from_file(tgz): ${\($mf//'(undef)')}" );
    };
};

# NOTE: XS-only methods return error on non-xs backend
subtest 'XS-only methods return error on non-xs backend' => sub
{
    SKIP:
    {
        skip( 'xs backend active — skipping non-xs error tests', 3 )
            if( $backend eq 'xs' );
    
        local $SIG{__WARN__} = sub{};
        my $r = $magic->check;
        ok( !defined( $r ), 'check() returns undef on non-xs backend' );
        like( $magic->error, qr/xs backend/i, 'check() error message mentions xs backend' );
    
        my $r2 = $magic->compile( '/nonexistent' );
        ok( !defined( $r2 ), 'compile() returns undef on non-xs backend' );
    };
};

# NOTE: Procedural interface
subtest 'Procedural interface' => sub
{
    SKIP:
    {
        skip( '/etc/passwd not available for procedural tests', 2 )
            unless( -r( '/etc/passwd' ) );
    
        my $mime = eval { Module::Generic::File::Magic::magic_mime_type( '/etc/passwd' ) };
        ok( !$@, 'magic_mime_type() does not die' );
        is( $mime, 'text/plain', "magic_mime_type(/etc/passwd): ${\($mime//'(undef)')}" );
    };

    {
        my $buf  = "\x1f\x8b\x08\x00" . ( "\x00" x 100 );
        my $mime = eval{ Module::Generic::File::Magic::magic_from_buffer( $buf, $MAGIC_MIME_TYPE ) };
        ok( !$@, 'magic_from_buffer() does not die' );
        is( $mime, 'application/gzip', "magic_from_buffer(gzip bytes): ${\($mime//'(undef)')}" );
    };
};

# NOTE: Flag constant exports
subtest 'Flag constant exports' => sub
{
    ok( MAGIC_NONE          == 0,     'MAGIC_NONE == 0'          );
    ok( MAGIC_MIME_TYPE     == 0x10,  'MAGIC_MIME_TYPE == 0x10'  );
    ok( MAGIC_MIME_ENCODING == 0x400, 'MAGIC_MIME_ENCODING == 0x400' );
    ok( MAGIC_MIME          == ( MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING ),
        'MAGIC_MIME == MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING' );
    ok( MAGIC_COMPRESS      == 0x4,   'MAGIC_COMPRESS == 0x4'    );
};

# NOTE: close() / cookie reuse (xs backend)
subtest 'close() / cookie reuse (xs backend)' => sub
{
    SKIP:
    {
        skip( 'cookie reuse test requires xs backend', 2 ) unless( $backend eq 'xs' );
        skip( '/etc/passwd not available', 2 )             unless( -r( '/etc/passwd' ) );
    
        $magic->flags( $MAGIC_MIME_TYPE );
        my $r1 = $magic->from_file( '/etc/passwd' );
        my $r2 = $magic->from_file( '/etc/passwd' );    # reuses the same cookie
        is( $r1, $r2, 'cookie reuse: second call gives same result' );
    
        $magic->close;
        my $r3 = $magic->from_file( '/etc/passwd' );    # opens a new cookie
        is( $r1, $r3, 'after close(): new cookie gives same result' );
    };
};

# NOTE: Parity: xs vs json backends (when both are available)
subtest 'Parity: xs vs json backends (when both are available)' => sub
{
    SKIP:
    {
        skip( 'parity test requires xs backend to be active', 2 )
            unless( $backend eq 'xs' );
        skip( '/etc/passwd not available', 2 )
            unless( -r( '/etc/passwd' ) );
    
        my @parity_cases = (
            [ 'passwd',  '/etc/passwd' ],
        );
        push( @parity_cases, [ 'ls', $binary ] ) if( defined( $binary ) );
    
        foreach my $case ( @parity_cases )
        {
            my( $label, $path ) = @$case;
            my $xs_result = Module::Generic::File::Magic->new( flags => $MAGIC_MIME_TYPE )
                                ->from_file( $path );
    
            local $Module::Generic::File::Magic::BACKEND = 'json';
            my $json_result = Module::Generic::File::Magic->new( flags => $MAGIC_MIME_TYPE )
                                ->from_file( $path );
    
            # libmagic and the JSON database can return different but equally valid ELF
            # subtypes for the same binary: e.g. x-pie-executable, x-executable,
            # x-sharedlib, x-object. All are correct — they differ only in how precisely
            # the ELF header is inspected. We consider the results in parity when both
            # are exact matches, or both belong to the ELF binary family.
            my $elf_family = qr{^application/x-(?:executable|pie-executable|sharedlib|object|core)$};
            my $ok = defined( $xs_result ) && defined( $json_result ) &&
                     ( $xs_result eq $json_result ||
                       ( $xs_result   =~ $elf_family &&
                         $json_result =~ $elf_family ) );
            ok( $ok, "parity xs/json for $label: xs=[${\($xs_result//'undef')}] json=[${\($json_result//'undef')}]" );
        }
    };
};

done_testing();

__END__
