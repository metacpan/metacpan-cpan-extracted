#*********************************************************************
#*** ResourcePool::Command
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Command.pm,v 1.13 2013-04-16 10:14:44 mws Exp $
#*********************************************************************
package ResourcePool::Command;

use vars qw($VERSION);

$VERSION = "1.0107";

sub new($) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	$self->resetReports();
	return $self;
}

sub init($) {
	my ($self) = @_;
}

sub preExecute($$) {
	my ($self, $res) = @_;
}

sub postExecute($$) {
	my ($self, $res) = @_;
}

sub cleanup($) {
	my ($self) = @_;
}

#sub revertExecute($$) {
#	my ($self, $res) = @_;
#}

sub _resetReports($) {
	my ($self) = @_;
	$self->{reports} = ();
}

sub _addReport($$) {
	my ($self, $rep) = @_;
	push(@{$self->{reports}}, $rep);
}

sub getReports($) {
	my ($self) = @_;
	return @{$self->{reports}};
}

sub info($) {
	my ($self) = @_;
	return ref($self) . ": info() has not been overloaded";
}

1;
