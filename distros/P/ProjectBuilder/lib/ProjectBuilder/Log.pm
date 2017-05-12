package ProjectBuilder::Log;

# this class can be used to store and analyze the complete log from pb
# this includes more than one vm

use strict;
use ProjectBuilder::Version;
use ProjectBuilder::Base;
use ProjectBuilder::Log::Item;

sub new {
	# contains the object name (here PBLog)
	my $object = shift;
	my $self = {};

	# $self should point to an object of type $object
	bless($self, $object);
   
	# this array stores our childs
	$self->{'logitems'} = [];

	return($self);
}

# returns number of handled ProjectBuilder::Log::Item's
sub countItems {
	my $self = shift;
	return scalar(@{$self->{'logitems'}});
}

# returns an array of all names of handled ProjectBuilder::Log::Item's
# the name is the vm name (e.g. ubuntu-10.04-i386 (by default))
sub itemNames {
	my $self = shift;
	my @result = ();

	foreach my $item (@{$self->{'logitems'}}) {
		push(@result, $item->name());
	}
	return @result;
}

# set's the log for ProjectBuilder::Log::item $vmname
# if such an item is not present, one is added
# $log should only contain the log of one machine
sub setLog {
	my $self = shift;
	my $vmname = shift;
	my $log = shift;
	  
	my $logitem = $self->findItem($vmname);
	if (!$logitem) {
		$logitem = new ProjectBuilder::Log::Item($vmname);
		push(@{$self->{'logitems'}}, $logitem);
	}
	$logitem->setLog($log);
}

# used to analyze the complete log of pb
sub setCompleteLog {
	my $self = shift;
	my $log = shift;
	my $tmplog = "";
	my $item = undef;
	  
	foreach my $line (split("\n", $log)) {
		if ($line =~ m/^Waiting [0-9]+ s for VM/) {
			# here starts a new machine, so append the tmplog to the last one
			if (defined($item)) {
				$item->setLog($tmplog);
			}
			if($line =~ m/VM ([^\s]+)/){
				$item = new ProjectBuilder::Log::Item($1);
				push(@{$self->{'logitems'}}, $item);
				$tmplog = 0;
			}
		} else {
			$tmplog .= $line ."\n";
		}
	}
	if (defined($item) && ($tmplog)) {
		$item->setLog($tmplog);
	}
}

# nums the issues (Warnings and Errors from lintian and rpmlint
# if no name is given, the total of all ProjectBuilder::Log::Item's is returned
sub numQaIssues {
	my $self = shift;
	my $itemname = shift || "";
	my $result = 0;

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			$result += scalar($item->qaIssues());
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			$result = $item->numQaIssues();
		}
	}
	return $result;
}

# returns the issues itself
# behaves like numQaIssues
sub qaIssues {
	my $self = shift;
	my $itemname = shift || "";
	my @result = ();

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			push(@result, $item->qaIssues());
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			push(@result, $item->qaIssues());
		}
	}
	return @result;
}

# same as num qaIssues but for compile errors
sub numErrors {
	my $self = shift;
	my $itemname = shift || "";
	my $result = 0;

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			$result += $item->numErrors();
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			$result = $item->numErrors();
		}
	}
	return $result;
}

# returns the compile errors itself
# behaves like numQaIssues
sub errors {
	my $self = shift;
	my $itemname = shift || "";
	my @result = ();

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			push(@result, $item->errors());
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			push(@result, $item->errors());
		}
	}
	return @result;
}

# same as num qaIssues but for compile warnings
sub numWarnings {
	my $self = shift;
	my $itemname = shift || "";
	my $result = 0;

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			$result += $item->numWarnings();
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			$result = $item->numWarnings();
		}
	}
	return $result;
}

# returns the compile warnings itself
# behaves like numQaIssues
sub warnings {
	my $self = shift;
	my $itemname = shift || "";
	my @result = ();

	if ($itemname eq "") {
		# no machine selected, so return combine from all items
		foreach my $item (@{$self->{'logitems'}}) {
			push(@result, $item->warnings());
		}
	} else {
		my $item = $self->findItem($itemname);
		if ($item) {
			push(@result, $item->warnings());
		}
	}
	return @result;
}

# prints out a summary of the log
sub summary {
	my $self = shift;
	my $summary = "";

	$summary = "Items: ". $self->countItems();
	$summary .= " (QA Issues: ". $self->numQaIssues();
	$summary .= ", Warnings: ". $self->numWarnings();
	$summary .= ", Errors: ". $self->numErrors() .")\n";
	foreach my $name ($self->itemNames()) {
		$summary .= $name ." (QA Issues: ". $self->numQaIssues($name);
		$summary .= ", Warnings: ". $self->numWarnings($name);
		$summary .= ", Errors: ". $self->numErrors($name) .")\n";
	}
	return $summary;
}

# mails the summary to $to
sub mailSummary {
	eval
	{
		require Mail::Sendmail;
		Mail::Sendmail->import();
	};
	if ($@) {
		# Mail::Sendmail not found not sending mail !
		pb_log(0,"No Mail::Sendmail module found so not sending any mail !\n");
	} else {
		my $self = shift;
		my $to = shift || "";

		if ($to eq "") {
			pb_log(0,"Please give a To: address\n");
			return;
		}
		my %mail = (	
			To => $to,
			From => "pb\@localhost",
			Message => $self->summary()
		);
		if (! sendmail(%mail)) { 
			if (defined $Mail::Sendmail::error) {
				return $Mail::Sendmail::error;
			} else {
				return "Unkown error";
			}
		}
		pb_log(0,"Mail send to ". $to ."\n");
	}
}

# private part (perl does not no about private, but it is meant so)
# find's item with name $vmname in handled OB::Log::Item's
sub findItem {
	my $self = shift;
	my $vmname = shift;

	# find existing item or add item if needed
	foreach my $logitem (@{$self->{'logitems'}}) {
		if ($logitem->name eq $vmname) {
			return $logitem;
		}
	}
	return 0;
}

1;
