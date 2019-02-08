package MySQL::ORM::Generate::Writer;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use File::Path 'make_path';
use File::Basename;
use Text::Trim 'trim';
use Perl::Tidy::Sweetened;

extends 'MySQL::ORM::Generate::Common';

##############################################################################
## required attributes
##############################################################################



##############################################################################
## optional attributes
##############################################################################


##############################################################################
## private attributes
##############################################################################



##############################################################################
## methods
##############################################################################

method write_class (
	Str      :$file_name!,
	Str      :$class_name!,
	ArrayRef :$use,
	ArrayRef :$with,
	ArrayRef :$extends,
	ArrayRef :$attribs,
	ArrayRef :$methods,
  ) {

	$self->trace;
	say "writing $file_name";

	make_path dirname($file_name);

	open my $fh, '>', $file_name
	  or confess "failed to open $file_name for writing: $!";

	$self->_write( fh => $fh, text => "package $class_name;" );
	$self->_write( fh => $fh );
	
	foreach my $mod (@$use) {
		$self->_write( fh => $fh, text => "use $mod;" );
	}

	$self->_write( fh => $fh );
	
	if ( $extends and @$extends > 0 ) {

		my @tmp;
		foreach my $ext (@$extends) {
			push @tmp, "'$ext'";
		}

		my $text = "extends ";
		$text .= join( ", ", @tmp );
		$text .= ';';

		$self->_write( fh => $fh, text => $text );
		$self->_write( fh => $fh );
	}

	if ( $with and @$with ) {

		my @tmp;
		foreach my $with (@$with) {
			push @tmp, "'$with'";
		}

		my $text = "with ";
		$text .= join( ", ", @tmp );
		$text .= ';';

		$self->_write( fh => $fh, text => $text );
		$self->_write( fh => $fh );
	}

	#
	# attribs
	#
	my @public;
	my @private;
	foreach my $attr (@$attribs) {
		$attr = trim $attr;
		if ( $attr =~ /^has\s+_/ ) {
			push @private, $attr;
		}
		else {
			push @public, $attr;
		}
	}
	
	@public = sort @public;
	$self->_write( fh => $fh, text => join( "\n\n", @public ) );
	$self->_write( fh => $fh );

	@private = sort @private;
	$self->_write( fh => $fh, text => join( "\n\n", @private ) );
	$self->_write( fh => $fh );

	#
	# methods
	#

	@public  = ();
	@private = ();
	foreach my $method (@$methods) {
		$method = trim $method;
		if ( $method =~ /^method\s+_/ or $method =~ /^sub\s+_/ ) {
			push @private, $method;
		}
		else {
			push @public, $method;
		}
	}

	@public = sort @public;
	$self->_write( fh => $fh, text => join( "\n\n", @public ) );
	$self->_write( fh => $fh );

	@private = sort @private;
	$self->_write( fh => $fh, text => join( "\n\n", @private ) );
	$self->_write( fh => $fh );
	$self->_write( fh => $fh, text => '1;' );
	close($fh);
	
	$self->_tidy($file_name);	
	$self->trace('exit');
}

##############################################################################
## private methods
##############################################################################

method _tidy (Str $file_name) {

	system("perltidier -b -bext='/' $file_name");
	return;
		
	local @ARGV = ('-b', "-bext='/'", $file_name);
	
	Perl::Tidy::Sweetened::perltidy();
}

#method _tidy (Str $file_name) {
#
#	my $cmd = "perltidier -b -bext='/' $file_name";
#	system($cmd);
#	die if $?;
#}

method _write ( Ref :$fh, Str :$text ) {

	print $fh $text if $text;
	print $fh "\n";
}


1;