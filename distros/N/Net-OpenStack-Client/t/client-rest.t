use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::Warnings;

BEGIN {
    push(@INC, dirname(__FILE__));
}

use Test::MockModule;
use JSON::XS;
use Net::OpenStack::Client;

my $m = Test::MockModule->new('Net::OpenStack::Client::REST');

# only logger is required for self
use logger;
my $cl = Net::OpenStack::Client->new(log => logger->new(), debugapi=>1);
isa_ok($cl, 'Net::OpenStack::Client::REST', 'the client is a REST instance');


# ->rest method is actually tested in mock_rest

=head1 _page_paths

=cut

my $response = {a => {
    b => {
        c => [1],
        c_links => [
            {rel => 'next', href => 'some/url'},
            {rel => 'previous', href => 'some/prevurl'},
        ],
    },
    d => ['a', 'b'],
    d_links => [{rel=> 'next', href => 'some/otherurl'}],
    e => ['a', 'b'],
    e_links => [{rel=> 'self', href => 'some/yetotherurl'}],
}};
my @paths = $cl->_page_paths($response);
is_deeply(\@paths, [
              [[qw(a b c)], 'some/url'],
              [[qw(a d)], 'some/otherurl']
          ], "_page_paths discovers all paths with links to next for pagination");


=head1 _page

=cut

my $call_args;
$m->mock('_call', sub {
    shift;
    $call_args = \@_;
    return {a=>{b=>{c=>[3,4]},d=>['x','y']}}, {}, undef;
});

my ($resp2, $err) = $cl->_page("METHOD", $response, {headers=>1});
is_deeply($resp2->{a}->{b}->{c}, [1,3,4], "a->b->c extended after pagination");
is_deeply($resp2->{a}->{d}, [qw(a b x y)], "a->d extended after pagination");
is_deeply($resp2->{a}->{e}, [qw(a b)], "a->e unmodified");

is_deeply($call_args, ['METHOD', 'some/otherurl', {'headers' => 1}],
          "_page called _call for pagination");

$m->unmock('_call');

done_testing;
