use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp 'tempfile';

use Smart::Options;

my($fh, $file) = tempfile(UNLINK => 1);

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

subtest 'config values are bytes, and the last line needs no newline' => sub {
    my($fh2, $file2) = tempfile(UNLINK => 1);
    binmode $fh2;
    print $fh2 "name=\xe3\x81\x82\nlast=end";
    close($fh2);

    my $argv = Smart::Options->new()->type(conf => 'Config')->parse('--conf', $file2);

    is $argv->{name}, "\xe3\x81\x82";
    ok !utf8::is_utf8($argv->{name});
    is $argv->{last}, 'end';
};

done_testing;

