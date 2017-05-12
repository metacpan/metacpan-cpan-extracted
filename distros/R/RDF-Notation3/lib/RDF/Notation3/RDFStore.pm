use strict;
#use warnings;

package RDF::Notation3::RDFStore;

require 5.005_62;
use RDF::Notation3;
use RDFStore::NodeFactory;
use RDFStore::Model;

############################################################

@RDF::Notation3::RDFStore::ISA = qw(RDF::Notation3);


sub parse_file {
    my ($self, $path) = @_;
    $self->_do_error(1, '') unless @_ > 1;

    $self->{factory} = RDFStore::NodeFactory->new();
    $self->{model} = RDFStore::Model->new(%{$self->{options}});

    $self->SUPER::parse_file($path);
    return $self->{model};
}


sub parse_string {
    my ($self, $str) = @_;
    $self->_do_error(3, '') unless @_ > 1;

    $self->{factory} = RDFStore::NodeFactory->new();
    $self->{model} = RDFStore::Model->new(%{$self->{options}});

    $self->SUPER::parse_string($str);
    return $self->{model};
}


sub set_options {
    my ($self, $options) = @_;

    $self->{options} = $options;
}


sub _process_statement {
    my ($self, $subject, $properties) = @_;

    my $subject = $self->_expand_prefix($subject);
    my $sub = $self->{factory}->createResource($subject);

    foreach (@$properties) {
	if ($_->[0] ne 'i') {
	    $_->[0] = $self->_expand_prefix($_->[0]);
	
	    for (my $i = 1; $i < scalar @$_; $i++ ) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);
	    
		my $pred  = $self->{factory}->createResource($_->[0]);
		my $obj;
		if ($_->[$i] =~ /^"(.*)"$/) {
		    $obj = $self->{factory}->createLiteral($_->[$i]);
		} else {
		    $obj = $self->{factory}->createResource($_->[$i]);
		}
		my $stat = $self->{factory}->createStatement($sub,$pred,$obj);
		$self->{model}->add($stat);
	    }
	} else {
	    # inverse mode (is, <-)
	    shift @$_;
	    $_->[0] = $self->_expand_prefix($_->[0]);
	
	    for (my $i = 1; $i < scalar @$_; $i++ ) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);

		my $pred = $self->{factory}->createResource($_->[0]);
		my $obj;
		if ($_->[$i] =~ /^".*"$/) {
		    $self->_do_error(501, $_->[$i]);
		} else {
		    $obj = $self->{factory}->createResource($_->[$i]);
		}
		my $stat = $self->{factory}->createStatement($sub,$pred,$obj);
		$self->{model}->add($stat);
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


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::RDFStore - creates a RDFStore model from an N3 file

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3, RDFStore.

=cut
