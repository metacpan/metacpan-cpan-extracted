package Module::Changes::ADAMK::Release;

use 5.006;
use strict;
use warnings;
use Carp                        ();
use Params::Util                '_INSTANCE';
use DateTime                    ();
use DateTime::Format::CLDR      ();
use DateTime::Format::DateParse (); 

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

use Module::Changes::ADAMK::Change ();

use Object::Tiny qw{
	string
	version
	date
	datetime
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { string => shift }, $class;

	# Get the paragraph strings
	my @lines  = split /\n/, $self->{string};

	# Find the header substrings
	my $header = shift @lines;
	unless ( $header =~ /^([\d_\.]+)(?:\s+(.+?\d{4}))?/ ) {
		Carp::croak("Failed to find version for release in '$header'");
	}
	$self->{version} = $1;
	$self->{date}    = $2;

	# Inflate the DateTime
	if ( $self->{date} ) {
		$self->{datetime} = DateTime::Format::DateParse->parse_datetime($self->{date});
		if ( $self->{datetime} ) {
			$self->{datetime}->truncate( to => 'day' );
			$self->{datetime}->set_time_zone('floating');
			$self->{datetime}->set_locale('C');
		}
	}

	# Split up the changes
	my @current = ();
	my @changes = ();
	while ( @lines ) {
		my $line = shift @lines;
		if ( $line =~ /^\s*-/ and @current ) {
			push @changes, [ @current ];
			@current = ();
		}
		push @current, $line;
	}
	push @changes, [ @current ] if @current;

	# Convert to change objects
	$self->{changes} = [ ];
	foreach my $change ( @changes ) {
		my $string = join "\n", @$change;
		my $object = Module::Changes::ADAMK::Change->new($string);
		push @{$self->{changes}}, $object;
	}

	return $self;
}

sub changes {
	@{$_[0]->{changes}};
}





#####################################################################
# Modification Functions

sub set_datetime_now {
	my $dt = DateTime->now;
	$_[0]->set_datetime( $dt );
}

sub set_datetime {
	my $self = shift;
	my $dt   = shift;
	unless ( _INSTANCE($dt, 'DateTime') ) {
		Carp::croak('Did not pass a valid DateTime to set_datetime');
	}

	# Overwrite the datetime
	$self->{datetime} = $dt;

	# Overwrite the string form
	$self->{date} = $dt->strftime('%a %e %b %Y');

	return 1;
}





#####################################################################
# Stringification

sub as_string {
	my $self  = shift;
	my @lines = (
		$self->version . ' ' . $self->date,
		map { $_->as_string } $self->changes,
	);
	return join "\n", @lines;
}

sub roundtrips {
	$_[0]->string eq $_[0]->as_string
}

1;
