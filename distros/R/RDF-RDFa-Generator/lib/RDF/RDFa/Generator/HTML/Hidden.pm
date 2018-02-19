package RDF::RDFa::Generator::HTML::Hidden;

use 5.008;
use base qw'RDF::RDFa::Generator::HTML::Head';
use strict;
use XML::LibXML qw':all';

use warnings;


our $VERSION = '0.200';

sub injection_site
{
	return '//xhtml:body';
}

sub nodes
{
	my ($proto, $model) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;
	
	my $stream = $self->_get_stream($model);
	my @nodes;
	
	my $rootnode = XML::LibXML::Element->new('i');
	$rootnode->setNamespace('http://www.w3.org/1999/xhtml', undef, 1);
	$rootnode->setAttribute('style','display:none');
	
	my $subjects = {};
	while (my $st = $stream->next)
	{
		my $s = $st->subject->is_resource ?
			$st->subject->abs :
			('_:'.$st->subject->value);
		push @{ $subjects->{$s} }, $st;
	}
	
	foreach my $s (keys %$subjects)
	{
		my $node = $rootnode->addNewChild('http://www.w3.org/1999/xhtml', 'i');
		
		$self->_process_subject($subjects->{$s}->[0], $node);
		
		foreach my $st (@{ $subjects->{$s} })
		{
			my $node2 = $node->addNewChild('http://www.w3.org/1999/xhtml', 'i');
			$self->_process_predicate($st, $node2)
			     ->_process_object($st, $node2);
		}
	}
	
	if (defined($self->{'version'}) && $self->{'version'} == 1.1
		 and $self->{'prefix_attr'}) {
	  if (defined($self->{namespacemap}->rdfa)) {
		 $rootnode->setAttribute('prefix', $self->{namespacemap}->rdfa->as_string);
	  }
	} else {
	  while (my ($prefix, $nsURI) = $self->{namespacemap}->each_map) {
		 $rootnode->setNamespace($nsURI->as_string, $prefix, 0);
	  }
	}
	
	push @nodes, $rootnode;
	
	return @nodes if wantarray;
	
	my $nodelist = XML::LibXML::NodeList->new;
	$nodelist->push(@nodes);
	return $nodelist;
}

sub _process_subject
{
	my ($self, $st, $node) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->abs eq $self->{'base'})
		{ $node->setAttribute('about', ''); }
	elsif ($st->subject->is_resource) 
		{ $node->setAttribute('about', $st->subject->abs); }
	else
		{ $node->setAttribute('about', '[_:'.$st->subject->value.']'); }
	
	return $self;
}

1;
