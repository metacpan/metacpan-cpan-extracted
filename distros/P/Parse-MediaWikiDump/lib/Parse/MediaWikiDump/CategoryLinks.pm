package Parse::MediaWikiDump::CategoryLinks;

our $VERSION = '1.0.3';

use strict;
use warnings;

sub new {
	my ($class, $source) = @_;
	my $self = {};

	$$self{BUFFER} = [];
	$$self{BYTE} = 0;

	bless($self, $class);

	$self->open($source);
	$self->init;

	return $self;
}

sub next {
	my ($self) = @_;
	my $buffer = $$self{BUFFER};
	my $link;

	while(1) {
		if (defined($link = pop(@$buffer))) {
			last;
		}

		#signals end of input
		return undef unless $self->parse_more;
	}

	return Parse::MediaWikiDump::category_link->new($link);
}

#private functions with OO interface
sub parse_more {
	my ($self) = @_;
	my $source = $$self{SOURCE};
	my $need_data = 1;
	
	while($need_data) {
		my $line = <$source>;

		last unless defined($line);

		$$self{BYTE} += length($line);

		while($line =~ m/\((\d+),'(.*?)','(.*?)',(\d+)\)[;,]/g) {
			push(@{$$self{BUFFER}}, [$1, $2, $3, $4]);
			$need_data = 0;
		}
	}

	#if we still need data and we are here it means we ran out of input
	if ($need_data) {
		return 0;
	}
	
	return 1;
}

sub open {
	my ($self, $source) = @_;

	if (ref($source) ne 'GLOB') {
		die "could not open $source: $!" unless
			open($$self{SOURCE}, $source);

		$$self{SOURCE_FILE} = $source;
	} else {
		$$self{SOURCE} = $source;
	}

	binmode($$self{SOURCE}, ':utf8');

	return 1;
}

sub init {
	my ($self) = @_;
	my $source = $$self{SOURCE};
	my $found = 0;
	
	while(<$source>) {
		if (m/^LOCK TABLES `categorylinks` WRITE;/) {
			$found = 1;
			last;
		}
	}

	die "not a MediaWiki link dump file" unless $found;
}

sub current_byte {
	my ($self) = @_;

	return $$self{BYTE};
}

sub size {
	my ($self) = @_;
	
	return undef unless defined $$self{SOURCE_FILE};

	my @stat = stat($$self{SOURCE_FILE});

	return $stat[7];
}

1;