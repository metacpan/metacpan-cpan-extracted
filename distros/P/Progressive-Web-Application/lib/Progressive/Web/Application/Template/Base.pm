package Progressive::Web::Application::Template::Base;
use strict;
use JSON qw//;
our $JSON;
BEGIN { $JSON = JSON->new->utf8->pretty(1)->allow_nonref->allow_blessed; }

sub new {
	my $self = bless {}, $_[0];
	$self->{handle} = $_[0] . '::DATA';
	$self->{handle_start} = tell $self->{handle};
	$self->{data} = $self->get_data_section();
	return $self;
}

sub get_data_section {
	my $fh = $_[0]->{handle};
	my $content = do { local $/; <$fh> } or return;
	seek $_[0]->{handle}, $_[0]->{handle_start}, 0; # reset for next 'call' to get_data_section
	$content =~ s/^.*\n__DATA__//s;
	$content =~ s/\n__END__\n.*$/\n/s;
	my @data = split /^@@\s+(.+?)\s*\r?\n/m, $content;
	shift @data;
	return {@data};
}

sub render {
	my $templates = $_[0]->{data};
	if ($_[0]->can('required_params')) {
		exists $_[1]->{$_} or Carp::croak(sprintf 'Required template param not found %s', $_)
			for $_[0]->required_params();
	}
	my $dataReg = join '|', map { quotemeta($_) } keys %{$_[1]};
	for my $key (keys %{$templates}) {
		$templates->{$key} =~ s/\{($dataReg)\}/encode_json($_[1]->{$1})/eg;
		$templates->{$key} =~ s/\s*$//;
	}
	return $templates;
}

sub encode_json {
	my $val = $JSON->encode($_[0]);
	chomp($val);
	return $val;
}

1;

