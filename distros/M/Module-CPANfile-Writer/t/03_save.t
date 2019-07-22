use strict;
use warnings;

use File::Temp;
use Test::More;

use Module::CPANfile::Writer;

my $fh = File::Temp->new;
my $writer = Module::CPANfile::Writer->new(\'# foo');
$writer->save($fh->filename);
my $src = do {
    open my $fh, '<', $fh->filename or die $!;
    local $/; <$fh>;
};
is $src, '# foo';

done_testing;
