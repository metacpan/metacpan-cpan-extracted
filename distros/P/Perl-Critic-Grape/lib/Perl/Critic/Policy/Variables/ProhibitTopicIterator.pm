package Perl::Critic::Policy::Variables::ProhibitTopicIterator;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.0.4';

Readonly::Scalar my $DESC  => q{Always use named loop control variables};
Readonly::Scalar my $EXPL  => undef; # [ ];

#-----------------------------------------------------------------------------

sub applies_to           { return 'PPI::Statement::Compound' }
sub default_severity     { return $SEVERITY_LOW      }
sub default_themes       { return qw/maintenance complexity/ }
sub supported_parameters { return }

#-----------------------------------------------------------------------------

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$elem->isa('PPI::Statement::Compound')) { return }
	my $node=$elem->first_element();
	if(!$node->isa('PPI::Token::Word')) { return }
	my $type=$node->content();
	my $next=$node->snext_sibling();
	if(!$next) { return } # invalid syntax?
	#
	if($type=~/^for(?:each)?$/) {
		if($next->isa('PPI::Structure::List'))                          { return $self->violation($DESC,$EXPL,$elem) }
		if($next->isa('PPI::Token::Magic')&&($next->content() eq '$_')) { return $self->violation($DESC,$EXPL,$elem) }
		if($next->isa('PPI::Structure::For')) {
			if($next->find_first(sub {
				my (undef,$e)=@_;
				if(!$e->isa('PPI::Token::Magic')) { return 0 }
				if($e->content() ne '$_')         { return 0 }
				my $ne=$e->snext_sibling();
				if(!$ne)                              { return 0 }
				if(!$ne->isa('PPI::Token::Operator')) { return 0 }
				if($ne->content() ne '=')             { return 0 }
				return 1;
			})) { return $self->violation($DESC,$EXPL,$elem) }
			return;
		}
		if($next->isa('PPI::Token::Symbol'))                           { return }
		if($next->isa('PPI::Token::Word')&&($next->content() eq 'my')) { return }
	}
	elsif(($type=~/^(?:if|while)$/)&&$next->isa('PPI::Structure::Condition')) {
		if($next->find_first(sub {
			my (undef,$e)=@_;
			if(!$e->isa('PPI::Token::Magic')) { return 0 }
			if($e->content() ne '$_')         { return 0 }
			my $ne=$e->snext_sibling();
			if(!$ne)                              { return 0 }
			if(!$ne->isa('PPI::Token::Operator')) { return 0 }
			if($ne->content() ne '=')             { return 0 }
			return 1;
		})) { return $self->violation($DESC,$EXPL,$elem) }
		return;
	}
	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitTopicIterator - Use named loop control variables.

=head1 DESCRIPTION

Loops with no named variable become a maintenance concern as the loop complexity grows.  Larger, multi-line, and nested loops can lead to programmer confusion about the true meaning of C<$_>.  To ensure long-term maintainability of code, named variables are recommended for all loops.

This policy considers any loop control without a named variable to be a violation.

Moreover, if/while statements that assign directly to C<$_> are considered a violation.

	foreach my $i (1..3)    { ... } # ok
	for(my $i=1;$i<=3;$i++) { ... } # ok
	for my $i (1..3)        { ... } # ok
	if(my $i=shift(@A))     { ... } # ok
	while(my $i=shift(@A))  { ... } # ok

	foreach (1..3)       { ... } # not ok
	for($_=1;$_<=3;$_++) { ... } # not ok
	for (1..3)           { ... } # not ok
	if($_=shift(@A))     { ... } # not ok
	while($_=shift(@A))  { ... } # not ok

=head1 CONFIGURATION

None at this time, but future configuration may make the policy I<less> aggressive about certain constructions.

=head1 NOTES

Post-conditionals can be enforced with L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>.

=cut
