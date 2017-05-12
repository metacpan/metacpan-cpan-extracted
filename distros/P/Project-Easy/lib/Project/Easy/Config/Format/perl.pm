package Project::Easy::Config::Format::perl;

use Class::Easy;

use Data::Dumper;

{
	no warnings 'redefine';
	sub Data::Dumper::qquote {
		my $s = shift;
		return "'$s'";
	}
}

sub new {
	my $class = shift;
	bless {}, $class;
}

sub parse_string {
	shift;
	my $string = shift;

	# TODO: we only need one parser configuration
	my $struct = eval $string;
	
	die ('error when parsing config: ', $@)
		if $@;
	
	return $struct;
}

sub dump_struct {
	shift;
	my $struct = shift;
	
	{
		local $Data::Dumper::Useqq = 1;
		my $str = Dumper ($struct);
	
		$str =~ s/^\$VAR\d+\s=\s//s;
	
		return $str;
	}
}


1;