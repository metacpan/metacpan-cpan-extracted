use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Sorin Pop
sorin.pop {at} evozon.com
Plack::Middleware::ServerName
Starman
IO
middleware
cho45
keepalive
