# check all crontab*.txt under the current directory

use strict;
use warnings;
use Test::More;
use File::Find;

if( eval { require Test::Crontab::Format } ){
    Test::Crontab::Format->import;
}
else{
    plan skip_all => "couldn't load Test::Crontab::Format";
}

File::Find::find {
    wanted => sub {
	return if not -f $File::Find::name;
	return if not m{crontab[^/]*?\.txt$}i;
	crontab_format_ok( $File::Find::name );
    },
    no_chdir => 1,
}, ".";

done_testing;

__END__
