package Template::Direct::Maths;

use base Template::Direct::Base;
use Template::Direct;

use strict;
use warnings;

=head1 NAME

Template::Direct::Maths - Handle a mathimatical query

=head1 DESCRIPTION

  Provide support for doing simple calculations (SIMPLE ONLY!)

=head1 METHODS

=cut

use Carp;

my %rules = (
	'+' => 3,
	'-' => 3,
	'*' => 2,
	'/' => 2,
	'%' => 1,
	'^' => 0,
);

=head2 I<$class>->new( $index, $line )

  Create a new instance object.

=cut
sub new {
	my ($class, $index, $line, %p) = @_;
	my $self = $class->SUPER::new(%p);
	$self->{'startTag'} = $index;
	my ($s, $p) = split(/=/, $line);
	$self->{'Statement'} = $s;
	$self->{'Print'}     = $p;
	return $self;
}

=head2 I<$maths>->tagName( )

  Returns 'maths'

=cut
sub tagName { 'maths' }

=head2 I<$maths>->singleTag( )

  Returns true

=cut
sub singleTag { 1 }

=head2 I<$maths>->compile( )

  Modifies a template with the data calculated.

=cut
sub compile {
	my ($self, $data, $template, %p) = @_;

	my $statement = $self->parseStatement( $self->{'Statement'}, $data );
	my $result    = $self->calculate( $statement );

	if($self->{'Print'}) {
		$result = sprintf($self->{'Print'}, $result);
	}

	$self->setTagSection($template, $self->{'startTag'}, $result);
}

=head2 I<$maths>->parseStatement( $s, $data )

  Return an array structure of values to calculate.

=cut
sub parseStatement {
	my ($self, $s, $data) = @_;
	my $statement = [];

	#Split into raw tokens
	my @raws = split(/\s+/, $s);
	my @depths;
	my $current = $statement;

	foreach my $raw (@raws) {

		if($raw =~ s/^\(//) {
			# New level
			my $new = [];
			push @{$current}, $new;
			push @depths, $current if $current;
			$current = $new;
		}

		my $end = $raw =~ s/\)$// ? 1 : 0;

		if($raw ne '') {
			# Add sane tokens only, remove all unexpected charicters.
			my $sane = $raw;
			#$sane =~ s/[^\w\$_\{\}\<\>\|\&\=\!\@]//g;

			# Get datum if required, replace this token with real value
			if($sane =~ /^\$(.+)$/) {
				$sane = $data->getDatum($1, forceString => 1);
			}

			# Set 0 when required
			$sane = 0 if not $sane;

			# Push this token onto the current stack.
			push @{$current}, $sane if defined($sane) and scalar($sane.'') ne '';
		}

		$current = pop @depths if $end and @depths;
	}

	return $statement;
}

=head2 I<$maths>->calculate( $statement )

  Return a result based on calulating the statement.

=cut
sub calculate {
	my ($self, $s) = @_;
	my $len = @{$s};

	# Return Directly
	return $s->[0] if $len == 1;

	if($len > 3 and not (($len-1) % 2)) {
		# Sort out the preceidence order and combine.
		my @p;
		# Take each operator index from the stack
		for(my $i=1;$i<$len;$i+=2) {
			push @p, $i;
		}
		foreach my $i (sort { $rules{$s->[$a]} <=> $rules{$s->[$b]} } @p) {
			# Remove 3 tokens, calculate them and
			# Put the result back on the stack
			splice(@{$s}, $i-1, 0, [ splice(@{$s}, $i-1, 3) ] );
			return $self->calculate( $s );
		}
	} elsif($len == 3) {
		# Calculate trinary
		my ($a, $o, $b) = @{$s};
		$a = $self->calculate( $a ) if ref($a) eq 'ARRAY';
		$b = $self->calculate( $b ) if ref($b) eq 'ARRAY';
		return $a + $b if $o eq '+';
		return $a - $b if $o eq '-';
		return $a * $b if $o eq '*';
		return $a / $b if $o eq '/';
		return $a % $b if $o eq '%';
		return $a ** $b if $o eq '^';
		warn "\nUnknown operator '$o' in statement: ".$self->{'statement'}."\n";
		return 0;
	}

	warn "Calculation broken for ".$self->{'Statement'}." : $len (".(($len-1) % 2).")\n";
	return 0;
}

=head1 AUTHOR

  Martin Owens - Copyright 2008, AGPL

=cut
1;
