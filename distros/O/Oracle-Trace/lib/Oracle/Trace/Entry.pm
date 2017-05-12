#
# $Id: Entry.pm,v 1.9 2003/12/24 20:38:54 oratrc Exp $
#
package Oracle::Trace::Entry;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;
use Oracle::Trace::Chunk;

our @ISA = qw(Oracle::Trace::Chunk);

our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG = $ENV{Oracle_Trace_DEBUG} || 0;

# Chunk

sub parse {
	my $self = shift;
	my $data = shift;
	$self->debug("incoming: ".Dumper($data)) if $DEBUG >= 4;
	my $i_line = 0;
	if ($data) {
		LINE:
		foreach my $line (split("\n", $data)) {
			$self->debug("line[".$i_line."] $line") if $DEBUG >= 5;
			$i_line++;
			next LINE if $line =~ /^(\*\*\*\s+\d+|END OF STMT)/;
			if ($line =~ /^(STAT|WAIT)\s+/) {
				next LINE unless $self->{_extended};
			}
			if ($line =~ /dep=[1-9]+/) {
				$self->{_child}++;
				next LINE unless $self->{_recurse};
			}
			# expecting uppercase words preceding data - misses binds
			if ($line =~ /^([A-Z]+(?:\s+[A-Z]+)*\s*(?:\#\d+)*):*(.*)$/) {
				my ($k, $v) = ($1, $2);
				if (my %data = ($v =~ /([a-z]+)=(\d+|'[^']*')/g)) {
					push @{$self->{_data}->{$k}}, \%data;
					if ($k =~ /^PARSING IN CURSOR/ && defined($data{dep})) {
					  $self->{_parent}++ if $data{dep} == 0;
					}
				}
			} else {	
				push @{$self->{_data}{other}}, $line;
			}
		}
	}
	$self->debug("_data: ".Dumper($self->{_data})) if $DEBUG >= 3;
	$self->debug("lines read: $i_line") if $DEBUG >= 2;
	return $self;
}

=item values 

Return the values from the hash referenced by the type and key given, with optional value or index.

	@vals = $o_chk->values('type' => 'PARSE #\d+', 'key' => 'dep', 'value' => '0');

=cut

sub values {
	my $self = shift;
	my %h = (
		'type'	=> 'PARSE .+',
		'key'	=> '.+',
		'value'	=> '.+',
		'index'	=> '',
	@_);
	my @vals = ();
	unless (($h{type}) and ($h{key})) {
		$self->error("invalid type and key: ".Dumper(\%h));
	} else {	
		foreach my $k (grep(/$h{type}/, $self->keys)) {
			my $i_ind = 0;
			if ($h{index} =~ /\d+/) {
				if ($h{type} eq 'other') {
					@vals = grep(/$h{value}/, @{$self->{_data}{$k}[$h{index}]});
				} else {
					if (defined($self->{_data}{$k}[$h{index}]->{$h{key}}) && 
						$self->{_data}{$k}[$h{index}]->{$h{key}} =~ /($h{value})/) {
						push(@vals, $1);
					}
				}
			} else {
				if ($h{type} eq 'other') {
					@vals = grep(/$h{value}/, @{$self->{_data}{$k}});
				} else {
					foreach my $h_d (@{$self->{_data}{$k}}) {
						push(@vals, $1) if (defined($h_d->{$h{key}}) && $h_d->{$h{key}} =~ /($h{value})/);
					}
				}
			}
		}
	}

	return @vals;
}

=item elapsed

Return a total of the C<elapsed> times for this C<Entry>.

	my $elapsed = $o_ent->elapsed;

=cut

sub elapsed {
	my $self = shift;
	my $elapsed = 0;

	my @parse = $self->values('type'=>'PARSE.+', 'key'=>'e');
	my @exec  = $self->values('type'=>'EXEC.+', 'key'=>'e');
	my @fetch = $self->values('type'=>'FETCH.+', 'key'=>'e');
	$self->debug("p(@parse) e(@exec) f(@fetch)") if $DEBUG >= 3;

	foreach my $x (@parse, @exec, @fetch) {
		$elapsed += $x;
	}

	return $elapsed;
}

=item stats

Synonmy for C<statistics()>

=cut

sub statistics { return $_[0]->stats; }

sub stats {
	my $self = shift;
	my @stats = ();
	unless ($self->{_extended}) {
		$self->fatal("extended statistics not enabled");
	} else {
		@stats = $self->values('type'=>'STAT \#\d+','key'=>'op');
	}
	return @stats;
}

1;

__END__

=head1 NAME

Oracle::Trace::Entry - Perl Module for parsing Oracle Trace Entries

=head1 SYNOPSIS

  use Oracle::Trace::Entry;

  my $o_ent = Oracle::Trace::Entry->new($string)->parse;

  print "Statement: ".join("\n", $o_ent->statement);

=head1 DESCRIPTION

Module to parse Oracle Trace Entries.

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
