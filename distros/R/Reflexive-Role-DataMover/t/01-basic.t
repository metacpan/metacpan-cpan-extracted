use warnings;
use strict;
use Test::More;
use File::Temp('tempfile');
use Text::Lorem;
use IO::All;
use Reflex::Stream;

BEGIN
{
    use_ok('Reflexive::Role::DataMover');
}

{
    package MyDataMover;
    use Moose;

    extends 'Reflex::Base';

    foreach my $attr (qw/input output/)
    {
        has $attr =>
        (
            is => 'ro',
            does => 'Reflex::Role::Streaming',
            clearer => 'clear_'.$attr,
            predicate => 'has_'.$attr,
        );
    }

    with 'Reflexive::Role::DataMover';
}

my ($fh1, $file1) = tempfile();
my ($fh2, $file2) = tempfile();

io($file1)->print(Text::Lorem->new()->paragraphs(10));

my $mover = MyDataMover->new
(
    input => Reflex::Stream->new(handle => $fh1),
    output => Reflex::Stream->new(handle => $fh2),
);

$mover->run_all();

is(io($file2)->slurp, io($file1)->slurp, 'data streamed appropriately');
unlink $file1;
unlink $file2;
done_testing();
