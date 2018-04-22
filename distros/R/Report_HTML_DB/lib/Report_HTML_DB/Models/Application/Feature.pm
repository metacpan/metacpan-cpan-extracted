package Report_HTML_DB::Models::Application::Feature;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This class will be used like a model responsible of result of features

=cut

has feature_id 	=> 	(is => 'ro', isa => 'Str');
has name		=>	(is => 'ro', isa =>	'Str');
has uniquename 	=> 	(is => 'ro', isa => 'Str');
has type		=> 	(is => 'ro', isa => 'Str');
has fstart		=>	(is => 'ro', isa => 'Int');
has fend		=>	(is => 'ro', isa => 'Int');
has predictor	=> (is => 'ro', isa => 'Str');

sub setFeatureID {
	my ($self, $feature_id) = @_;
	$self->{feature_id} = $feature_id;
	return $self->{feature_id};
}

sub getFeatureID {
	my ($self) = @_;
	return $self->{feature_id};
}

sub setName {
	my ($self, $name) = @_;
	$self->{name} = $name;
	return $self->{name};
}

sub getName {
	my ($self) = @_;
	return $self->{name};
}

sub setUniquename {
	my ($self, $uniquename) = @_;
	$self->{uniquename} = $uniquename;
	return $self->{uniquename};
}

sub getUniquename {
	my ($self) = @_;
	return $self->{uniquename};
}

sub setValue {
	my ($self, $value) = @_;
	$self->{type} = $value;
	return $self->{type};
}

sub getValue {
	my ($self) = @_;
	return $self->{type};
}

sub setStart {
	my ($self, $fstart) = @_;
	$self->{fstart} = $fstart;
	return $self->{fstart};
}

sub getStart {
	my($self) = @_;
	return $self->{fstart};
}

sub setEnd {
	my ($self, $fend) = @_;
	$self->{fend} = $fend;
	return $self->{fend};
}

sub getEnd {
	my ($self) = @_;
	return $self->{fend};
}

sub setPredictor {
        my ($self, $predictor) = @_;
        $self->{predictor} = $predictor;
        return $self->{predictor};
}

sub getPredictor {
        my ($self) = @_;
        return $self->{predictor};
}

1;
