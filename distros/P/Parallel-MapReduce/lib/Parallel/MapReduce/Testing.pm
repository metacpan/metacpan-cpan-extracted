package Parallel::MapReduce::Testing;

use strict;
use warnings;

use base 'Parallel::MapReduce';

our $log;

=pod

=head1 NAME

Parallel::MapReduce::Testing - MapReduce Infrastructure, single-threaded, local

=head1 SYNOPSIS

  use Parallel::MapReduce::Testing;
  my $mri = new Parallel::MapReduce::Testing;

  # rest like in Parallel::MapReduce

=head1 DESCRIPTION

This subclass of L<Parallel::MapReduce> implements MapReduce, but only as a single thread. Unlike
its superclass, there is no need (or use) to provide lists of servers or workers.

This is great for testing your algorithm itself.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub mapreduce {
    my $mri    = shift;
    my $map    = shift;
    my $reduce = shift;
    my $h1     = shift;

    $log ||= $Parallel::MapReduce::log;                                 # just a local short, I hate typing
    my %h3;
    while (my ($k, $v) = each %$h1) {
	my %h2 = &$map ($k => $v);
	map { push @{ $h3{$_} }, $h2{$_} } keys %h2;
    }
    my %h4;
    while (my ($k, $v) = each %h3) {
	$h4{$k} = &$reduce ($k => $v);
    }
    return \%h4;
}

=pod

=head1 SEE ALSO

L<Parallel::MapReduce>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.04;

1;
