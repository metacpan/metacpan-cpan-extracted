package Schedule::Activity::Message;

use strict;
use warnings;
use Ref::Util qw/is_arrayref is_hashref is_ref/;

our $VERSION='0.1.8';

my %property=map {$_=>undef} qw/message attributes names note/;

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		attributes=>$opt{attributes}//{},
		msg       =>[],
		names     =>$opt{names}//{},
	);
	if(is_hashref($opt{message})) {
		if(is_arrayref($opt{message}{alternates})) {
			@{$self{msg}}=grep
				{is_hashref($_) && (
						 (!is_ref($$_{message}) && defined($$_{message}))
					|| (!is_ref($$_{name})    && defined($$_{name}))
				)} @{$opt{message}{alternates}}
		}
		elsif(defined($opt{message}{name})&&!is_ref($opt{message}{name})) { @{$self{msg}}=({name=>$opt{message}{name}}) }
	}
	elsif(is_arrayref($opt{message})) { @{$self{msg}}=grep {!is_ref($_) && defined($_)} @{$opt{message}} }
	elsif(!is_ref($opt{message}))     { @{$self{msg}}=grep {!is_ref($_) && defined($_)} $opt{message} }
	return bless(\%self,$class);
}

sub unwrap {
	my ($self,$msg)=@_;
	if(!defined($msg)) { return ('',$self) }
	my $names=$$self{names};
	if(!is_ref($msg))  {
		if(!defined($$names{$msg})) { return ($msg,$self) }
		return __PACKAGE__->new(%{$$names{$msg}},names=>{})->random();
	}
	if(is_hashref($msg)) {
		my $name=$$msg{name}//$$msg{message};
		if(!defined($$names{$name})) { return ($$msg{message},$msg) }
		return __PACKAGE__->new(%{$$names{$name}},names=>{})->random();
	}
	return ('',$msg);
}

sub primary { my ($self)=@_; return $self->unwrap($$self{msg}[0]) }
sub random  { my ($self)=@_; return $self->unwrap($$self{msg}[ int(rand(1+$#{$$self{msg}})) ]) }

sub attributesFromConf {
	my ($conf)=@_;
	if(!is_hashref($conf)) { return }
	my @res;
	if(is_hashref($$conf{attributes})) {
		while(my ($k,$v)=each %{$$conf{attributes}}) { push @res,[$k,$v] } }
	if(is_arrayref($$conf{alternates})) {
		foreach my $message (grep {is_hashref($_)} @{$$conf{alternates}}) {
			if(is_hashref($$message{attributes})) {
				while(my ($k,$v)=each %{$$message{attributes}}) { push @res,[$k,$v] } } } }
	return @res;
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity::Message - Container for individual or multiple messages

=head1 SYNOPSIS

	my $message=Schedule::Activity::Message->new(
		message   =>'key name',
		message   =>'string message',
		message   =>['array', 'of', 'alternates'],
		message   =>{name=>key},
		message   =>{
			alternates=>[
				{message=>'string', attributes=>{...}},
				{name=>key},
				...
			],
		},
		names=>{
			key=>{
				message=>'string message',
				attributes=>{...}          # optional
			},
		},
		attributes=>{...} # optional
		note      =>...   # optional
	);

=head1 FUNCTIONS

=head2 random

Retrieve a pair of C<(message,object)>, which is either an individual string message, or a random selection from an array or hash of alternatives.  The first index will always be a string, possibly empty.  The object can be used to inspect message attributes.

=head2 attributesFromConf

Given a plain (unknown) message configuration, find any embedded attributes.  This function is primarily useful during schedule configuration validation, prior to full action nodes being built, to identify all attributes within a nested configuration.  It does not need to handle named attributes because those are separately declared.

=head1 NAMED MESSAGES

Named messages permit sharing of common messages across configured instances.  This is particularly useful when there are a large number of common alternate messages where copy/pasting through the scheduling configuration would be egregious.

A reference may be provided to C<names>, each defined with a lookup C<key> and containing a plain message string and, optionally, attributes.  During message selection, any string message or configured C<name> will return the message configuration for C<key=name>, if it exists, or will return the string message.  This applies to all messages configurations (flat strings, array of strings, hash containing a C<message>, and hash containing a C<name>).  If a configured message matches a referenced name, the name takes precedence.

As of version 0.1.2, there is very little validation of the C<names> contents.

=cut
