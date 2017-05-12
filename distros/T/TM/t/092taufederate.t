package Rumsti;

use TM;
use base qw(TM);
use Class::Trait ('TM::Synchronizable' => { exclude => 'mtime' } );

sub reset {
    my $self = shift;
    $self->{sync_in_called}  = 0;
    $self->{sync_out_called} = 0;
}

sub mtime {
#warn "rumsti mtime";
    return time + 1;
}

sub source_in {
    my $self = shift;
    $self->{sync_in_called}++;
}

sub source_out {
    my $self = shift;
    $self->{sync_out_called}++;
}

1;

package Ramsti;
use base qw(Rumsti);
1;

package Remsti;
use base qw(Rumsti);
1;

package Romsti;
use base qw(Rumsti);
1;

#-- test suite

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

#== TESTS =====================================================================

require_ok ('TM::Tau::Federate');

eval {
    my $f = new TM::Tau::Federate;
}; like ($@, qr/no left/, 'left operand missing');

use TM::Tau::Filter;

eval {
    my $f = new TM::Tau::Federate (left => new TM::Tau::Filter (map => new TM));
}; like ($@, qr/no right/, 'right operand missing');

{ # structural
    my $f = new TM::Tau::Federate (left  => new TM::Tau::Filter (map     => new Rumsti),
				   right => new TM::Tau::Federate (left  => new TM::Tau::Filter (map     => new Ramsti),
								   right => new TM::Tau::Filter (map     => new Remsti)));

    ok ($f->isa                   ('TM::Tau::Federate'),  'class');
    ok (!$f->{map},                                       'empty map');
    ok ($f->{left}->isa           ('TM::Tau::Filter'),    'left class');
    ok ($f->{right}->isa          ('TM::Tau::Federate'),  'right class');

    ok ($f->{right}->{left}->isa  ('TM::Tau::Filter'),    'rightleft class');
    ok ($f->{right}->{right}->isa ('TM::Tau::Filter'),    'rightright class');
    ok (!$f->{right}->{right}->{operand},                 'rightright operand class');
}

{
    my $f = new TM::Tau::Federate (url   => 'whatever:',    # only if there is a URL, the infrastructure will try a sync out
				   left  => new TM::Tau::Filter (left     => new Rumsti (url => 'in1:'),
								 url      => 'what:ever'),
				   right => new TM::Tau::Federate (left  => new TM::Tau::Filter (left    => new Ramsti (url => 'in2:'),
												 url     => 'what:ever'),
								   right => new TM::Tau::Filter (left    => new Remsti (url => 'in3:'),
												 url     => 'what:ever'),
								   url   => 'what:ever'));
    use Class::Trait;
    Class::Trait->apply ($f, 'TM::Synchronizable', { exclude => [ 'mtime', 'sync_out' ] });

    $f->sync_in;

    is ($f->left->left->{sync_in_called},            1,         'tried sync in once');
    is ($f->right->left->left->{sync_in_called},     1,         'tried sync in once');
    is ($f->right->right->left->{sync_in_called},    1,         'tried sync in once');

    $f->{last_mod} = time + 1; # make sure we fake change

# MUCH TO BE DONE HERE
#     $f->sync_out;

#     is ($f->left->left->{sync_in_called},            1,         'tried sync in once');
#     is ($f->right->left->left->{sync_in_called},     1,         'tried sync in once');
#     is ($f->right->right->left->{sync_in_called},    1,         'tried sync in once');
}

__END__

