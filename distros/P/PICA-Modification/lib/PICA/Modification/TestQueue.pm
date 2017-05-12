package PICA::Modification::TestQueue;
{
  $PICA::Modification::TestQueue::VERSION = '0.16';
}
#ABSTRACT: Unit test implementations of PICA::Modification::Queue

use strict;
use warnings;
use v5.10;

use Test::More 0.96;
use PICA::Modification;
use Test::JSON::Entails;

use parent 'Exporter';
our @EXPORT = qw(test_queue);

sub test_queue {
	my $queue = shift;
    my $name  = shift;

	subtest $name => sub {
	    my $test = bless { queue => $queue }, __PACKAGE__;
        $test->run;
    };
}

sub get { my $t = shift; $t->{queue}->get(@_); }
sub request { my $t = shift; $t->{queue}->request(@_); }
sub update { my $t = shift; $t->{queue}->update(@_); }
sub delete { my $t = shift; $t->{queue}->delete(@_); }
sub list { my $t = shift; $t->{queue}->list(@_); }

sub run {
	my $self = shift;

	my $list = $self->list();
	is_deeply $list, [], 'empty queue';

	my $mod = PICA::Modification->new( 
		del => '012A',
		id  => 'foo:ppn:123',
	);

	my $id = $self->request( $mod );
	ok( $id, "inserted modification" );

	my $got = $self->get($id);
	entails $got => $mod->attributes, 'get stored modification';
	isa_ok $got, 'PICA::Modification::Request';

	my $req = PICA::Modification::Request->new($mod);
    is $self->request($req), undef, 'reject insertion of modification requests';

	$list = $self->list();
	is scalar @$list, 1, 'list size 1';
	entails $list->[0] => $mod->attributes, 'list contains modification';

	$list = $self->list(limit => 1);
	is scalar @$list, 1, 'list option "limit"';

    $mod = PICA::Modification->new( del => '012A', id => 'bar:ppn:123' );
    my $id2 = $self->request( $mod );
	$list = $self->list( sort => 'id' );
	is scalar @$list, 2, 'list size 2 after inserting second modification';
    is $list->[0]->{id}, 'bar:ppn:123', 'list can be sorted';

	$list = $self->list( id => 'foo:ppn:123' );
	is scalar @$list, 1, 'search by field value';
    is $list->[0]->{id}, 'foo:ppn:123', 'only list matching modifications';

    foreach (0..4) {
        $mod = PICA::Modification->new( del => '012A', id => "doz:ppn:1$_" );
        $self->request($mod);
    }
    $list = $self->list( sort => 'id', limit => 3 );
    is scalar @$list, 3, 'inserted five additional modifications, limit works';

    $list = $self->list( sort => 'id', limit => 3, page => 2 );
    is scalar @$list, 3, 'limit';
    is $list->[0]->{id}, 'doz:ppn:12', 'page';

    $mod = PICA::Modification->new( add => '028A $xfoo', del => '028A', id => 'ab:ppn:1' );
    $id2 = $self->update( $id => $mod );
    is $id2, $id, 'update allowed';
    $mod = $self->get($id);
    is $mod->{del}, '028A', 'update changed';
    is $mod->{add}, '028A $xfoo', 'update changed';


	$mod = PICA::Modification->new( del => '012A', id  => 'xxx' );
    is $self->request($mod), undef, 'reject modification with error';

	$mod = PICA::Modification->new( del => '012A', id  => 'xxx' );
    is $self->update( $id => $mod), undef, 'reject modification with error';

	my $delid = $self->delete($id);
	is $delid, $id, 'deleted modification';

	$got = $self->get($id);
	is $got, undef, 'deleted modification returns undef';
}

1;


__END__
=pod

=head1 NAME

PICA::Modification::TestQueue - Unit test implementations of PICA::Modification::Queue

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use PICA::Modification::TestQueue;

    test_queue $queue, 'tested queue';

=head1 DESCRIPTION

This package exports the function C<test_queue> to run a simple unit test on a
L<PICA::Modification::Queue>.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

