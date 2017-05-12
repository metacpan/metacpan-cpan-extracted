use strict;
#use warnings;

package RDF::Notation3::RDFCore;

require 5.005_62;
use RDF::Notation3;
use RDF::Core::Model;
use RDF::Core::Statement;
use RDF::Core::Resource;
use RDF::Core::Literal;

############################################################

@RDF::Notation3::RDFCore::ISA = qw(RDF::Notation3);


sub parse_file {
    my ($self, $path) = @_;
    $self->_do_error(1, '') unless @_ > 1;
    $self->_do_error(502, '') unless ref $self->{storage};

    my $model = RDF::Core::Model->new(Storage => $self->{storage});
    $self->{model} = $model;

    $self->SUPER::parse_file($path);
    return $self->{model};
}


sub parse_string {
    my ($self, $str) = @_;
    $self->_do_error(3, '') unless @_ > 1;
    $self->_do_error(502, '') unless ref $self->{storage};

    my $model = RDF::Core::Model->new(Storage => $self->{storage});
    $self->{model} = $model;

    $self->SUPER::parse_string($str);
    return $self->{model};
}


sub set_storage {
    my ($self, $storage) = @_;

    $self->{storage} = $storage;
}


sub get_n3 {
    my ($self, $model) = @_;
    
    my $n3 = '';
    my $tri_tree = {};
    my @tri_seq = ();
    my $namespaces = {};
    map($namespaces->{$self->{hardns}->{$_}->[1]} = $_,
	keys %{$self->{hardns}});

    # building tree
    my $enumerator = $model->getStmts(undef,undef,undef);
    my $statement = $enumerator->getNext;

    while (defined $statement) {
	my $o = $statement->getObject;
	my $ov = ((ref $o) eq 'RDF::Core::Resource') 
	  ? '<' . $o->getURI . '>' : '"' . $o->getValue . '"';

	push @{$tri_tree->{$statement->getSubject->getURI}->{$statement->getPredicate->getURI}}, $ov;

	push @tri_seq, $statement->getSubject->getURI 
	  unless grep($_ eq $statement->getSubject->getURI, @tri_seq);
	
	$namespaces->{$statement->getPredicate->getNamespace} 
	  = $self->_make_prefix unless 
	    exists $namespaces->{$statement->getPredicate->getNamespace};

	$statement = $enumerator->getNext;
    }
    $enumerator->close;

    # namespaces
    foreach (keys %{$namespaces}) {
	$n3 .= "\@prefix $namespaces->{$_}: <$_> .\n";
    }

    # serializing tree
    foreach my $s (@tri_seq) {
	$n3 .= "<$s>\n";
	my @pred = keys %{$tri_tree->{$s}};
	for (my $i=0; $i < @pred; $i++) {
	    $n3 .= ' ' x 8;

	    # resolving predicate prefix
	    my $prefixed = 0;
	    foreach (keys %$namespaces) {
		if ($pred[$i] =~ /^$_(.*)$/) {
		    $n3 .= $namespaces->{$_} . ':' . $1 . ' ';
		    $prefixed = 1;
		    last;
		} 
	    }
	    $n3 .= "<$pred[$i]> " unless $prefixed;
	    
	    # object
	    for (my $j=0; $j < @{$tri_tree->{$s}->{$pred[$i]}}; $j++) {
		$n3 .= $tri_tree->{$s}->{$pred[$i]}->[$j];
		if ($i == $#pred && $j == @{$tri_tree->{$s}->{$pred[$i]}}-1) {
		    $n3 .= " .\n";
		} elsif ($j == @{$tri_tree->{$s}->{$pred[$i]}}-1) {
		    $n3 .= " ;\n";
		} else {
		    $n3 .= " , ";
		}
	    }
	}
    }
    return $n3;
}


sub _process_statement {
    my ($self, $subject, $properties) = @_;

    $subject = $self->_expand_prefix($subject);
    my $sub = RDF::Core::Resource->new($subject);

    foreach (@$properties) {
	if ($_->[0] ne 'i') {
	    $_->[0] = $self->_expand_prefix($_->[0]);
	
	    for (my $i = 1; $i < scalar @$_; $i++ ) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);
	    
		my $pred = $sub->new($_->[0]);
		my $obj;
		if ($_->[$i] =~ /^"(.*)"$/) {
		    $obj  = RDF::Core::Literal->new($1);
		} else {
		    $obj  = RDF::Core::Resource->new($_->[$i]);		    
		}
		my $stat = RDF::Core::Statement->new($sub, $pred, $obj);
		$self->{model}->addStmt($stat);
	    }
	} else {
	    # inverse mode (is, <-)
	    shift @$_;
	    $_->[0] = $self->_expand_prefix($_->[0]);
	
	    for (my $i = 1; $i < scalar @$_; $i++ ) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);

		my $pred = $sub->new($_->[0]);
		my $obj;
		if ($_->[$i] =~ /^".*"$/) {
		    $self->_do_error(501, $_->[$i]);
		} else {
		    $obj  = RDF::Core::Resource->new($_->[$i]);		    
		}
		my $stat = RDF::Core::Statement->new($obj, $pred, $sub);
		$self->{model}->addStmt($stat);
	    }
	} 
    }
}


sub _expand_prefix {
    my ($self, $qname) = @_;

    foreach (keys %{$self->{ns}->{$self->{context}}}) {
	$qname =~ s/^$_:(.*)$/$self->{ns}->{$self->{context}}->{$_}$1/;
    }

    if ($qname =~ /^([_a-zA-Z]\w*)*:[a-zA-Z]\w*$/) {
	$self->_do_error(106, $qname);
    }
    $qname =~ s/^\<(.*)\>$/$1/;

    return $qname;
}


sub _make_prefix {
    my $self = shift;
    $self->{_prefix} ||= 'a';
    return $self->{_prefix}++;
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::RDFCore - creates a RDF::Core model from an N3 file

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3, RDF::Core.

=cut
