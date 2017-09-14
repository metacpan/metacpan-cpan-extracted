use Test::More;
use Patro ':test';
use strict;
use warnings;

my $rbar = two_refs->new(3,4,5,6);
ok($rbar && ref($rbar) eq 'two_refs',
   'created remote two_refs object');
my $pbar = getProxies(patronize($rbar));

my $z=0;if($pbar) { $z=1 }
ok($z, 'got proxy');
ok(Patro::ref($pbar) eq 'two_refs', '... a proxy two_refs ref');
ok(CORE::ref($pbar) eq 'Patro::N6', '... internally a Patro::N6');

$rbar->[1] = 9;
is($rbar->[1], 9, 'array access');
is($rbar->{one}, 9, 'hash access');

$pbar->[2] = 11;
is($pbar->[2], 11, 'proxy array access');
is($pbar->{two}, 11, 'proxy hash access');

done_testing;

package two_refs; # example in perldoc overload
use overload '%{}' => \&gethash, '@{}' => sub { $ {shift()} }, bool => sub{1};
sub new {
    my $p = shift;
    _init();
    bless \ [@_], $p;
}
sub gethash {
    my %h;
    my $self = shift;
    tie %h, ref $self, $self;
    \%h;
}

sub TIEHASH { my $p = shift; bless \ shift, $p }
my %fields;
my $init;
sub _init {
    return if $init++;
    my $i = 0;
    $fields{$_} = $i++ foreach qw{zero one two three};
}
sub STORE {
    my $self = ${shift()};
    my $key = $fields{shift()};
    defined $key or die "Out of band access";
    $$self->[$key] = shift;
}
sub FETCH {
    my $self = ${shift()};
    my $key = $fields{shift()};
    defined $key or die "Out of band access";
    $$self->[$key];
}
