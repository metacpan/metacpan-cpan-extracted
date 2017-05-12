use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Nobuo Danjou
nobuo.danjou@gmail.com
Net::Google::Spreadsheets
API
username
google
orderby
UserAgent
col
min
sq
rewritable
param
com
oauth
AuthSub
auth
