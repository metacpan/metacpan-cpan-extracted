# SETI::Stats - after perlseti.pl by Jan Rocho
# See below for author, copyright, &c.
# $Id: Stats.pm,v 1.9 2001/09/05 09:10:44 martin Exp $

package SETI::Stats;
use strict;
use vars qw($VERSION);

$VERSION = "1.06";


sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my ($a, $v, %f);
    my $self = {};

    while(($a, $v) = each %args) { $self->{$a} = $v; }
    bless $self, $class;

    @{$self->{messages}} = (
	"Analyzing the work unit data ...\n",
	"Your \"state.sah\" file is currently being updated.\n",
	"Downloading new work unit ...\n",
	"Your user information is being updated ...\n",
	"Can't open the high-score data file for reading ...\n",
	"Can't open the high-score data file for writing ...\n",
	"Can't reset the high-score file ...\n"
    );
    $self->{message} = 0;

    $self->{source} = "Arecibo Radio Observatory"
	unless $args{source}; # :-)
    $self->{dir} = "/home/seti" unless $args{dir};
    # rsh command could include '-l username' ...
    $self->{rsh} = "ssh" unless $args{rsh};
    $self->{save} = ($self->{dir} . "/perlseti_data") unless $args{save};
    # no default host, so we can disambiguate local/remote stats

    return $self;
}


sub poll {
    my ($self, %args) = @_;
    my (@results) = ();
    my $okclearmessage;
    my $foundfile;
    my ($filename) = $args{file};

    $foundfile = 0;

    # set message to appropriate error
    if ($self->{message} eq 0) {
        $okclearmessage = 1;
        if ($filename eq 'state.sah') {
            $self->{message} = 1;
        } elsif ($filename eq 'work_unit.sah' || $filename eq 'result_header.sah') {
            $self->{message} = 2;
        } elsif ($filename eq 'user_info.sah') {
            $self->{message} = 3;
        } else {
            $self->{message} = 4;
        }
    } else {
        $okclearmessage = 0;
    }

    unless ($filename =~ /^\// || $filename =~ /^.:/) { # already FQ?
	$filename = $self->{dir} . "/" . $args{file};
    }

    # rsh/ssh/... over to another machine to snarf the stats if needed
    if ($self->{host} && !$args{checkpoint}) {
	return undef unless
	  open(IN, "$self->{rsh} $self->{host} \"cat $filename 2>/dev/null\"|");
    } else {
	# ...or just open a local file
	return undef unless open(IN, "$filename");
    }

    # end_seti_header is a special case in work units
    while(<IN>) { 
        $foundfile = 1; chop; last if /^end_seti_header/; push(@results, $_); 
    }
    close(IN);

    # clear error message
    $self->{message} = 0 if ($okclearmessage && $foundfile);

    return @results;
}


sub populate {
    my ($self, %args) = @_;
    my ($l, $r);

    # mandatory parameters
    return undef unless $args{results} && $args{section};

    # slurp into a hash array
    foreach (@{$args{results}}) {
	s/=\s+/=/;
	($l,$r) = split(/=/);
	#$self->{$args{section}}{$l} = $r || ""; # default should be undef?
	$self->{$args{section}}{$l} = $r;
    }
}


