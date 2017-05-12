# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl::Runtime;
use strict;
use Data::Dumper;

my $_runtime; # we will use a singleton runtime to track classes etc.

sub runtime {
	my $className = shift;
	unless ($_runtime) {
		$_runtime = bless {}, $className;
		$_runtime->init();
	}
	return $_runtime;
}

sub init {
	my $self = shift;
}

sub debug {
	my $self = shift;
	return $self->{_debug};
}

sub setDebug {
	my $self = shift;
	$self->{_debug} = shift;
}

sub camelBonesCompatibility {
	my $self = shift;
	return $self->{_camelBonesCompatibility};
}

sub setCamelBonesCompatibility {
	my $self = shift;
	$self->{_camelBonesCompatibility} = shift;
}

sub ObjpMsgSend {
	my $className = shift;
	# For some reason, CamelBones yacks if you don't assign the return
	# value to a variable at some point (maybe can't fish things off the stack?)
	# so we would have to do this even without the debug line
	my $returnValue = $className->runtime()->objp_msgSend(@_);
	if ($className->runtime()->debug() & $ObjectivePerl::DEBUG_MESSAGING) {
		print "Return value: ".Data::Dumper->Dump([$returnValue], [qw($value)])."\n";
	}
	return $returnValue;
}

sub objp_msgSend {
	my $self = shift;
	my $receiver = shift || "";
	my $message = shift || "";
	my $selectors = shift || []; # an array of key value pairs

	if ($self->debug() & $ObjectivePerl::DEBUG_MESSAGING) { print "Trying to invoke $message on $receiver\n" };
	return undef unless $receiver;
	return undef unless $message;
	# the first argument is the entry for $message
	my $messageSignature = messageSignatureFromMessageAndSelectors($message, $selectors) || "";

	my $argumentList = [];
	foreach my $selector (@$selectors) {
		push (@$argumentList, $selector->{value});
	}
	
	# send the message
	if (UNIVERSAL::can($receiver, $messageSignature)) {
		if ($self->debug() & $ObjectivePerl::DEBUG_MESSAGING) { print "Invoking $messageSignature on object $receiver\n"; }
		return $receiver->$messageSignature(@$argumentList);
	} else {
		my $messageSignatureWithNoUnderscores = lcfirst(join("", map {ucfirst($_)} split(/_/, $messageSignature)));		
		if (UNIVERSAL::can($receiver, $messageSignatureWithNoUnderscores)) {
			if ($self->debug() & $ObjectivePerl::DEBUG_MESSAGING) { print "Invoking $messageSignatureWithNoUnderscores on object $receiver\n"; }
			return $receiver->$messageSignatureWithNoUnderscores(@$argumentList);
		}
		my $messageSignatureWithTrailingUnderscores = $messageSignatureWithNoUnderscores.("_" x scalar(@$argumentList));
		if (UNIVERSAL::can($receiver, $messageSignatureWithTrailingUnderscores)) {
			if ($self->debug() & $ObjectivePerl::DEBUG_MESSAGING) { print "Invoking $messageSignatureWithTrailingUnderscores on object $receiver\n"; }
			return $receiver->$messageSignatureWithTrailingUnderscores(@$argumentList);
		}
	}
	# TODO: Handle unknown static methods... this will only work with instance methods
	if (UNIVERSAL::can($receiver, "handleUnknownSelector")) {
		if ($self->debug() & $ObjectivePerl::DEBUG_MESSAGING) { print "Invoking handleUnknownSelector on object $receiver\n"; }
		return $receiver->handleUnknownSelector($message, $selectors);
	} else {
		# can't find the method anywhere, so just send it to the object and see what happens
		return $receiver->$messageSignature(@$argumentList);
	}
	return undef;
}

sub messageSignatureFromMessageAndSelectors {
	my $message = shift;
	my $arguments = shift;
	my $messageSignature = $message;
	if ($arguments) {
		foreach my $argument (@$arguments) {
			next if ($argument->{key} eq $message);
			if ($argument->{key} eq "_") {
				$messageSignature .= "_";
			} else {
				$messageSignature .= "_".$argument->{key};
			}
		}
	}
	return $messageSignature;
}

1;
