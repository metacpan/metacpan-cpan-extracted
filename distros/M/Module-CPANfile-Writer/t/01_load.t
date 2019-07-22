use strict;
use warnings;

use File::Temp;
use Test::More;

use Module::CPANfile::Writer;

subtest 'load from file' => sub {
    my $fh = File::Temp->new;
    print {$fh} '# foo';
    close $fh;
    my $writer = Module::CPANfile::Writer->new($fh->filename);
    is $writer->src, '# foo';
};

subtest 'load from string' => sub {
    my $writer = Module::CPANfile::Writer->new(\'# foo');
    is $writer->src, '# foo';
};

done_testing;
