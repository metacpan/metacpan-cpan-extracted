package Perl::Critic::Policy::ControlStructures::ProhibitInlineDo;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.0.3';

Readonly::Scalar my $DESC  => q{Do not use inline do-blocks};
Readonly::Scalar my $EXPL  => undef; # [ ];

#-----------------------------------------------------------------------------

sub applies_to           { return 'PPI::Token::Word' }
sub default_severity     { return $SEVERITY_LOW      }
sub default_themes       { return qw/maintenance complexity/ }
sub supported_parameters { return }

#-----------------------------------------------------------------------------

sub _cmpLocation {
	my ($L,$R)=@_;
	my @ll=@{$L->location()//[]};
	my @rr=@{$R->location()//[]};
	@ll or return;
	@rr or return;
	return ($ll[0]<=>$rr[0]) || ($ll[1]<=>$rr[1]);
}

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$elem->isa('PPI::Token::Word')) { return }
	if(!is_perl_bareword($elem))        { return }
	if(is_method_call($elem))           { return }
	if($elem->content() ne 'do')        { return }

	my $next=$elem->snext_sibling();
	if(!$next || !$next->isa('PPI::Structure::Block')) { return }

	my $parent=$elem->parent();
	if(!$parent) { return $self->violation($DESC,$EXPL,$elem) } # impossible?
	if($parent->isa('PPI::Statement::Sub')) { return }
	if($parent->isa('PPI::Statement')) {
		my $token=$parent->first_token();
		if(0==_cmpLocation($elem,$token)) { return }
	}
	return $self->violation($DESC,$EXPL,$elem);
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitInlineDo - Use subroutines instead of inline do-blocks.

=head1 DESCRIPTION

Functions permit code reuse, isolate scope, and reduce complexity.

	my $handler //= do { ... };         # no
	my $handler //= build_handler(...); # ok
	
	my $value = 1 + do {...} + do {...}; # no
	my $value = 1 + f(...) + g(...);     # ok

Standalone do-blocks are not considered violations.

	do { $x++ } foreach (...); # ok

=head1 CONFIGURATION

None.

=head1 NOTES

Custom subroutines called C<do> will be considered a violation if they are called as C<do {...}>.

Right-hand evaluation of regular expressions is not checked.  EG C<$x=~s/./do{-}/e>

=cut
