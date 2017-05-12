package SQL::Template::XMLBuilder;

use strict;
use XML::Parser;
use SQL::Template::Command;



sub new {
	my ($class) = @_;
	return bless {	}, $class;
}


sub parse_file {
	my $self = shift;
	my $filename = shift;
	my $p = XML::Parser->new(Style=>'Stream', Pkg=>'SQL::Template::XMLParser');
	$p->parsefile($filename);
	$self->_compile_commands;
	##$SQL::Template::XMLParser::SQL_COMMAND->dump;
}

sub parse_string {
	my $self = shift;
	my $string = shift;
	my $p = XML::Parser->new(Style=>'Stream', Pkg=>'SQL::Template::XMLParser');
	$p->parse($string);
	$self->_compile_commands;
	##$SQL::Template::XMLParser::SQL_COMMAND->dump;
}

sub _compile_commands {
	my $self = shift;
	my @commands = $SQL::Template::XMLParser::SQL_COMMAND->get_commands;
	foreach my $command(@commands) {
		$self->{COMMANDS}->{lc($command->name)} = $command;
	}
}

sub get_commands {
	my $self = shift;
	return $self->{COMMANDS};
}

sub get_command {
	my $self = shift;
	my $name = shift;
	return $self->{COMMANDS}->{lc($name)};
}

#******************************************************************************
package SQL::Template::XMLParser;

our $SQL_COMMAND = undef;
my $CURRENT_COMMAND;
my $LAST_COMMAND;

sub trim {
	$_[0] =~ s!^\s+!!;
	$_[0] =~ s!\s+$!!;
	return $_[0];
}

sub set_current_command {
	my $command = shift;
	##print "set current command: ", ref($command), "\n";
	$CURRENT_COMMAND = $command;
}

sub set_last_command {
	my $command = shift;
	$LAST_COMMAND = $command;
}

sub StartTag {
	my $parser = shift;
	my $name = trim(shift);
	my $command = SQL::Template::Command::new_from({
			XMLTYPE   => $name,
			PARENT    => $CURRENT_COMMAND, 
			PREVIOUS  => $LAST_COMMAND,
			CONTAINER => $SQL_COMMAND,
			PARAMS    => \%_
	});
	
	if( eval { $command->isa('SQL::Template::Command::Sql')} ) {
		$SQL_COMMAND = $command;
	}
	
	##print "start tag: ", Data::Dump::dump(%_), "\n";
	##print "last command: ", ref($LAST_COMMAND), "\n";
	
	set_current_command $command;
	set_last_command $command;
}

sub EndTag {
	my $parser = shift;
	my $name = shift;
	##print "END TAG: $name\n";
	my $parent = $CURRENT_COMMAND->parent;
	set_current_command $parent;
}

sub Text {
	my $parser = $_[0];
	my $text   = trim($_);
	if( $text ) {
		$CURRENT_COMMAND->add_command( SQL::Template::Command::Text->new({TEXT=>$text}) );
	}
}


1;