package Net::FSP::Handle;

use strict;
use warnings;
use base 'Exporter';
our $VERSION   = $Net::FSP::VERSION;
our @EXPORT_OK = qw/do_or_fail/;

use Carp;
use Errno qw/EIO/;

require Net::FSP::Handle::Read;
require Net::FSP::Handle::Write;

my %class_for = (
	'<' => 'Net::FSP::Handle::Read',
	'>' => 'Net::FSP::Handle::Write',
);

sub do_or_fail(&) {    ##no critic prototype
	my $action = shift;
	local $@;
	my $ret;
	eval { $ret = $action->(); };
	if ($@) {
		$! = EIO;
		return;
	}
	return $ret;
}

sub TIEHANDLE {
	my (undef, $fsp, $filename, $mode) = @_;
	my $class = $class_for{$mode} or croak "Invalid or unsuppored mode specified\n";
	my $self = bless { fsp => $fsp }, $class;
	$self->OPEN($mode, $filename);
	return $self;
}

sub CLOSE {
	my $self = shift;
	for my $key (keys %{$self}) {
		delete $self->{$key} if $key ne 'fsp';
	}
	return 1;
}

sub DESTROY {
	my $self = shift;
	$self->CLOSE;
	return;
}

1;

__END__

=begin ignore

=item do_or_fail

=cut
