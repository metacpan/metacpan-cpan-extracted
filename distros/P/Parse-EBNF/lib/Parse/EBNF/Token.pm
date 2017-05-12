package Parse::EBNF::Token;

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	$self->{error} = 0;
	return $self;
}

sub reduce_alternations {
	my ($self) = @_;

	return 1 unless $self->{type} eq 'list';


	#
	# reduce our own children first
	#

	for my $token(@{$self->{tokens}}){
		$token->reduce_alternations();
	}


	#
	# now check if we have any alts
	#

	my $alts = 0;
	for my $token(@{$self->{tokens}}){
		$alts++ if $token->{type} eq 'alt';
	}

	return 1 unless $alts;


	#
	# we have alts - change our base type and create new alt children
	#

	my $our_tokens = $self->{tokens};
	$self->{tokens} = [];
	$self->{type} = 'alternation';

	my $current = Parse::EBNF::Token->new();
	$current->{type} = 'list';
	$current->{tokens} = [];

	for my $token(@{$our_tokens}){

		if ($token->{type} eq 'alt'){

			push @{$self->{tokens}}, $current;

			$current = Parse::EBNF::Token->new();
			$current->{type} = 'list';
			$current->{tokens} = [];

		}else{
			push @{$current->{tokens}}, $token;
		}
	}

	push @{$self->{tokens}}, $current;

	return 1;
}

sub reduce_repetition {
	my ($self) = @_;

	return 1 unless (($self->{type} eq 'list') || ($self->{type} eq 'alternation'));

	#
	# reduce our own children first
	#

	for my $token(@{$self->{tokens}}){
		$token->reduce_repetition();
	}


	#
	# do it
	#

	my $old_tokens = $self->{tokens};
	$self->{tokens} = [];

	for my $token(@{$old_tokens}){

		if ($token->{type} =~ m!^rep (.*)$!){

			my $new = Parse::EBNF::Token->new();
			$new->{type} = 'repeat '.$1;
			$new->{tokens} = [];

			my $subject = pop @{$self->{tokens}};

			unless (defined $subject){
				$self->{error} = "repetition operator without suject";
				return 0;
			}

			push @{$new->{tokens}}, $subject;

			push @{$self->{tokens}}, $new;
		}else{

			push @{$self->{tokens}}, $token;
		}
	}

	return 1;
}

sub reduce_empty {
	my ($self) = @_;


	#
	# reduce our own children first
	#

	if (defined($self->{tokens})){
		for my $token(@{$self->{tokens}}){
			$token->reduce_empty();
		}
	}


	#
	# reduce self?
	#

	if ($self->{type} eq 'list'){
		if (scalar(@{$self->{tokens}}) == 1){
			my $child = $self->{tokens}->[0];

			for my $key(keys %{$self}){ delete $self->{$key}; }
			for my $key(keys %{$child}){ $self->{$key} = $child->{$key}; }
		}
	}

	return 1;
}

sub reduce_rx {
	my ($self) = @_;


	#
	# reduce our own children first
	#

	if (defined($self->{tokens})){
		for my $token(@{$self->{tokens}}){
			$token->reduce_rx();
		}
	}

	return 1 unless (($self->{type} eq 'alternation') || ($self->{type} eq 'list'));


	#
	# see if we're in a position to reduce self...
	#

	for my $token(@{$self->{tokens}}){
		next if $token->{type} eq 'literal';
		next if $token->{type} eq 'rx';
		return 1;
	}


	#
	# we can reduce all of our children into a single rx
	#

	my @rx;

	for my $token(@{$self->{tokens}}){

		if ($token->{type} eq 'literal'){
			push @rx, '('.quotemeta($token->{content}).')';
		}

		if ($token->{type} eq 'rx'){
			push @rx, $token->{content};
		}
	}

	my $rx = '';
	$rx = join('', @rx) if $self->{type} eq 'list';
	$rx = join('|', @rx) if $self->{type} eq 'alternation';

	$self->{type} = 'rx';
	$self->{content} = $rx;
	$self->{tokens} = [];

	return 1;
}

1;

__END__

=head1 NAME

Parse::EBNF::Token - An EBNF production rule token

=head1 SYNOPSIS

  use Parse::EBNF;


=head1 DESCRIPTION

This module is used internally by the EBNF parser for rule reduction. Parse::EBNF::Token objects are blessed hashes.

=head1 AUTHOR

Copyright (C) 2005, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Parse::EBNF>, L<Parse::EBNF::Rule>

=cut


