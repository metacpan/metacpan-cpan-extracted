=pod

=head1 NAME

Properties - Module for option file parsing

=head1 VERSION

1.4

=head1 SYNOPSIS

		use Properties;
		
		my $options = Properties->new('/etc/some_optionsfile');
		if($options->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}
		
		my $configHash = $options->getCompleteConfig();
		if($options->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}
		
		my $property = $options->getProperty("socket.remote.hostname");
		if($options->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}
		
=head1 DESCRIPTION

Properties give you the ability to define program properties in an external file and parse them as needed. You can fetch the complete config in a well formed hash structure or fetch single properties. This class also need the Merror Module to indicate error states. Every method will set his internal Merror state to an error if something strange happend.
You have to catch these error yourself via defined methods.

=head1 METHODS

=over 4

=item B<new(propertyFile)>

Constructor.

		Example:
		my $obj = Properties->new("/etc/myClient/socket.properties");
		if(obj->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}
		
=item B<getCompleteConfig>

Returns the attribute value pairs defined in the properties file as an well formed anonymous hash.
See HASHSTRUCTURE for detailed information about the retunred structure.

		Example:
		my $c_hash = $obj->getCompleteConfig();
		if($obj->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}

=item B<getProperty(propertyName)>

Searches propertyName in configured property file and returns the value of that property

		Example:
		$obj->getProperty("socket.remote.hostname");
		if($obj->error()) {
				print("Errorcode: " . $options->get_errorCode() ."\n");
				print("Error description: " . $options->get_errorDescription() ."\n");
				$options->printStacktrace();
				exit(0);
		}
		
=item B<error>

Wraps the error function of Merror class to hide the internal represantation of Merror. If this method returns 1 an error happend.

=item B<get_errorDescription>

Returns the error description.

=item B<get_errorCode>

Returns the errorcode.

=item B<printStacktrace>

Prints out the stacktrace.

=item B<get_stacktrace>

Returns the stacktrace as an array where every element is one level of the stacktrace.

=back

=head1 PROPERTYFILE

Lines starting with a # are ignored.
The syntax of an key-value propertie pair is:

		a.b.c.d = foo

Here you have a propertie named C<a.b.c.d>with an value of C<foo>.
Properties are seen in groups. This mean that if you define another property:

		a.b.c.e = bar
		
the level of C<d> and C<e> are the direct sublevel of C<c> when calling getCompleteConfig.

Example of an property file:

		socket.local.port = 3333
		socket.local.hostname = localhost
		socket.local.maxconnections = 10
		socket.remote.port = 3334
		socket.remote.hostname = remotehost

=head1 HASHSTRUCTURE

When calling C<getCompleteConfig> the resulting hashstructure depends on the levels of different attributes.
Every subitem of the anonymous hash stands for an subitem ob the attribute.
Lets have a look at an example. Think about we are having a property file like the one described in section PROPERTYFILE.
If we call method C<getCompleteConfig> the resulting hash will look like this:

		$returned_hash =>
				{socket} =>
						{local} =>
								{port} = 3333
								{hostname} = localhost
								{maxconnections} = 10
						{remote} =>
								{port} = 3334
								{hostname} = remotehost
								
So, if you want to use the value of the local port you must access it via:

		$$returned_hash{socket}{local}{port}

=head1 BUGS
		
Option value missparsing: If an option value contains a dot the value was also parsed as an parameter structure. Fixed in version 1.3. Thanks to <florent.lartet@univ-tlse2.fr>
		
=head1 ACKNOWLEDGEMENTS

If you find any bugs or got some feature you wish to have implemented please register at C<mantis.markus-mazurczak.de>.

=head1 COPYRIGHT

See README.

=head1 AVAILABILITY

You can allways get the latest version from CPAN.

=head1 AUTHOR

Markus Mazurczak <coding@markus-mazurczak.de>

=cut
package Properties;

use strict;
use warnings;

use Merror;

our $VERSION = '1.4';

