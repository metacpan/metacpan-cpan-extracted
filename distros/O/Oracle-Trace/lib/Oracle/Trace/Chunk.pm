#
# $Id: Chunk.pm,v 1.10 2003/12/24 20:38:54 oratrc Exp $
#
package Oracle::Trace::Chunk;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;
use Oracle::Trace::Utils;

our @ISA = qw(Oracle::Trace::Utils);

our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG = $ENV{Oracle_Trace_DEBUG} || 0;

=item new

Create a new object.

	my $o_chk = Oracle::Trace::Chunk->new();

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) ? ref($proto) : $proto;
	my $self = bless({
		_data   => {},
		_id     => '',
		_parent => 0,
		_child  => 0,
	@_}, $class);
	$self->init;
	return $self;
}

=item init 

Initialise a C<Chunk>, set the oid:

	$o_chk->parse;

=cut

sub init {
	my $self = shift;
	my $xref = $self;
	my $x = $xref;
	$x =~ s/^(\w+:+)+//;
	$x = substr($x, 0, 1);
	$xref =~ s/^\w+(?::+\w+)*=[A-Z]+\(//;
	$xref =~ s/\)$//;
	$self->{_id} = join('-', $$, $x, $xref);
	return $self;
}

=item oid

Return the id of this object.

	my $oid = $o_chk->oid;

=cut

sub oid {
	my $self = shift;
	return $self->{_id};
}

=item parse

Parse the given string appropriately, expecting to be overriden.

Returns the object

	$o_chk->parse($string);

=cut

sub parse {
	# supplied by each relevant package
}

=item keys

Return an array of object data keys, restricted by optional regex.

	my @keys = $o_chk->keys($regex);

=cut

sub keys {
	my $self = shift;
	my $arg = shift || '';
	return grep(/$arg/, keys %{$self->{_data}});
}

=item value

Return the value(s) for the given key.

	my ($val/s) = $o_chk->value($key);

=cut

sub value {
	my $self = shift;
	my $key  = shift;
	return defined($self->{_data}{$key}) ? @{$self->{_data}{$key}} : (); 
}

=item statement

Return statement/s for an entry:

	my $s_stmt = $o_ent->statement;

=cut

sub statement {
	my $self = shift;

	return $self->values('type'=>'other');
}

sub dump {
	my $self = shift;
	return Dumper($self->{_data});	
};

1;
__END__

=head1 NAME

Oracle::Trace::Chunk - Perl Module for parsing Oracle Trace Chunks

=head1 SYNOPSIS

  use Oracle::Trace::Chunk;

  my $o_chk = Oracle::Trace::Chunk->new($string)->parse;

  print "Statement: ".join("\n", $o_chk->statement);

=head1 DESCRIPTION

Module to parse Oracle Trace Chunks.

=head2 EXPORT

None by default.


=head1 SEE ALSO

	http://www.rfi.net/oracle/trace/

=head1 AUTHOR

Richard Foley, E<lt>oracle.trace@rfi.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Richard Foley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
