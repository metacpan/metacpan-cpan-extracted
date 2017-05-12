use strict;
use warnings;
use v5.10;
use Test::More;
use Test::Exception;
use PICA::Modification;
use PICA::Modification::TestQueue;
use PICA::Modification::Queue::Smart;
use PICA::Record;

sub picamod { PICA::Modification->new(@_) }

throws_ok { PICA::Modification::Queue::Smart->new( check => 1 ); }
    qr{missing 'via'};

my $queue = PICA::Modification::Queue::Smart->new( check => 1, via => 'http://example.org/' );
isa_ok $queue, 'PICA::Modification::Queue::Smart';

my $pica = "003@ \$0123\n012A \$xfoo";
my $unapi = sub {
    my $id = shift;
    return PICA::Record->new($pica);
};

$queue = PICA::Modification::Queue::Smart->new( check => 1, via => $unapi );
isa_ok $queue, 'PICA::Modification::Queue::Smart';
isa_ok $queue->{via}->(789), 'PICA::Record';

my $id = $queue->request( picamod(id => 'foo:ppn:123', del => '098X') );

# TODO: edits should better be idempotent
#my $id  = $queue->request( picamod(id => 'foo:ppn:123', add => '012A $xfoo') );

my $mod = $queue->get($id);
is $mod->{status}, 1, 'already done';

$id = $queue->request( picamod(id => 'foo:ppn:123', del => '012A') );
$mod = $queue->get($id);

is $mod->{status}, 0, 'not done yet';
$pica = "003@ \$0123";

$mod = $queue->get($id);
is $mod->{status}, 0, 'not done yet';

sleep(1);

$mod = $queue->get($id);
is $mod->{status}, 1, 'done after checking back!';

my $smart = PICA::Modification::Queue->new( 
    'smart', 
    queue => { type => 'hash' }, 
    via => sub { 
        $_[0] ~~ /ppn:([0-9Xi]+)$/ ? PICA::Record->new('003@ $0'.$1) : undef;
    },
);
isa_ok $smart, 'PICA::Modification::Queue::Smart';

test_queue $smart, 'PICA::Modification::Queue::Smart';

done_testing;