sub checkpoint {
    my ($self, %args) = @_;
    my ($host) = ($self->{host} ? "_$self->{host}" : "");
    my (%x, @results, $changed, $okclearmessage);

    # changed -f to -s so we will work with 0 byte bestscore data files
    # when trying to write out a (true) best score (like gaussian power)
    # of 0.   agw 06/22/00
    unless (-s "$self->{save}$host.txt") {
        if ($self->{message} eq 0) {
            $okclearmessage = 1;
            $self->{message} = 5;
        } else {
            $okclearmessage = 0;
        }

	open(OUT, ">$self->{save}$host.txt") || return undef;
        $self->{message} = 0 if ($okclearmessage);

	print OUT "bestspike_power= " . $self->state("bs_power") . "\n";
	print OUT "bestspike_score= " . $self->state("bs_score") . "\n";
	print OUT "bestspike_ra= " . $self->work_unit("start_ra") . "\n";
	print OUT "bestspike_dec= " . $self->work_unit("end_ra") . "\n";
	print OUT "bestgaussian_power= " . $self->state("bg_power") . "\n";
	print OUT "bestgaussian_score= " . $self->state("bg_score") . "\n";
	print OUT "bestgaussian_ra= " . $self->work_unit("start_ra") . "\n";
	print OUT "bestgaussian_dec= " . $self->work_unit("end_ra") . "\n";
	close(OUT);

        @results = $self->poll(file => "$self->{save}$host.txt",
				checkpoint => 1);
        $self->populate(section => "perlseti_data", results => \@results);
	return 2;
    }

    @results = $self->poll(file => "$self->{save}$host.txt",
				checkpoint => 1);
    $self->populate(section => "perlseti_data", results => \@results);

    $changed = 0; # default is that we don't need to update perlseti_data

    # $x is the info we'd write to our state file...
    $x{bestspike_power} = $self->perlseti_data("bestspike_power");
    $x{bestspike_score} = $self->perlseti_data("bestspike_score");
    $x{bestspike_ra} = $self->perlseti_data("bestspike_ra");
    $x{bestspike_dec} = $self->perlseti_data("bestspike_dec");
    $x{bestgaussian_power} = $self->perlseti_data("bestgaussian_power");
    $x{bestgaussian_score} = $self->perlseti_data("bestgaussian_score");
    $x{bestgaussian_ra} = $self->perlseti_data("bestgaussian_ra");
    $x{bestgaussian_dec} = $self->perlseti_data("bestgaussian_dec");

    if ($self->state("bs_power") > $self->perlseti_data("bestspike_power")) {
	$x{bestspike_power} = $self->state("bs_power");
	$x{bestspike_score} = $self->state("bs_score");
	$x{bestspike_ra} = $self->work_unit("start_ra");
	$x{bestspike_dec} = $self->work_unit("start_dec");
	$changed = 1;
    }

    if ($self->state("bg_score") > $self->perlseti_data("bestgaussian_score")) {
	$x{bestgaussian_power} = $self->state("bg_power");
	$x{bestgaussian_score} = $self->state("bg_score");
	$x{bestgaussian_ra} = $self->work_unit("start_ra");
	$x{bestgaussian_dec} = $self->work_unit("start_dec");
	$changed = 1;
    } 

    return 1 unless $changed;

    if ($self->{message} eq 0) {
        $okclearmessage = 1;
        $self->{message} = 5;
    } else {
        $okclearmessage = 0;
    }

    open(OUT, ">$self->{save}$host.txt") || return undef;
    $self->{message} = 0 if ($okclearmessage);
    print OUT <<EOF;
bestspike_power= $x{bestspike_power}
bestspike_score= $x{bestspike_score}
bestspike_ra= $x{bestspike_ra}
bestspike_dec= $x{bestspike_dec}
bestgaussian_power= $x{bestgaussian_power}
bestgaussian_score= $x{bestgaussian_score}
bestgaussian_ra= $x{bestgaussian_ra}
bestgaussian_dec= $x{bestgaussian_dec}
EOF
    close(OUT);

    @results = $self->poll(file => "$self->{save}$host.txt",
				checkpoint => 1);
    $self->populate(section => "perlseti_data", results => \@results);

    return 3;
}


sub visit {
    my ($self, %args) = @_;
    my ($section, @results);

    foreach $section ("result_header", "state", "user_info",
					"version", "work_unit") {
	@results = $self->poll(file => "$section.sah");
	$self->populate(section => $section, results => \@results);
    }
    $self->checkpoint;
}


sub result_header {
    my ($self, $param) = @_; return ${$self->{result_header}}{$param};
}
sub state {
    my ($self, $param) = @_; return ${$self->{state}}{$param};
}
sub user_info {
    my ($self, $param) = @_; return ${$self->{user_info}}{$param};
}
sub version {
    my ($self, $param) = @_; return ${$self->{version}}{$param};
}
sub work_unit {
    my ($self, $param) = @_; return ${$self->{work_unit}}{$param};
}
sub perlseti_data {
    my ($self, $param) = @_; return ${$self->{perlseti_data}}{$param};
}

sub message { my ($self) = @_; return @{$self->{messages}}[$self->{message}]; }

sub bar {
    my ($self) = @_;
    my $unitprogbar = ($self->state("prog") * 100) * 0.8;
    return ("#" x $unitprogbar);
}


