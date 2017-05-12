#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Query/Result.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/29/2004
# Revision:	$Id: Result.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Query::Result;

use strict;
use warnings;

use ODO::Node;
use ODO::Jena::Node::Parser;

use ODO::Exception;
use ODO::Statement;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use base qw/ODO::Query::Simple::Result/;


=head1 NAME

ODO::Jena::Query::Result -

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=item new(  )

=head1 METHODS

=over

=item

=cut

sub init {	
	my ($self, $config) = @_;
	
	my @result_array;
	tie @result_array, 'ODO::Jena::Query::Result::Tie::Array', $config->{'results'};
	$config->{'results'} = \@result_array;
	
	$self = $self->SUPER::init( $config );
	
	return $self;	
}


sub DESTROY {
	my $self = shift;
	untie $self->{'results'};
}


package ODO::Jena::Query::Result::Tie::Array;

use strict;
use warnings;

use Tie::Array;

use ODO::Statement;

use ODO::Jena::Node;
use ODO::Jena::Node::Parser;

use base qw/Tie::StdArray/;


sub TIEARRAY {
	return bless $_[1], $_[0];
}

sub STORE {
	$_[0]->[$_[1]] = __jena_decompose($_[2]);
}


sub PUSH {
	my $o = shift;
	push(@$o, map { __jena_decompose($_); } @_)
}


sub FETCH {
	return __to_statement($_[0]->[$_[1]]);
}


sub POP {
	return __to_statement(pop(@{$_[0]}));
}


sub SHIFT {
	return __to_statement(shift(@{$_[0]}));
}

sub UNSHIFT {
	my $o = shift;
	unshift(@$o, map { __jena_decompose($_); } @_);
}

sub __jena_decompose {
	my $stmt = shift;

	return undef
		unless $stmt;
	
	my $s = $stmt->s();
	my $p = $stmt->p();
	my $o = $stmt->o();
	
	unless(UNIVERSAL::isa($stmt, 'ODO::Jena::Node')) {
		$s = ODO::Jena::Node->to_jena_node($s);
		$p = ODO::Jena::Node->to_jena_node($p);
		$o = ODO::Jena::Node->to_jena_node($o);
	}
	
	return [ $s->serialize(), $p->serialize(), $o->serialize() ];
}


sub __to_statement {
	my $jena_stmt_arr = shift;
	
	return undef
		unless(UNIVERSAL::isa($jena_stmt_arr, 'ARRAY'));
	
	my $s = ODO::Jena::Node::Parser->parse($jena_stmt_arr->[0]);
	my $p = ODO::Jena::Node::Parser->parse($jena_stmt_arr->[1]);
	my $o = ODO::Jena::Node::Parser->parse($jena_stmt_arr->[2]);
	
	return ODO::Statement->new($s, $p, $o);
}

=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Graph::Storage>, L<ODO::Jena>, L<ODO::Query::Result>, L<ODO::Query::Simple::Result>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__