sub new {
	my $invocant = shift;
	my $optfile = shift || undef;

	my $class = ref($invocant) || $invocant;
	my $self = {};

	$self->{MERROR} = Merror->new();
	$self->{OPTFILE} = $optfile;
	bless $self, $class;

	$self->checkOptfile();
	return($self);
}

sub getCompleteConfig {
	my $self = shift;
	my $tryOpen = open(CFG, $self->{OPTFILE});
	if(!$tryOpen) {
		$self->{MERROR}->error(1);
		$self->{MERROR}->ec(-1);
		$self->{MERROR}->et("Could not open option file for reading: $!");
		return({});
	}
	
	my $cfgHash = {};
	while(my $line = <CFG>) {
		next if($line =~ /^\s{0,}$/ || $line =~ /^(\s{0,}#)/);
		chomp($line);
		&splitCfgLine($line, \$cfgHash);
	}

	close(CFG);
	return($cfgHash);
}


sub getProperty {
	my ($self, $property) = @_;

	if(!defined($property)) { 
		$self->{MERROR}->error(1);
		$self->{MERROR}->ec(-2);
		$self->{MERROR}->et("Syntax error while calling getProperty. You have to define a property");
		return("");
	}
	my $tryOpen = open(CFG, $self->{OPTFILE});
	if(!$tryOpen) {
		$self->{MERROR}->error(1);
		$self->{MERROR}->ec(-1);
		$self->{MERROR}->et("Could not open option file for reading: $!");
		return("");
	}
	while(my $line = <CFG>) {
		next if($line !~ /^(\s{0}$property.*?=.*)/ || $line =~ /^\s{0,}$/ || $line =~ /^(\s{0,}#)/);
		chomp($line);
		my ($value) = ($line =~ /.*?=(.*)/);
		close(CFG);
		return(&delWhitespaces($value));
	}
	close(CFG);
	$self->{MERROR}->error(1);
	$self->{MERROR}->ec(-1);
	$self->{MERROR}->et("Option not found: $property");
	return("");
}

sub error {
		my $self = shift;
		return($self->{MERROR}->error());
}

sub get_errorDescription {
		my $self = shift;
		return($self->{MERROR}->et());
}

sub get_errorCode {
		my $self = shift;
		return($self->{MERROR}->ec());
}

sub printStacktrace {
		my $self = shift;
		$self->{MERROR}->stacktrace();
}

sub get_stacktrace {
		my $self = shift;
		return($self->{MERROR}->return_stacktrace());
}

# private method
# Splits a configuration line refrenced by line into a hierarchic anonHash hashRef
sub splitCfgLine {
	my ($line, $hashRef) = @_;

	if($line =~ /\..+=/) {
		my @parts = split(/\./, $line);
		$parts[0] = &delWhitespaces($parts[0]);
		my $newLine;
		for(my $i=1; $i < $#parts + 1; $i++) { $newLine .= ".$parts[$i]"; }
		$newLine =~ s/^\.//;
		&splitCfgLine($newLine, \$${$hashRef}{$parts[0]});
	} else {
		my ($attr, $value) = ($line =~ /(.*?)=(.*)/);
		$attr = &delWhitespaces($attr);
		$value = &delWhitespaces($value);
		$${$hashRef}{$attr} = $value; 
	}
	return;
}

# private method
# Deletes all leading and trainling whitespaces from what
sub delWhitespaces {
	my $string = shift;
	$string =~ s/^\s{1,}//;
	$string =~ s/\s{1,}$//;
	return($string);
}

# private method
# Checks if a optionfile is given and if it is readable
sub checkOptfile {
	my $self = shift;
	if(!defined($self->{OPTFILE})) {
		$self->{MERROR}->error(1);
		$self->{MERROR}->ec(-1);
		$self->{MERROR}->et("No option file defined");
		return;
	}
	if(!-r $self->{OPTFILE}) {
		$self->{MERROR}->error(1);
		$self->{MERROR}->ec(-1);
		$self->{MERROR}->et("Could not read option file: " . $self->{OPTFILE});
		return;
	}
	return;
}

1;
