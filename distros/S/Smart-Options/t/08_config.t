use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp 'tempfile';

use Smart::Options;

my($fh, $file) = tempfile();

print $fh <<'EOS';
[section]
rif=55
xup=9.52
[section2]
;comment
hello=world
EOS
close($fh);

subtest 'load option from config file' => sub {
    my $opt = Smart::Options->new()->type(conf => 'Config');
    my $argv = $opt->parse('--conf', $file);

    is $argv->{rif}, 55;
    is $argv->{xup}, 9.52;
    is $argv->{hello}, 'world';
};

subtest 'load option from config file(use default file name)' => sub {
    my $opt = Smart::Options->new()->type(conf => 'Config')->default(conf => $file);
    my $argv = $opt->parse();

    is $argv->{rif}, 55;
    is $argv->{xup}, 9.52;
    is $argv->{hello}, 'world';
};


done_testing;

