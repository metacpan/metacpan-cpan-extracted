package PICA::Modification::Queue::Hash;
{
  $PICA::Modification::Queue::Hash::VERSION = '0.16';
}
#ABSTRACT: In-memory collection of modifications

use strict;
use warnings;
use v5.10;

use PICA::Modification::Request;
use Scalar::Util qw(blessed);

sub new { 
    bless [{},0], shift; 
}

sub get {
   my ($self, $id) = @_;
   return $self->[0]->{ $id };
}

sub request {
	my ($self, $mod) = @_;
	return if !$mod->isa('PICA::Modification') or $mod->isa('PICA::Modification::Request');
	$mod = PICA::Modification::Request->new( $mod );
	return if $mod->error;
	my $id = ++$self->[1];
	$self->[0]->{ $id } = $mod;
	return $id;
}

sub update { 
    my ($self, $id => $mod) = @_;
	$mod = PICA::Modification::Request->new( $mod );
	return if $mod->error;
	$self->[0]->{ $id } = $mod;
	return $id;
}

sub delete {
    my ($self, $id) = @_;
    return unless defined $self->[0]->{ $id };
	delete $self->[0]->{ $id }; 
	$id;
}

sub list {
	my ($self, %properties) = @_;

	my $limit  = delete $properties{limit} || 20;
	my $page   = delete $properties{page} || 1;
	my $sortby = delete $properties{sort};

	my $hash = $self->[0];

    my $c = 0;
    my $grep = sub {
        while (my ($k,$v) = each(%properties)) {
            return 0 unless $_[0]->{$k} eq $v; 
        }
        $c++;
        return 0 if $c > $page*$limit;
        return 0 if $c <= ($page-1)*$limit;
        1;
    };

    if ( $sortby ) {
        my $sort = sub { $a->{$sortby} cmp $b->{$sortby} };
        return [ grep { $grep->($_) } sort $sort values %$hash ];
    } else {
        return [ grep { $grep->($_) } values %$hash ];
    }
}

1;


__END__
=pod

=head1 NAME

PICA::Modification::Queue::Hash - In-memory collection of modifications

=head1 VERSION

version 0.16

=head1 DESCRIPTION

PICA::Modification::Queue::Hash implements a L<PICA::Modification::Queue> that
directly stored modification requests as references in memory.

=encoding utf-8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

