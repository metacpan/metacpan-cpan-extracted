package Seshat;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use POSIX qw(strftime);
use Data::Dumper;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.1';

sub new {
	my $classname = shift;
	my $filename = shift;
	my %params = @_;
	my $self = {};
	$self->{NAME} = "Seshat";
	$self->{FILE} = $filename;
	$self->{FLAG} = 0;
	$self->{POS} = 0;

	# -> defaults -< #
	$self->{PARAM}->{LOG_LEVEL} = "0";
	$self->{PARAM}->{DATE_FORMAT} ="%a %b %e %H:%M:%S %Y";
	

	foreach (keys %params) {
		if (exists $self->{PARAM}->{$_}) {
			$self->{PARAM}->{$_} = $params{$_};
		}
	}
	bless ($self,$classname);
	return $self;
}

sub write {
	my ($self, $string, $flag) = @_; 
	open(FH, ">>".$self->{FILE}) 
		or ( $@="cant open ".$self->{FILE}.": $!" 
		     && return undef);
	my $flocked = 0;
	while (! $flocked ) {
		if (! flock(FH, 2)) {
			sleep 1;
		}
		else {
			$flocked = 1;
		}
	} 

	my $print_string;

	if ($self->{FLAG} eq 1) { seek(FH,$self->{POS},0) }		# the line is not blank
	else { 
		#$print_string = strftime "%a %b %e %H:%M:%S %Y", localtime; 
		$print_string = strftime $self->{PARAM}->{DATE_FORMAT}, localtime; 
		$print_string .= " : $0 : ";
	}
	$print_string .= "$string";

	if ($flag eq 1) {		# new line...
		$print_string .= "\n";
		print FH $print_string;
		$self->{FLAG} = 0;
	}
	elsif ($flag eq 0) {		#no new line... 
		print FH $print_string;
		$self->{FLAG} = 1;	
		my $index = tell(FH);
		$self->{POS} = $index;	
	}
	
	close(FH) 
		or ($@= "can't close $!" 
		    && return undef);
	return 1;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Seshat - Perl Extension for writing modules

"Seshat, her who writes..."

=head1 SYNOPSIS

  use Seshat;
  
  my $lh = Seshat->new($log_filename[, PARAM => VALUE [, ...]]);

  $res = $lh->write($string,$nl_bool);


=head1 DESCRIPTION

  Seshat is a module designed to handle more than one log, and log files shared by two or more processes.
  It is a concurrency safe system, and implements extra information about the script that is writing the log.


=head1 METHODS

=over

=item $lh = Seshat->new($log_filename [, PARAM => VALUE [, ...]])

Creates a new object that uses th $log_filename as the log file

Parameter description:

DATE_FORMAT => $string 
  
  Defines the format of the date that is written to the log file

	Types:

	%a -> short day 
	%A -> long day 
	%b -> short month
	%B -> long month
	%d -> month day
	%g -> last 2 dig of year
	%G -> year
	%c -> long date
	%D -> short date
	%F -> short date (inverted)
	%H -> hour
	%M -> minutes
	%S -> seconds
	
	ex: "%a %b %G - %H:%M:%S" 
	     Tue Oct 2000 - 13:59:41

LOG_LEVEL => [0..5]

  Defines the amount of information about the caller script that is written to the log file

=item $res = $lh->write($string,$nl_bool);

Writes the $string to the log file , and terminates the line or not ($nl_bool)

=back

=head1 TODO

Sugestions accepted

=head1 AUTHOR

Bruno Tavares (bat@isp.novis.pt)  

=head1 SEE ALSO

perl(1), Seshat::Parallel(1)

=cut
