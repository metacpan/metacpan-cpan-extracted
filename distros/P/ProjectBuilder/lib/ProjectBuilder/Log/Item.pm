package ProjectBuilder::Log::Item;

# Each PB::Log::Item represents one machine

use strict;

# the *matches represents strings, which a line must contain, to be recognized as a corresponding found
# the *exludes can be used to exclude a string (if the string contains a *match and a *exclude, the line is ignored)
# the name is by default the name of the vm (e.g. ubuntu-10.04-i386)
sub new {
	# contains the object name (here PBLog)
	my $object = shift;
	my $vmname = shift || "";
	my $log = shift || "";

	my $self = {};
	# $ref should point to an object of type $object
	bless($self, $object);

	# array of strings, which are indicating errors or warnings (case insensitive)
	$self->{'errormatches'} = [];
	$self->{'warningmatches'} = [];
	# array of strings, which are excluded from error lines (case insensitive)
	$self->{'errorexcludes'} = [];
	$self->{'warningexcludes'} = [];

	push(@{$self->{'errormatches'}}, "error");
	push(@{$self->{'errormatches'}}, "fehler");

	push(@{$self->{'warningmatches'}}, "warning");
	push(@{$self->{'warningmatches'}}, "warnung");

	# init default values
	$self->setName($vmname);
	$self->setLog($log);

	return($self);
}

#set's the name
sub setName {
	my $self = shift;
	my $vmname = shift || "";

	$self->{'vmname'} = $vmname;
}

# returns the name
sub name {
	my $self = shift;

	return $self->{'vmname'};
}

# set's the log and calls the analyzer (parseLog())
sub setLog {
	my $self = shift;
	my $log = shift || "";
	
	$self->{'qawarnings'} = [];
	$self->{'qaerrors'} = [];
	$self->{'warnings'} = [];
	$self->{'errors'} = [];
	$self->{'log'} = $log;
	$self->parseLog;
}

# returns the "raw" log text
sub log {
	my $self = shift;

	return $self->{'log'};
}

# returns the number of warnings and errors reported by lintian or rpmlint
sub numQaIssues {
	my $self = shift;

	return scalar($self->qaIssues);
}

# returns the issues itself
sub qaIssues {
	my $self = shift;
	my @result = $self->qaErrors;

	push(@result, $self->qaWarnings);
	return @result;
}

#returns only the warnings
sub qaWarnings {
	my $self = shift;

	return @{$self->{'qawarnings'}};
}

# returns only the errors
sub qaErrors {
	my $self = shift;

	return @{$self->{'qaerrors'}};
}

# returns the number of compile errors
# or better, all other than lintian and rpmlint
sub numErrors {
	my $self = shift;

	return scalar($self->errors);
}

# returns the errors itself
sub errors {
	my $self = shift;

	return @{$self->{'errors'}};
}

# same for warnings
sub numWarnings {
	my $self = shift;

	return scalar($self->warnings);
}

# same for warnings
sub warnings {
	my $self = shift;

	return @{$self->{'warnings'}};
}

# private part

# parses the log
sub parseLog {
	my $self = shift;
	
	my @lines = split("\n", $self->{'log'});
	foreach my $line (@lines) {
		# check for lintian or rpmlint errors
		if ($line =~ m/^W:/) {
			push(@{$self->{'qawarnings'}}, $line);
		} elsif ($line =~ m/^E:/) {
			push(@{$self->{'qaerrors'}}, $line);
		} else {
			# error detect
			my $iserror = 0;
			foreach my $errormatch (@{$self->{'errormatches'}}) {
				if($line =~ m/$errormatch/){
					# check wether an exclude is also true
					my $isexcluded = 0;
					foreach my $exclude (@{$self->{'errorexcludes'}}) {
						if ($line =~ m/$exclude/) {
							$isexcluded = 1;
							last;
						}
					}
					if ($isexcluded == 0) {
						# it is an error and not excluded, so add it to array
						push(@{$self->{'errors'}}, $line);
						$iserror = 1;
						last;
					}
				}
			}

			# warning detect
			if ($iserror == 0) {
				foreach my $match (@{$self->{'warningmatches'}}) {
					if($line =~ m/$match/){
						# check wether an exclude is also true
						my $isexcluded = 0;
						foreach my $exclude (@{$self->{'warningexcludes'}}) {
							if ($line =~ m/$exclude/) {
								$isexcluded = 1;
								last;
							}
						}
						if ($isexcluded == 0) {
							# it is an error and not excluded, so add it to array
							push(@{$self->{'warnings'}}, $line);
							$iserror = 1;
							last;
						}
					}
				}
			}
		}
	}
}

1;
