#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);

use Object::Proto;

# handles(...) delegation against the perl it replaces: a hand-written
# delegating sub, and the same code written out where it is used.

package Logger;
sub new  { bless {}, shift }
sub info { $_[1] }

package Service;
sub perl_info   { my $self = shift; $self->logger->info(@_) }
sub perl_format { my $self = shift; $self->formatter->(@_) }
sub perl_fire   { my $self = shift; $self->hook->($self, @_) }

package main;

Object::Proto::define('Service',
	'logger:Object:handles(info)',
	'formatter:CodeRef:handles(format)',
	'hook:CodeRef:handles(fire=>method)',
	'tags:ArrayRef:handles(push_tag=>push, pop_tag=>pop, tag_count=>count, get_tag=>get)',
	'opts:HashRef:handles(get_opt=>get, set_opt=>set)',
);

my $svc = Service->new(
	logger    => Logger->new,
	formatter => sub { $_[0] },
	hook      => sub { $_[1] },
	tags      => [1 .. 10],
	opts      => { k => 1 },
);

sub compare {
	my ($title, %cases) = @_;
	print "\n$title\n", "-" x length($title), "\n";
	cmpthese(timethese(-3, \%cases, 'none'));
}

compare('Method delegation: $svc->info(1)',
	'handles'     => sub { $svc->info(1) for 1 .. 100 },
	'perl sub'    => sub { $svc->perl_info(1) for 1 .. 100 },
	'written out' => sub { $svc->logger->info(1) for 1 .. 100 },
);

compare('CodeRef delegation: $svc->format(1) and $svc->fire(1)',
	'handles call'    => sub { $svc->format(1) for 1 .. 100 },
	'perl sub call'   => sub { $svc->perl_format(1) for 1 .. 100 },
	'written out'     => sub { $svc->formatter->(1) for 1 .. 100 },
	'handles method'  => sub { $svc->fire(1) for 1 .. 100 },
	'perl sub method' => sub { $svc->perl_fire(1) for 1 .. 100 },
);

compare('ArrayRef: push and pop',
	'handles'     => sub { for (1 .. 100) { $svc->push_tag(1); $svc->pop_tag } },
	'written out' => sub { for (1 .. 100) { push @{ $svc->tags }, 1; pop @{ $svc->tags } } },
);

compare('ArrayRef: count',
	'handles'     => sub { my $n; $n = $svc->tag_count for 1 .. 100 },
	'written out' => sub { my $n; $n = scalar @{ $svc->tags } for 1 .. 100 },
);

compare('ArrayRef: get',
	'handles'     => sub { my $v; $v = $svc->get_tag(3) for 1 .. 100 },
	'written out' => sub { my $v; $v = $svc->tags->[3] for 1 .. 100 },
);

compare('HashRef: get and set',
	'handles'     => sub { for (1 .. 100) { $svc->set_opt(k => 2); my $v = $svc->get_opt('k') } },
	'written out' => sub { for (1 .. 100) { $svc->opts->{k} = 2; my $v = $svc->opts->{k} } },
);
