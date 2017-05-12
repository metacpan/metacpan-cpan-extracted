package String::Tokeniser;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw();

$VERSION = '0.05';

1;

=pod

=head1 NAME

String::Tokeniser - Perl extension for, uhm, tokenising strings.

=head1 SYNOPSIS

  use String::Tokeniser;

=head1 DESCRIPTION

C<String::Tokeniser> provides an interface to a tokeniser class, allowing
one to manipulate strings on a token-by-token basis without having to
keep track of list element numbers and so on.

=head1 CONSTRUCTOR

=over 4

=item new ( $sentence, [0|-1|$regexp], [$exception...] )

Create a C<String::Tokeniser>, tokenises $sentence and resets the token 
counter. 

The next argument determines how a ``token'' is defined: a value of 0 or
C<undef> determines that underscores B<are> included in a token; -1 states
that they are not. Alternatively, you can supply your own regular
expression which will be fed to a C<split> to determine the tokens.

Then may optionally follow a list of exceptions: tokens that would be
split in two, but should be treated as one.

=back

=cut

sub new {
  my $classname = shift;
  my $self = {};
  bless($self, $classname);
  my $sentence = shift;
  carp "! Nothing to tokenise" unless defined $sentence;
  my $style = shift || 0;
  my @list;
  if ($style==-1) {
    $style= "(?<=[^a-zA-Z0-9])|(?=[^a-zA-Z0-9])";
  } elsif ($style) {
  } else {
    $style="(?<=[^a-zA-Z0-9_])|(?=[^a-zA-Z0-9_])";
  }
  $self->{STYLE} = $style;
  @list = split /$style/, $sentence;
  $self->{LIST} = \@list;
  $self->{COUNT} = 0;
  $self->{STACK} = [];
  $self->_except(@_); # Exception handler. Is not fun.

  return($self);
}

=pod

=head1 METHODS

=over 4

=item moretokens

Tells you if you have any more tokens left to deal with.

=cut

sub moretokens { my $self = shift; 
	return ($self->{COUNT} <= $#{$self->{LIST}})
}

=pod

=item skiptoken([n])

Move the `pointer' forward one (or C<n>) tokens.

=cut
sub skiptoken { my $self=shift; my $howmany=shift;
	$howmany=1 unless defined $howmany;
	$self->{COUNT}+=$howmany;
}

=pod

=item thistoken

Return the current token; that is, the token under the `pointer'.

=cut

sub thistoken { my $self=shift;
	return $self->{LIST}->[$self->{COUNT}];
}

=pod

=item lasttoken

Return the previous token; that is, the one just past the `pointer'.

=cut

sub lasttoken { my $self=shift;
	return $self->{LIST}->[$self->{COUNT}-1];
}

=pod

=item gettoken

Equivalent to C<skiptoken;gettoken> - the usual way of grabbing the
next token in the list in turn.

=cut

sub gettoken { my $self=shift; 
$self->skiptoken(); return $self->lasttoken();}

=pod

=item nexttoken

Looks ahead one token, but does not change the `pointer' position.

=cut

sub nexttoken { my $self=shift;
	return $self->{LIST}->[$self->{COUNT}+1];
}

=pod

=item lookahead([n])

Returns a string composed of the next C<n> tokens, but does not change
the `pointer' position.

=cut

sub lookahead { my $self=shift;
	my $howmany=shift;
	croak "Silly value in lookahead" if $howmany <=1;
	my $ret="";
	for (my $i=$self->{COUNT}; $i<$self->{COUNT}+$howmany; $i++)
		{ $ret.= $self->{LIST}->[$i] }
	return $ret;
}

=pod

=item gimme($string)

Assuming a string of tokens will end in C<$string>, returns everything
from the current `pointer' position until the string is found. Returns
a two-element list: firsly, why the search terminated, (either C<EOF>
meaning we hit the end of the token list without success, or C<FOUND>
meaning C<$string> was found.) and the rest of the tokens upto and
including C<$string> (or the end of the list, whichever was soonest).

=cut

sub gimme { my ($self,$expectation)=(shift,shift);
	my $why="EOF"; my $retval="";
	while ($self->moretokens()) {
		$retval.=$self->gettoken();
		if (substr($retval,-length($expectation)) eq $expectation) {
			$why="FOUND";
			last
		} 
	}
	return ($why, $retval);
}

=pod

=item save

Saves one's pointer position. Can be used multiply as a save stack.

=cut

sub save { my $self=shift;
	push @{$self->{STACK}}, $self->{COUNT};
}

=pod

=item restore

Restores a previously saved position.

=cut

sub restore { my $self=shift; my $temp;
	$self->{COUNT}=$temp if $temp = pop @{$self->{STACK}};
}

=pod 

=back

=head1 FEATURES

At present, there is no support for exceptions which spread over three
or more tokens, although this is planned. 

=head1 AUTHOR

Originaly written by Simon Cozens;
Maintained by Alberto Simoes C<<ambs@cpan.org>>

=head1 SEE ALSO

L<WEBPerl::Changetie>

=cut

# I have no idea how this works any more. And I've *only just* written
# it.
#                 -- Simon Cozens
#
# But it is correct, and simple! You just need to indent it correctly.
#
#                 -- Alberto Simoes

sub _except {
  my $self = shift;
  my $style = $self->{STYLE};
  my %decide;
  my $listref=$self->{LIST};
  my @res;

  while($_ = shift) {   # was foreach(shift) {
    my($left, $right) = split /$style/;
    push @{$decide{$left}}, $right;
  }

  @_ = @$listref;
  while (@_) {
    my($first,$second) = (shift, shift || "");
    if (grep { $first eq $_ and scalar(grep { $second eq $_ } @{$decide{$_}}) } keys %decide ) {
      # I think
      push(@res, $first.$second);
    } else {
      push @res,$first;
      if (grep { $second eq $_ } keys %decide) {
	unshift(@_, $second);
      } else {
	push @res, $second;
      }
    }
  }
  $self->{LIST}=\@res;
  return $self;
}

# sub ishere { return 1 }
