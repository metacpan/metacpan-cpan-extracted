package Telephone::Lookup::Americom;
our $VERSION = 0.01;

use strict;

use LWP::Simple;


sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = {};
	bless $self, $class;
	return $self;
}

sub lookup {
	my ($self, $query) = @_;
	my $url = "http://decoder.americom.com/decoderscript?Search=$query&handle=101";

	## Using LWP::Simple to get the html content
	my $content = get($url);

	## Format the content, naively, making it easier to parse
	$content =~ s/[\r\n]+//g;       ## get rid of newlines
	{
	    local $/;                   ## clear default newline separator
	    $content =~ s/<[^>]*>//gs;  ## strip html comments.  not a very good method, but works for us
	}

	my (@results);

	## AREA_CODE Record match
	if ($content =~ /Found Area Code Match(.?\d+-\d{3}) .{10}(.*?)Created on (.*?\d{4}).*?((Area)|( Country)|( Found))/) {
		my $record = { _type => 'AREA_CODE',
				area_code => $1,
				location => $2,
				created_on => $3
				};
		push(@results, $record);
	}

	## EXCHANGE_CODE Record match
	if ($content =~ /Exchange Location:..(.*?)Exchange Type:..(.*?)Owner:..(.*?)Created On:..(.*?\d{4})/) {
		my $record = { _type => 'EXCHANGE_CODE',
				exchange_location => $1,
				exchange_type => $2,
				exchange_owner => $3,
				created_on => $4
				};
		push(@results, $record);
	}
	
	return @results;
}

1;
__END__

=head1 NAME

Telephone::Lookup::Americom - Lookup area, exchange, service provider, etc. information from Americom.

=head1 SYNOPSIS

  use Telephone::Lookup::Americom;
  my $am = Telephone::Lookup::Americom->new();
  my @res = $am->lookup('212-555-1212');

=head1 DESCRIPTION

This module uses Americom Area Decoder (http://decoder.americom.com/) to lookup information about a phone number.  It parses the return form and returns a list of hash refs, one for each record found.

  my @res = $am->lookup('212');           ## lookup only area code
  my @res = $am->lookup('212-555');       ## area code and exchange
  my @res = $am->lookup('212-555-1212');  ## or full phone number

  ## The form also seems to accpept numbers of the form '2125551212' and '(212) 555-1212'. 

  ## The module can return two datatypes:
  for my $record (@res) {
	if ($record->{_type} eq 'AREA_CODE'} {
		# The fields are:
                # $record->{'area_code', 'location', 'created_on'}
	}
	elsif ($record->{_type} eq 'EXCHANGE_CODE') {
		# The fields are: exchange_location, exchange_type, exchange_owner, created_on
	}
  }

=head2 EXPORT

None by default.



=head1 SEE ALSO

