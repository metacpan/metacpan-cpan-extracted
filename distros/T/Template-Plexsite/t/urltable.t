use feature "say";
use Data::Dumper;
use Test::More;
use File::Basename qw<dirname>;
use File::Spec::Functions qw<catfile>;

use Log::ger;
use Log::ger::Output "Screen";
use Log::OK {
	lvl=>"trace",
	opt=>"verbose",
};

use Log::ger::Util;
Log::ger::Util::set_level Log::OK::LEVEL;


BEGIN { use_ok "Template::Plexsite::URLTable" };

use Template::Plexsite::URLTable;

my $file=__FILE__;
my $src=catfile dirname($file),"src";
my $html_root=catfile dirname($file), "site";

my $table=Template::Plexsite::URLTable->new(src=>$src, html_root=>$html_root, locale=>"en");

ok $table, "URL table creation";

#Resouces are relative to source root

#Test adding single input with not explicit output
my $input="templates/test1.plt";

$table->add_resource($input);
$table->build;

my $output=$table->lookup($input);
#say STDERR Dumper $output;
done_testing;
