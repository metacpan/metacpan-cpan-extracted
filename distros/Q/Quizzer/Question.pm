#!/usr/bin/perl -w

=head1 NAME

Quizzer::Question - Question object

=cut

=head1 DESCRIPTION

This is an object that represents a Question. Each Question has some
associated data. To get at this data, just use $question->fieldname
to read a field, and  $question->fieldname(value) to write a field. Any
field names at all can be used, the convention is to lower-case their names,
and prefix the names of fields that are flags with "flag_". If a field that
is not defined is read, and a field by the same name exists on the Template
the Question is mapped to, the value of that field will be returned instead.

=cut

=head1 METHODS

=cut

package Quizzer::Question;
use strict;
#use Quizzer::ConfigDb;
use Quizzer::Base;
use vars qw($AUTOLOAD @ISA);
@ISA=qw(Quizzer::Base);

my $VERSION='0.01';

=head2 new

Returns a new Question object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{flag_isdefault}='true';
	$self->{variables}={};
	return $self;
}

# This is a helper function that expands variables in a string.
sub _expand_vars {
	my $this=shift;
	my $text=shift;
	
	my %vars=%{$this->variables};
	
	my $rest=$text;
	my $result='';
	while ($rest =~ m/^(.*?)\${([^{}]+)}(.*)$/sg) {
		$result.=$1;  # copy anything before the variable
		$result.=$vars{$2} if defined($vars{$2}); # expand the variable
		$rest=$3; # continue trying to expand rest of text
	}
	$result.=$rest; # add on anything that's left.
	
	return $result;
}

=head2 description

Returns the description of this Question. This value is taken from the Template
the Question is mapped to, and then any substitutions in the description are
expanded.

=cut

sub description {
	my $this=shift;
	return $this->_expand_vars($this->template->description);
}

=head2 answer

Returns the abswer to this Question. This value is taken from the Template
the Question is mapped to, and then any substitutions in the answer are
expanded.

=cut

sub answer {
	my $this=shift;
	return $this->_expand_vars($this->template->answer);
}

=head2 answer2

Returns the alternative answer to this Question. 
This is used when you want to allow an alternative answer to a Question
(expecially questions where answers are provided by means of a String text 
field ...).
This value is taken from the Template the Question is mapped to, and then 
any substitutions in the answer are expanded.

=cut

sub answer2 {
	my $this=shift;
	return $this->_expand_vars($this->template->answer2);
}

=head2 explanation

Returns the explanation of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in the
explanation are expanded.

=cut

sub explanation {
	my $this=shift;
	return $this->_expand_vars($this->template->explanation);
}

=head2 extended_description

Returns the extended description of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in the extended
description are expanded.

=cut

sub extended_description {
	my $this=shift;
	return $this->_expand_vars($this->template->extended_description);
}

=head2 choices

Returns the choices field of this Question. This value is taken from the
Template the Question is mapped to, and then any substitutions in it
are expanded.

=cut

sub choices {
	my $this=shift;
	
	return $this->_expand_vars($this->template->choices);
}

=head2 choices_split

This takes the result of the choices method and simply splits it up into
individual choices and returns them as a list.

=cut

sub choices_split {
	my $this=shift;
	
	return split(/,\s+/, $this->choices);
}

=head2 variables

Access the variables hash, which is a hash of values that are used in the above
substitutions. Pass in no parameters to get the full hash. 
Pass in one parameter to get the value of that hash key. Pass in two parameters
to set a hash key to a value.

=cut

sub variables {
	my $this=shift;
	
	if (@_ == 0) {
		return $this->{variables};
	} elsif (@_ == 1) {
		my $varname=shift;
		return $this->{variables}{$varname};
	} else {
		my $varname=shift;
		my $varval=shift;
		return $this->{variables}{$varname} = $varval;
	}
}	

=head2 value

Get the current value of this Question. Will return the default value is there
is no value set. Pass in a value to set the value.

=cut

sub value {
	my $this = shift;
	
	if (@_ == 0) {
		return $this->{value} if (defined $this->{value});
		return $this->template->default;
	} else {
		return $this->{value} = shift;
	}
}

=head2 value_split

This takes the result of the value method and simply splits it up into
individual values and returns them as a list.

=cut

sub value_split {
	my $this=shift;
	
	return split(/,\s+/, $this->value);
}

=head2 owners

This method allows you to get/set the owners of a Question. The owners are
returned in a comma and space delimited list, a similar list should be
passed in if you wish to use this function to set them. (Internally, the
owners are stored quite differently..)

=cut

sub owners {
	my $this=shift;
	
	if (@_) {
		# Generate hash on fly.
		my %owners=map { $_, 1 } split(/,\s*/, shift);
		$this->{'owners'}=\%owners;
	}
	
	if ($this->{'owners'}) {
		return join(", ", keys %{$this->{'owners'}});
	}
	else {
		return "";
	}
}

=head2 addowner

Add an owner to the list of owners of this Question. Pass the owner name.
Adding an owner that is already listed has no effect.

=cut

sub addowner {
	my $this=shift;
	my $owner=shift;

	# I must be careful to access the real hash, bypassing the 
	# method that stringifiys the owners property.
	my %owners;
	if ($this->{'owners'}) {
		%owners=%{$this->{'owners'}};
	}
	$owners{$owner}=1;
	$this->{'owners'}=\%owners;
}

=head2 removeowner

Remove an owner from the list of owners of this Question. Pass the owner name
to remove.

=cut

sub removeowner {
	my $this=shift;
	my $owner=shift;
	
	# I must be careful to access the real hash, bypassing the
	# method that stringifiys the owners property.
	my %owners;
	if ($this->{'owners'}) {
		%owners=%{$this->{'owners'}};
	}
	delete $owners{$owner};
	$this->{'owners'}=\%owners;
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;

	$property =~ s|.*:||; # strip fully-qualified portion

	$this->{$property}=shift if @_;
	return $this->{$property} if (defined $this->{$property});
	# Fall back to template values.
	return $this->{template}->$property();
}

### Aggiungiamo il distruttore, altrimenti il perl si lamenta ###
sub DESTROY {
	### Non fa un bel nulla ###
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
