package SVG::DOM2::Element::MetaData;

use base "XML::DOM2::Element";
use strict;

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new('metadata', %args);
}

sub data
{
	my ($self) = @_;
	warn "Trying to get DATA: $self\n";
	if(not $self->{'data'}) {
		# Generate with RDF:
		my $result = {};
		my ($rdf) = $self->getChildrenByName('rdf:RDF');
		if($rdf) {
			my ($work) = $rdf->getChildrenByName('cc:Work');
			$result = $self->_format_rdf_hash($work);
			$self->{'rdf'} = 1;
		}
		$self->{'data'} = $result;
	}
	
	return $self->{'data'};
}

sub _format_rdf
{
	my ($self, $child) = @_;
	# Resource
	my $rdfns = $self->document->getNamespace('rdf');
	my $resource = $child->getAttributeNS($rdfns, 'resource');
	return $resource->value if defined $resource;
	# Value
	return $child->cdata->text if $child->hasCDATA;
	# Structure
	my $result;
	my ($achild) = $child->getChildren;
	return '' if not $achild;
	if($achild->localName =~ /Bag|Alt|Seq/) {
		# Array
		$result = [ map { $self->_format_rdf($_) } $achild->getChildrenByName('rdf:li') ];
	} elsif($achild->localName eq 'Agent') {
		# Hash
		$result = $self->_format_rdf_hash($achild);
	}
	return $result;
}

sub _format_rdf_hash
{
	my ($self, $child) = @_;
	my $result = {};
	foreach my $achild ($child->getChildren) {
		my $name = $achild->localName;
		$result->{$name} = $self->_format_rdf($achild);
	}
	return $result;
}

sub list
{
	my ($self) = @_;
	return $self->list_hash($self->data);
}

sub list_data
{
	my ($self, $data) = @_;
	return '"'.$data.'"' if not ref($data);
	if(UNIVERSAL::isa($data, 'HASH')) {
		return $self->list_hash($data);
	} elsif(UNIVERSAL::isa($data, 'ARRAY')) {
		return $self->list_array($data);
	}
}

sub list_array
{
	my ($self, $array) = @_;
	return '['.join(', ',map { $self->list_data($_) } @{$array}).']';
}

sub list_hash
{
	my ($self, $hash) = @_;
	return '{'.join(', ', map { $_.' = '.$self->list_data($hash->{$_}) } keys(%{$hash}) ).'}';
}

=head2 MetaData Fields

  title       - Image title
  description - Image discription
  subject     - Array of subjects (contexts)
  publisher   - Company who publishes the work
  creator     - Author, Artist, Designer ect.
  rights      - Owner of the work (rights holder)
  date        - Creation date
  license     - Published License
  language    - Language (if applicable)
	
=cut
sub title       { shift->datum('title', @_) }
sub description { shift->datum('description', @_) }
sub subject     { shift->datum('subject', @_) }
sub publisher   { shift->datum('publisher', @_) }
sub creator     { shift->datum('creator', @_) }
sub rights      { shift->datum('rights', @_) }
sub date        { shift->datum('date', @_) }
sub license     { shift->datum('license', @_) }
sub language    { shift->datum('language', @_) }

sub datum
{
	my ($self, $name, $value) = @_;
	if(defined($value)) {
		$self->data->{$name} = $value;
	} else {
		$value = $self->data->{$name};
	}
	return $value;
}

return 1;