sub dump {
    my ($self) = @_;
    my ($rectime);

    ($rectime = $self->work_unit("time_recorded")) =~ s/.*\(([^\)]+)\)/$1/;

    return
	"Username      : " . $self->user_info("email_addr") . "\n" .
	"Units RX/TX   : " . $self->user_info("nwus") . " \/ " .
					$self->user_info("nresults") . "\n" .
	"CPU time      : " . $self->user_info("total_cpu") . "\n" .
	"Host          : " . ($self->{host} || $ENV{HOSTNAME}) . "\n" .
	"Source        : " . $self->{source} . "\n" .
 	"Best Spike    : " . $self->perlseti_data("bestspike_power") .
 				" (Score: " .
 				$self->perlseti_data("bestspike_score") .
 				") (" .
 				$self->perlseti_data("bestspike_ra") .
 				" R.A. - " .
 				$self->perlseti_data("bestspike_dec") .
 				" DEC)\n" .
	"Best Gaussian : " . $self->perlseti_data("bestgaussian_power") .
				" (Score: " .
				$self->perlseti_data("bestgaussian_score") .
				") (" .
				$self->perlseti_data("bestgaussian_ra") .
				" R.A. - " .
				$self->perlseti_data("bestgaussian_dec") .
				" DEC)\n" .
	"Base Freq.    : " . $self->work_unit("subband_base") . " Hz\n" .
	"Time Recorded : $rectime\n" .
	"Sky Coordinat.: " . $self->work_unit("start_ra") . " R.A. - " .
				$self->work_unit("start_dec") . " DEC\n\n" .
	"Spike Power   : " . $self->state("bs_power") . "   (Score: " .
					$self->state("bs_score") . ")\n" .
	"Gaussian Power: " . $self->state("bg_power") . "   (Score: " .
					$self->state("bg_score") . ")\n" .
	"FFT Length    : " . $self->state("fl") . "\n" .
	"Dop Shift Rate: " . $self->state("cr") . "\n" .
	"Unit CPU time : " . $self->state("cpu") . "\n" .
	"Done          : " . ($self->state("prog") * 100) . "\%\n" .
	"Unit Progress :\n" . $self->bar . "\n\n" .
	"Message: " . @{$self->{messages}}[$self->{message}] . "\n";
}


1;
__END__



=head1 NAME

SETI::Stats - gather local and remote SETI@home stats and manipulate them

=head1 SYNOPSIS

  use SETI::Stats;

  $s = new SETI::Stats ( rsh => "/semi-free/bin/ssh -l ernie",
                         host => "bert",
                         dir => "/seti" );
  $s->visit;
  print $s->user_info("email_addr");
  print $s->bar . "\n";

  $t = new SETI::Stats ( dir => "/martin/seti", save => "p" );
  while (1) {
    $t->visit;
    print $t->dump . "\n\n";
    sleep(60);
  }


=head1 DESCRIPTION

This Perl class provides an object oriented API which lets you gather
SETI@home stats from one or more machines and gives you a programmatic
way of getting access to them.  It can cope with multiple SETI@home
clients which share a directory hierarchy accessible to the machine it
is run on, clients which each have their own private filespace (using
I<rsh>, I<ssh> or equivalent) and even works for boxes running Windows NT.
   
SETI::Stats borrows from Jan Rocho's B<perlseti.pl>, but differs in
several ways - this is a module devoted to stats gathering rather than
a general purpose control program, it can be used to monitor remote
machines without even requiring Perl to be installed on them, and 
it provides a generic framework for access to (both local and remote)
SETI@home client stats.  It could also be extended to cover stats
gathering from the SETI@home WWW server, though this may be better done
in a separate module to avoid code bloat.

=head1 METHODS

Each B<SETI::Stats> object supports the following methods:

=over 4

=item new

Create a new B<SETI::Stats> object.  The following parameters are
supported:

=over 4

=item dir

This is the (local or remote) directory where B<SETI::Stats> will look
for the SETI@home client's stats files.  It defaults to I</home/seti>.

=item host

When gathering stats remotely, this is the name of the host to contact.
It will also be used as part of the name of B<SETI::Stats>' own state
file - see below for more info on this.

=item rsh

The command (I<rsh> or equivalent) which will be used to contact the
remote host when gathering stats over the Internet.  If you need to
specify a user name or other parameters, you can add them here, e.g.

  rsh => "/semi-free/bin/ssh -l ernie"

This defaults to I<ssh>.

=item save

The filename (absolute or relative) prefix of the local file to store
B<SETI::Stats>' state info in.  This defaults to I<perlseti_data>.  
See below for more information on state file naming.

=item source

