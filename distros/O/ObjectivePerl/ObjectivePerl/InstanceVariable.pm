# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl::InstanceVariable;

use strict;
use vars qw(@ISA);
use Tie::Scalar;
@ISA = qw(Tie::StdScalar);

sub TIESCALAR {
	my $className = shift;
	my $self = { _o => shift,
				 _k => shift };
	return bless $self, $className;
}

sub FETCH {
	my $self = shift;
	return $self->{_o}->{_v}->{$self->{_k}};
}

sub STORE {
	my $self = shift;
	my $value = shift;
	$self->{_o}->{_v}->{$self->{_k}} = $value;
}

1;
