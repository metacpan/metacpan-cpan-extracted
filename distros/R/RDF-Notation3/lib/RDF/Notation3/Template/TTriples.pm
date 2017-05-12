use strict;
#use warnings;

package RDF::Notation3::Template::TTriples;

require 5.005_62;
use RDF::Notation3;

############################################################

@RDF::Notation3::Template::TTriples::ISA = qw(RDF::Notation3);

sub parse_file {
    my ($self, $path) = @_;
    $self->_do_error(1, '') unless @_ > 1;

    $self->{triples} = [];

    $self->SUPER::parse_file($path);
    return scalar @{$self->{triples}};
}


sub parse_string {
    my ($self, $str) = @_;
    $self->_do_error(3, '') unless @_ > 1;

    $self->{triples} = [];

    $self->SUPER::parse_string($str);
    return scalar @{$self->{triples}};
}


sub get_triples {
    my ($self, $subj, $verb, $obj, $context) = @_;
    my @triples = ();

    foreach (@{$self->{triples}}) {
	if (not $subj or ($subj eq $_->[0])) {
	    if (not $verb or ($verb eq $_->[1])) {
		if (not $obj or ($obj eq $_->[2])) {
		    if (not $context or ($context eq $_->[3])) {
			push @triples, $_;
		    }
		}
	    }
	}
    }
    return \@triples;
}


sub get_triples_as_string {
    my ($self, $subj, $verb, $obj, $context) = @_;
    my $triples = '';

    foreach (@{$self->{triples}}) {
	if (not $subj or ($subj eq $_->[0])) {
	    if (not $verb or ($verb eq $_->[1])) {
		if (not $obj or ($obj eq $_->[2])) {
		    if (not $context or ($context eq $_->[3])) {
			$triples .= "$_->[0] $_->[1] $_->[2]\n";
		    }
		}
	    }
	}
    }
    return $triples;
}


sub get_n3 {
    my ($self) = @_;
    my $n3 = '';

    # for each context
    foreach my $c (keys %{$self->{ns}}) {
	# namespaces
	foreach (keys %{$self->{ns}->{$c}}) {
	    $n3 .= "\@prefix $_: <$self->{ns}->{$c}->{$_}> .\n";
	}
	# statements
	my $tri_tree = {};
	my @tri_seq = ();
	# building tree
	foreach my $t (@{$self->{triples}}) {
	    if ($t->[3] eq $c) {

		push @{$tri_tree->{$t->[0]}->{$t->[1]}}, $t->[2];
		push @tri_seq, $t->[0] unless grep ($_ eq $t->[0], @tri_seq);
	    }
	}
	# serializing tree
	foreach my $s (@tri_seq) {
	    $n3 .= "$s\n";
	    my @pred = keys %{$tri_tree->{$s}};
	    for (my $i=0; $i < @pred; $i++) {
		$n3 .= ' ' x 8;
		$n3 .= "$pred[$i] ";
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
    }
    return $n3;
}


sub add_prefix {
    my ($self, $pref, $uri) = @_;

    if ($pref !~ /^[_a-zA-Z]\w*/) {
	$self->_do_error(102, $pref);
    } elsif ($uri !~ /^(?:[_a-zA-Z]\w*)?:[a-zA-Z]\w*$|^[^\{\}<>]*$/) {
	$self->_do_error(103, $uri);
    } else {
	$self->{ns}->{'<>'}->{$pref} = $uri;
    }
    return scalar keys %{$self->{ns}->{'<>'}};
}


sub _check_resource {
    my ($self, $s, $rs, $type) = @_;

    if ($rs =~ /^<[^\{\}<>]*>$/) {
	# URI

    } elsif ($rs =~ /^(?:[_a-zA-Z]\w*)?:[a-zA-Z]\w*$/) {
	# QName
	my $bound = 0;
	foreach (keys %{$self->{ns}->{'<>'}}) {
	    $rs =~ /^$_:(.*)$/ and $bound = 1 and last;
	}
	$self->_do_error(106, "$rs (subject: $s)") unless $bound;

    } elsif ($rs =~ /^"(?:\\"|[^\"])*"$/) {
	# string1
	$self->_do_error(202, "$rs (subject: $s)") unless $type eq 'l';

    } elsif ($rs =~ /^"""(.*)"""$/) {
	# string2
	$self->_do_error(202, "$rs (subject: $s)") unless $type eq 'l';

    } else {
	$self->_do_error(201, "$rs (subject: $s)");
    }
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Template::TTriples - a triple generator template

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
