use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Nobuo Danjou
nobuo.danjou@gmail.com
Net::Amazon::HadoopEC2::S3fs
hadoop
Hadoop
fs
svn
AmazonS3
Wiki
aws
ec2
ec
