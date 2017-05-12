=head1 NAME

Probe::MachineInfo::SimpleMetric - Simple Metric Collector

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::SimpleMetric;


# pragmata
use base qw(Probe::MachineInfo::Metric);
use strict;
use warnings;


# Standard Perl Library and CPAN modules
use English;
use Proc::Reliable;

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#


=head2 get

 get()

=cut

sub get {
	my($self) = @_;

	return $self->get_via_cmd() if($self->command());
	return $self->get_via_file() if($self->filename());

}

=head2 get_via_cmd

 get_via_cmd()

=cut

sub get_via_cmd {
	my ($self) = @_;

	my $cmd = $self->command();
	return unless $cmd;

	my($executable) = $cmd =~ m/^(\S+)/;

	if(not -r $executable) {
		$self->log->warn("$executable is not readable\n");
		return;
	}
	elsif(not -x _) {
		$self->log->warn("$executable is not executable\n");
		return;
	}

	my $proc = Proc::Reliable->new();

	my $output = $proc->run($cmd);

	if($proc->status()) {
		my $err = $proc->stderr();
		$self->log->warn("$cmd exited with non zero exit status $err\n");
		return;
	}

	unless($output) {
		$self->log->warn("$cmd returned no output\n");
		return;
	}

	if($self->linenumber()) {
		my $n = $self->linenumber();
		my @lines = split("\n", $output);
		$output = $lines[$n];
	}

	return $self->filter_through_regex($output);
}

=head2 get_via_file

 get_via_file()

=cut

sub get_via_file {
	my($self) = @_;

	my $file = $self->filename();
	return unless $file;

	if(! -r $file) {
		$self->log->warn("$file is not readable\n");
		return;
	}

	open (my $fh, '<', $file) or return;
	my @contents = <$fh>;
	close $fh;

	if(my $n = $self->linenumber()) {
		return->filter_through_regex($contents[$n])
	}
	else {
		return->filter_through_regex(join("\n", @contents))
	}	
}

=head2 filter_through_regex

  filter_through_regex($value)

=cut

sub filter_through_regex {
	my($self, $value) = @_;


	chomp $value;

	if(my $regex = $self->regex()) {
		my($value) = $value =~ m/$regex/;
		return $value;
	}

	return $value;
}

=head2 command

 command()

=cut

sub command {
	my($self) = @_;

	return;
}


=head2 linenumber

 linenumber()

=cut

sub linenumber {
	my($self) = @_;

	return;
}

=head2 regex

 regex()

=cut

sub regex {
	my($self) = @_;

	return;
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
