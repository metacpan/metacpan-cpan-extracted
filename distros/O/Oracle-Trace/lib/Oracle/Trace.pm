#
# $Id: Trace.pm,v 1.6 2003/12/24 20:38:54 oratrc Exp $
#
package Oracle::Trace;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;
use FileHandle;
use Oracle::Trace::Header;
use Oracle::Trace::Entry;
use Oracle::Trace::Footer;
use Oracle::Trace::Utils;

our @ISA = qw(Oracle::Trace::Utils);

our $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG      = $ENV{Oracle_Trace_DEBUG}    || 0;
my $EXTENDED   = $ENV{Oracle_Trace_EXTENDED} || 0;
my $RECURSE    = $ENV{Oracle_Trace_RECURSE}  || 0;
my $RESOLUTION = 1000000;

=item new

Create a new object for a given Orace Trace file.

	my $o_trc = Oracle::Trace->new($tracefile);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) ? ref($proto) : $proto;
	my $self = bless({
		_entries	=>	[],
		_filehandle	=>	undef,
		_footer		=>	undef,
		_header		=>	undef,
		_stats		=>	{},
		_tracefile  =>	shift,
	}, $class)->init;
	$self->debug(Dumper($self)) if $DEBUG >= 2;
	return $self;
}

=item init

Initialise the object (check the tracefile).

	$o_trc->init.

=cut

sub init {
	my $self = shift;
	my $s_file = $self->{_tracefile};
	$self->fatal("non-existent trace file($s_file)") unless -f $s_file;
	$self->fatal("non-readable trace file($s_file)") unless -r _;
	$self->fatal("no-data in trace file($s_file)")   unless -s _;
	return $self;
}

=item opentracefile 

Perform basic exists/read/etc. checks on given tracefile.  

Returns object or undef. 

	$o_trc = $o_trc->checkfile($tfile);	

=cut

# user_dump_dest or background_dump_dest

sub opentracefile {
	my $self = shift;
	my $s_file = shift || '';
	my $FH = FileHandle->new($s_file) or $self->fatal("failed to open trace file($s_file) $!");
	$self->debug("incoming trace file($s_file) => FH($FH)") if $DEBUG;
	return $FH;
}

# Chunk

sub parse {
	my $self = shift;
	my $FH    = $self->opentracefile($self->{_tracefile});
	my $i_ent = 0;
	my %args  = ('_extended'=>$EXTENDED, '_recurse'=>$RECURSE);
	local $/  = "=====================\n";
	while (<$FH>) {
		my $entry = $_;
		$entry =~ s#$/$##;
		$self->debug("entry[$.]") if $DEBUG >= 2;
		if ($self->{_header}) {
			my $e = Oracle::Trace::Entry->new(%args)->parse($entry);
			if ($RECURSE || !$e->{_child}) {
				push @{$self->{_entries}}, $e;
				$i_ent++;
			}
		} else {
			$self->{_header} = Oracle::Trace::Header->new(%args)->parse($entry);
			my $release = join('',$self->header->keys('Oracle\d+.+?Release'));
			$RESOLUTION = 100 if $release =~ /Oracle[678]/;
		}
	}
	$self->debug("entries read: $. and retained: $i_ent") if $DEBUG >= 1;
	$self->{_footer} = Oracle::Trace::Footer->new(%args)->parse();
	return $self->{_header} ? $self : undef;
};

=item header

Return the C<Header> object.

	my $o_hdr = $o_trc->header;

=cut

sub header { my $self = shift; return $self->{_header}; }

=item entries

Return Entry objects which comply with given regex criteria.

	my @o_ents = $o_trc->entries('type'=>'EXEC #\d+', 'key'=>dep, 'value'=>0);

=cut

sub entries { 
	my $self = shift; 
	my %crit = @_;
	if (keys %crit) {
		my @entries = ();
		ENTRY:
		foreach my $e (@{$self->{_entries}}) {
			my $i_vals = my @vals = $e->values(%crit);
			push(@entries, $e) if $i_vals;
		}
		return @entries;
	} else {
		return @{$self->{_entries}}; 
	}
}

=item oids

Return the unique object ids for the currently known C<Entry>ies

	my @oids = $o_trc->oids;

=cut

sub oids { return map { $_->oid } $_[0]->entries(@_); }

=item footer

Return the C<Footer> object

	my $o_ftr = $o_trc->footer;

=cut

sub footer { return $_[0]->{_footer}; }

=item test_report

Return a B<simple> test_report of the current object.

	print $o_trc->test_report('string');

=cut

sub test_report {
	my $self = shift;
	my $type = shift || 'string';
	my $report = '';
	if ($type eq 'string') {
		my $i_rep = my @rep = $self->entries('type'=>'other'); #, 'value' => 'select');
		my $x_rep = my @xep = $self->entries('type'=>'other','key'=>'.*','value'=>'.*'); #, 'value' => 'select');
		my $rep = $self->mini_report('10', @rep);
		$report = join("\n",
			'          instance name: '.join('',$self->header->value('Instance name')),
			'                release: '.join('',$self->header->keys('Oracle.+?Release')),
			'                   info: '.join("\n", $self->header->value('other')),
			'           header lines: '.$self->header->keys.' oid: '.$self->header->oid,
			'                entries: '.$self->entries,
			'        root statements: '.$self->entries('type'=>'PARSING IN CURSOR #\d+','key'=>'dep','value'=>'0'),
			'           parse errors: '.$self->entries('type'=>'PARSE ERROR #\d+','key'=>'dep','value'=>'0'),
			# '      select oids: '.join(', ', map{$_->oid} @sel),
			sprintf('%5d', $i_rep).' reports (top ten): '.$rep,
			'           footer lines: '.$self->footer->keys,
			'',
		);
	} elsif ($type eq 'html') {
		$report = 'html unsupported yet...<br>';
	} else {
		$self->error("unsupported report type($type)");
	}
	return $report;
};

=item mini_report

Return a B<simple> string of descending order timings for the statements
retrieved from the given objects.

	my $s_str = $o_trc->mini_report($i_max, @o_objs);

Note that we use microsecond resolution for Oracle 9i and above and
centisecond resolution otherwise

=cut

sub mini_report {
	my $self = shift;
	my $i_max = shift;
	my @objs = @_;

	my %rep = ();
	STMT:
	foreach my $o (@objs) {
		($rep{$o->elapsed}) = $o->statement;
		if ($EXTENDED) {
			$rep{$o->elapsed} .= "\n\t\t".join("\n\t\t", $o->stats); 
		}
	}
	my $rep = "\n";
	my $i_rep = 0;
	REP:
	foreach my $k (reverse sort {$a <=> $b} keys %rep) {
		$i_rep++;
		$rep .= sprintf('%15.3f', $k/$RESOLUTION)." secs <- $rep{$k}\n";
		last REP if $i_rep >= 10;
	}

	return $rep;
}
	
1;

__END__

=head1 NAME

Oracle::Trace - Perl Module for parsing Oracle Trace files

=head1 SYNOPSIS

  use Oracle::Trace;

  print Oracle::Trace->new($tracefilename)->parse->test_report;

=head1 DESCRIPTION

Module for parsing and describing an Oracle Trace file.

Currently the parsing and statistics are very rudimentary, and in
certain matters may be fundamentally flawed - you have been warned!

Expect this to improve as further development takes place.

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
