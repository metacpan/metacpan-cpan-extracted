package Perl::Critic::Policy::References::RequireSigils;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

use PPI::Document;
use PPIx::QuoteLike;

our $VERSION = '0.0.6';

Readonly::Scalar my $DESC  => q{Only use arrows for methods};
Readonly::Scalar my $EXPL  => undef;

#-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'directcast',
			description    => 'Prohibit block-style casting of direct references (not yet available).',
			default_string => '1',
			behavior       => 'boolean',
		},
		{
			name           => 'interpolation',
			description    => 'Check interpolated strings for arrow-like patterns.',
			default_string => '1',
			behavior       => 'boolean',
		},
	);
}

sub applies_to           { return qw/PPI::Token::Operator PPI::Token::Quote::Double/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub operatorViolates {
	my ($self,$elem)=@_;
	if($elem->content() ne '->') { return }
	my $next=$elem->snext_sibling();
	if(!$next) { return }
	if($next->isa('PPI::Token::Word') && is_method_call($next)) { return }
	if($next->isa('PPI::Structure::Subscript')) { return $self->invalid($elem) }
	if($next->isa('PPI::Structure::List'))      { return $self->invalid($elem) }
	if($next->isa('PPI::Token::Cast'))          { return $self->invalid($elem) }
	return;
}

sub violates {
	my ($self,$elem,undef)=@_;

	if($elem->isa('PPI::Token::Operator')) { return $self->operatorViolates($elem) }

	if($elem->isa('PPI::Token::Quote')) {
		if(!$$self{_interpolation}) { return }
		my $content=$elem->content();
		my $string=PPIx::QuoteLike->new($content);
		my @tocheck=$string->children();
		while(@tocheck) {
			my $node=shift(@tocheck);
			if($node->isa('PPIx::QuoteLike::Token::Interpolation')) {
				$content=$node->content();
				my $doc=PPI::Document->new(\$content);
				foreach my $inner (@{$doc->find('PPI::Token::Operator')||[]}) {
					if(my $violation=$self->operatorViolates($inner)) { return $violation }
				}
			}
		}
		return;
	}

	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::References::RequireSigils - Only use dereferencing arrows for method calls; use sigils to signal types.

=head1 DESCRIPTION

Post-conditional and post-fix operators are harder to read and maintain, especially within other operators and functions that work only in infix or prefix/function-call mode.  Since certain forms of arrow-dereferencing don't work inside quoted constructs, there can be additional confusion about uniformity of expected behaviors:

	print "Name:  ",$href->{name} # no
	print "Name:  ",$$href{name}  # yes

	print "Item:  ",$aref->[1]    # no
	print "Item:  ",$$aref[1]     # yes

	my @A=$x->@*;                # no
	my @A=@$x;                   # yes

	my $y=$x->method();          # yes
	print "$x->method();"        # invalid code (not checked)

	print "Name:  $href->{name}" # no
	print "Name:  $$href{name}"  # yes

	print "Item:  $aref->[1]"    # no
	print "Item:  $$aref[1]"     # yes

=head1 CONFIGURATION

Violations within interpolated strings can be disabled by setting C<interpolation>:

  [References::RequireSigils]
  interpolation = 0

=head1 NOTES

Not presently well-tested.  There may be some false violations.

Inside Quote/QuoteLike expressions, L<String::InterpolatedVariables> will be used in the future to establish consistency.

Proposed:  Because C<@$x> is a direct casting operation, whereas C<@{ $x }> is a block operator, performance goals may suggest that the latter is a violation of the expected pattern for sigils.  In particular it signals "there is a complicated expansion here", when it fact it is just meant as a direct casting operator.  Future configuration may support enabling required double sigils where possible.

=head1 BUGS

This implementation is primarily "Prohibit non-method arrows" at this time.

=head1 SEE ALSO

See L<Perl::Critic::Policy::References::ProhibitDoubleSigils> to move code away from sigils, but note that does not require postfix dereferencing.

=cut
