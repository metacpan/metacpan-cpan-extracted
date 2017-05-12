use strict;
#use warnings;

package RDF::Notation3::Template::TXML;

require 5.005_62;
use RDF::Notation3;

############################################################

@RDF::Notation3::Template::TXML::ISA = qw(RDF::Notation3);


sub _process_statement {
    my ($self, $subject, $properties) = @_;

    $subject = $self->_expand_prefix($subject);
    $subject =~ s/^<(.*)>$/$1/;

    my $prev;
    my $j = 0;
    foreach (@$properties) {

	if ($_->[0] ne 'i') {

	    if ($j == 0 or $prev eq 'i') {
		my @attr = ();

		# nodeID is used for blank nodes
		if ($subject =~ /^$self->{ansuri}(.*)$/) {
		    push @attr, ['rdf:nodeID' => "$self->{nIDpref}$1"];
		} else {
		    push @attr, ['rdf:about' => $subject];		    
		}

		$self->doStartElement('rdf:Description', \@attr);
	    }

	    my ($attr, $pred) = $self->_process_predicate($_->[0]);
	    $pred =~ s/^:(.*)$/$1/;
	
	    for (my $i = 1; $i < scalar @$_; $i++) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);
   
		my @attr = @$attr;
		my $val = '';

		# URI
		if ($_->[$i] =~ s/^<(.*)>$/$1/) {
		    # nodeID is used for blank nodes
		    if ($_->[$i] =~ /^$self->{ansuri}(.*)$/) {
			push @attr, ['rdf:nodeID' => "$self->{nIDpref}$1"];
		    } else {
			push @attr, ['rdf:resource' => $_->[$i]];
		    }

		# string2
		} elsif ($_->[$i] =~ s/^"""(.*)"""$/$1/s) {
		  $val = $_->[$i];
		  
		# string1
		} elsif ($_->[$i] =~ s/^"(.*)"$/$1/) {
		    $val = $_->[$i];

		} else {
		    $self->_do_error(402, $_->[$i]);		    
		}

# 		# URI
# 		$_->[$i] =~ s/^<(.*)>$/$1/ and
# 		  push @attr, ['rdf:resource' => $_->[$i]];
# 		# string2
# 		$_->[$i] =~ s/^"""(.*)"""$/$1/s and
# 		  $val = $_->[$i];
# 		# string1
# 		$_->[$i] =~ s/^"(.*)"$/$1/ and
# 		  $val = $_->[$i];

		# escaping literals
		$val =~ s/</&lt;/g;
		$val =~ s/>/&gt;/g;
		$val =~ s/&/&amp;/g;

		$self->doElement($pred, \@attr, $val);
		$self->{count}++;
	    }

	    if ($j == scalar @$properties - 1 or 
		($properties->[$j+1]->[0] eq 'i')) {
		$self->doEndElement('rdf:Description');
	    }

	} else {
	    # inverse mode (is, <-)
	    for (my $i=2; $i < scalar @$_; $i++) {
		$_->[$i] = $self->_expand_prefix($_->[$i]);
		$_->[$i] =~ s/^<(.*)>$/$1/;

		my @attr = ();
		push @attr, [about => $_->[$i]];
		$self->doStartElement('rdf:Description', \@attr);

		my ($attr, $pred) = $self->_process_predicate($_->[1]);
		my @attr2 = @$attr;
		$pred =~ s/^:(.*)$/$1/;
		push @attr2, ['rdf:resource' => $subject];

		$self->doElement($pred, \@attr2, '');
		$self->{count}++;

		$self->doEndElement('rdf:Description');
	    }
	} 
	$prev = $_->[0];
	$j++;
    }
}


sub _expand_prefix {
    my ($self, $qname) = @_;

    foreach (keys %{$self->{ns}->{$self->{context}}}) {
	$qname =~ s/^$_:(.*)$/<$self->{ns}->{$self->{context}}->{$_}$1>/;
    }

    if ($qname =~ /^([_a-zA-Z]\w*)*:[a-zA-Z]\w*$/) {
	$self->_do_error(106, $qname);
    }

    return $qname;
}


sub _process_predicate {
    my ($self, $name) = @_;
    my @attr = ();

    my $p = '';
    my $pushed = 0;
    if ($name =~ /^([_a-zA-Z]\w*)*:[a-zA-Z]\w*$/) {
 	$p = $1;

    } else { # not a QName - must be turned to QName
	my $qnamed = 0;

	# checking if the NS already exists
	foreach (keys %{$self->{ns}->{$self->{context}}}) {
	    my $ns = _escape_ns($self->{ns}->{$self->{context}}->{$_});
	    if ($name =~ s/^<$ns([a-zA-Z]\w*)>$/$_:$1/) {
		$qnamed = 1;
		$p = $_;
		last; 
	    }
	}
	# checking out hard-coded NS
	unless ($qnamed) {
	    foreach (keys %{$self->{hardns}}) {
		my $ns = _escape_ns($self->{hardns}->{$_}->[1]);
		if ($name =~ s/^<$ns([a-zA-Z]\w*)>$/$self->{hardns}->{$_}->[0]:$1/) {
		    $p = $self->{hardns}->{$_}->[0];
		    $self->{ns}->{$self->{context}}->{$p} = 
		      $self->{hardns}->{$_}->[1];
		    $qnamed = 1;
		    $p = $self->{hardns}->{$_}->[0];
		    last; 
		}
	    }
	}
	# inventing new NS
	unless ($qnamed) {
	    my $i = 1;
	    my $pref = 'pref';
	    while ($self->{ns}->{$self->{context}}->{$pref}) {
		$pref = "$pref$i";
		$i++;
	    }
	    if ($name =~ s/^<(.*?)([a-zA-Z]\w*)>$/$pref:$2/) {
		push @attr, ["xmlns:$pref" => $1];
		$qnamed = 1;
		$pushed = 1;
	    }
	}
	$self->_do_error(401, $name) unless $qnamed;
    }

    unless ($pushed) {
	if ($p) {
	    push @attr, ["xmlns:$p" => $self->{ns}->{$self->{context}}->{$p}];
	    $self->_do_error(106, $name) 
	      unless $self->{ns}->{$self->{context}}->{$p};
	} else {
	    push @attr, ["xmlns" => $self->{ns}->{$self->{context}}->{''}];
	    $self->_do_error(106, $name) 
	      unless $self->{ns}->{$self->{context}}->{''};
	}
    }

    return (\@attr, $name);
}


sub _escape_ns {
    my $ns = shift;

    $ns =~ s/\+/\\+/;
    $ns =~ s/\*/\\*/;
    $ns =~ s/\?/\\?/;

    return $ns;
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Template::TXML - an RDF/XML converter template

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
