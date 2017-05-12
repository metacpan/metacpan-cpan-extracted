use utf8;

use Test::Most  qw/defer_plan/;
use Digest::MD5 qw/md5_hex/;

binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";
binmode STDERR, ":utf8";

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $module = 'Postscript::TextDecode';

my $glyph       = 'odieresis';
my $fake_glyph  = 'foobitybar';
my $oct_index   = 232;
my $dec_index   = oct($oct_index);
my $charcode    = 246;
my $char        = chr($charcode);
my $postscript  = 'Hab Dank f\237r all Deine Liebe,';
my $text        = 'Hab Dank für all Deine Liebe,';
my $asciitext   = 'Alles sal reg kom';

my $fake_encoding        = '/foo /bar            /.baz /xuux /xuu.xuux';
my %parsed_fake_encoding = (
   glyph_to_char => [ 'foo', 'bar', '', 'xuux', 'xuu' ],
   glyph_to_dec  => {
        'foo'  => 0,
        'bar'  => 1,
        ''     => 2,
        'xuux' => 3,
        'xuu'  => 4,
   },
);

my $real_encoding = '/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /space /exclam /quotedbl /numbersign /dollar /percent /ampersand /quotesingle /parenleft /parenright /asterisk /plus /comma /hyphen /period /slash /zero /one /two /three /four /five /six /seven /eight /nine /colon /semicolon /less /equal /greater /question /at /A /B /C /D /E /F /G /H /I /J /K /L /M /N /O /P /Q /R /S /T /U /V /W /X /Y /Z /bracketleft /backslash /bracketright /asciicircum /underscore /grave /a /b /c /d /e /f /g /h /i /j /k /l /m /n /o /p /q /r /s /t /u /v /w /x /y /z /braceleft /bar /braceright /asciitilde /.notdef /Adieresis /Aring /Ccedilla /Eacute /Ntilde /Odieresis /Udieresis /aacute /agrave /acircumflex /adieresis /atilde /aring /ccedilla /eacute /egrave /ecircumflex /edieresis /iacute /igrave /icircumflex /idieresis /ntilde /oacute /ograve /ocircumflex /odieresis /otilde /uacute /ugrave /ucircumflex /udieresis /dagger /degree /cent /sterling /section /bullet /paragraph /germandbls /registered /copyright /trademark /acute /dieresis /Euro /AE /Oslash /brokenbar /plusminus /twosuperior /threesuperior /yen /mu /.notdef /.notdef /onesuperior /onequarter /threequarters /ordfeminine /ordmasculine /onehalf /ae /oslash /questiondown /exclamdown /logicalnot /.notdef /florin /.notdef /.notdef /guillemotleft /guillemotright /ellipsis /lslash /Agrave /Atilde /Otilde /OE /oe /endash /emdash /quotedblleft /quotedblright /quoteleft /quoteright /divide /multiply /ydieresis /Ydieresis /fraction /currency /guilsinglleft /guilsinglright /fi /fl /daggerdbl /periodcentered /quotesinglbase /quotedblbase /perthousand /Acircumflex /Ecircumflex /Aacute /Edieresis /Egrave /Iacute /Icircumflex /Idieresis /Igrave /Oacute /Ocircumflex /Lslash /Ograve /Uacute /Ucircumflex /Ugrave /dotlessi /circumflex /tilde /macron /breve /dotaccent /ring /cedilla /hungarumlaut /ogonek /caron';

my $real_encoding_hash = md5_hex( $real_encoding );

#========= Basics =========
use_ok( $module );
my $obj = new_ok( $module );

#======= Encoding =========
throws_ok { $obj->encoding } qr{No encoding set!}                 , 'request encoding without encoding set dies';
throws_ok { $obj->oct_to_char( $oct_index ) } qr{No encoding set!}, 'decode without encoding dies';
ok( $obj->encoding( $fake_encoding ), 'configure encoding'                      );
ok( $obj->encoding                  , 'request encoding with encoding set'      );
is_deeply( \%parsed_fake_encoding, $obj->encoding, 'encoding parses correctly'  ) || diag explain $obj->encoding;
ok( $obj->encoding( $real_encoding ), 'configure real encoding'                 );
is_deeply( $obj->encoding, $obj->_stored_encodings->{ $real_encoding_hash }, 'encoding is hashed and stored correctly' );

#======= Decoding =========
is( $obj->glyph_to_char( $glyph ), $char,       'glyph_to_char for ' . $glyph   );
is( $obj->glyph_to_dec( $glyph ), $dec_index,   'glyph_to_dec for ' . $glyph    );
is( $obj->oct_to_glyph( $oct_index ), $glyph,   'oct_to_glyph for ' . $glyph    );
is( $obj->oct_to_char( $oct_index ) , $char,    'oct_to_char for ' . $glyph     );
is( $obj->ps_to_text( $postscript ), $text,     'ps_to_text'                    );
# test u_to_char
# test uni_to_chars

#=== Unexpected Decoding ==
is( $obj->glyph_to_char, q{},       'glyph_to_char for no args'                 );
is( $obj->glyph_to_dec, 0,          'glyph_to_dec for no args'                  );
is( $obj->oct_to_glyph, q{},        'oct_to_glyph for no args'                  );
is( $obj->oct_to_char, q{},         'oct_to_char for no args'                   );
is( $obj->ps_to_text( $asciitext ), $asciitext, 'ps_to_text with asciitext'     );
# test u_to_char
# test uni_to_chars

#========== Fin ===========
all_done;