The radio telescope data source for the SETI@home client.  By default
this is set to the I<Arecibo Radio Observatory>, which is currently the
only source of data for the SETI@home experiment.

=back

Note that none of these parameters is mandatory.  In particular, you
don't have to store state info between polling clients - unless you
want to use the B<dump> method.  The B<visit> method will store it for
you, however!

=item poll

This method polls the SETI@home client being monitored by this
B<SETI::Stats> object for a given section of its stats.  It takes the
following parameters:

=over 4

=item checkpoint

This indicates that the B<poll> invocation is of the local checkpoint
file maintained by B<SETI::Stats> rather than a (possibly remote) state
file maintained by the SETI@home client itself.  It's set automatically
by the B<visit> method when updating the local checkpoint file.

=item section

This is the section name to poll for, corresponding to the file
I<section>.sah in the SETI@home working directory on the client machine.

=back

This method is normally used internally by the B<visit> method.

=item populate

This method populates the internal data structures used by B<SETI::Stats>
for this section of the stats.  It takes the following parameters:

=over 4

=item results

An array of results, in the format I<attribute>=I<value>, with one
attribute/value pair per entry - e.g. I<prog=0.487688>

=item section

The section name of the stats to populate, e.g. I<work_unit>.

=back

This method is normally used internally by the B<visit> method.

=item checkpoint

This method saves B<SETI::Stats>' current state info to a file on
the local machine (even when monitoring a remote one).  The file name
is determined by the values of the B<dir> and B<save> parameters when
the object was created, e.g. with a B<dir> of I</seti> and a B<save>
of I<perlseti_state>, the file created would be I</seti/perlseti_state.txt>
when the local host was being monitored.

In the case of a remote client being monitored, the host name is appended
to B<dir> and B<save>, prefixed by an underscore, e.g. for the client
machine I<bert>, the file would be I</seti/perlseti_state_bert.txt>.
Note that the value of B<save> no longer needs to contain the string
I<perlseti> (as was the case in B<SETI::Stats> 1.00 and 1.01) for this
feature to work properly.

You don't have to checkpoint, but be aware that this info is used by the
B<dump> method.

This method is normally used internally by the B<visit> method.

=item visit

This method is the one you would normally call when polling a given
SETI@home client for its stats.  It in turn calls the B<poll> method
for each of the I<result_header>, I<state>, I<user_info>, I<version>
and I<work_unit> stats files and populates the B<SETI::Stats> object's
internal data structures with the contents of these files.

These are then accessible through the B<result_header>, B<state>,
B<user_info>, B<version> and B<work_unit> methods.

B<visit> also calls the B<checkpoint> and B<poll> methods, which store
B<SETI::Stats>' state information and populates the internal data
structure used by the B<perlseti_data> method.

=back

Access methods:

=over 4

=item bar

Returns a progress bar of '#' characters, representing the percentage
of the work unit which has been analysed so far - on a scale of 0 to
80 characters, where 80 indicates that the work unit is complete.

=item dump

Returns a SETI stats info 'screen' in the style of B<perlseti.pl>,
based on the last polled values for this SET@home client.

=item perlseti_data

The method returns the value of the nominated parameter in the
I<perlseti_data> section of the client's stats.  This section is
unusual in that it is collected by B<SETI::Stats> rather than the
SETI@home client itself.

=item result_header

This method returns the value of the nominated parameter in the
I<result_header> section of the client's stats.

=item state

This method returns the value of the nominated parameter in the
I<state> section of the client's stats.

=item user_info

This method returns the value of the nominated parameter in the
I<user_info> section of the client's stats.

=item version

This method returns the value of the nominated parameter in the
I<version> section of the client's stats.

=item work_unit

This method returns the value of the nominated parameter in the
I<work_unit> section of the client's stats.

=back

Examples of the access methods in use can be found above in the SYNOPSIS
section of this manpage.

=head1 BUGS

This is still fairly new stuff, so probably contains much which is
apocryphal, or just plain wrong :-)

If the object existed already we should probably take care to overwrite
or remove old stats in a section when doing an update, or we could end up
with the situation that some stats are current but others aren't.

Return codes should be documented.

There should be a test module.

Debugging options would be useful!

=head1 COPYRIGHT

Copyright (c) 1999, Martin Hamilton E<lt>martinh@gnu.orgE<gt>.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Martin Hamilton E<lt>martinh@gnu.orgE<gt>

