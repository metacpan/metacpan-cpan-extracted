package Project::Easy::Config::Format::json;

use Class::Easy;

use JSON;

sub new {
	my $class = shift;
	
	my $json = JSON->new;
	$json->utf8 (1);
	$json->pretty (1);
	$json->convert_blessed (1);
	
	bless {worker => $json}, $class;
}

sub parse_string {
	my $self   = shift;
	my $string = shift;

	return $self->{worker}->decode ($string);
}

sub dump_struct {
	my $self  = shift;
	my $string = shift;

	return $self->{worker}->encode ($string);
}


1;
