use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
set_spell_cmd("aspell -l en list");
all_pod_files_spelling_ok('lib');
__DATA__
Masahiro Nagano
kazeburo {at} gmail.com
Plack::Middleware::Log::Minimal
PSGI
debugf
exmple
infof
middleware
psgi
uri
warnf
autodump
loglevel
formatter
utf

