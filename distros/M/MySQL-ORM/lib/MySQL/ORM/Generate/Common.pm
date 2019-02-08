package MySQL::ORM::Generate::Common;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite;
use MySQL::Util::Lite::Column;
use IO::Handle;

##############################################################################
# required attributes
##############################################################################


##############################################################################
# optional attributes
##############################################################################

##############################################################################
# private attributes
##############################################################################

has _writer => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::Writer',
	lazy    => 1,
	builder => '_build_writer',
);

has _attribute_maker => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::AttributeMaker',
	lazy    => 1,
	builder => '_build_attribute_maker',
);

has _method_maker => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::MethodMaker',
	lazy    => 1,
	builder => '_build_method_maker',
);

##############################################################################
# methods
##############################################################################

method camelize ( Str $str ) {

	my @a = split( /_+/, $str );
	my @b = map { ucfirst $_ } @a;

	return join '', @b;
}

method writer {
	return $self->_writer;
}

method attribute_maker {
	return $self->_attribute_maker;
}

method method_maker {
	return $self->_method_maker;
}

method get_column_attribute_comments (MySQL::Util::Lite::Column $col) {

	my $default = $col->default || '';

	my @comments;
	push @comments, sprintf( 'type:    %s', $col->type );
	push @comments, sprintf( 'key:     %s', $col->key );
	push @comments, sprintf( 'autoinc: %s', $col->is_autoinc ? 'yes' : 'no' );
	push @comments, sprintf( 'null:    %s', $col->is_null ? 'yes' : 'no' );
	push @comments, sprintf( 'default: %s', $default );

	return \@comments;
}

method get_column_trigger (MySQL::Util::Lite::Column $col) {

	my $trig = "sub { \n";
	$trig .= "    my \$self = shift;\n";
	$trig .= sprintf( '    $self->_touched->{%s}++;', $col->name ) . "\n";
	$trig .= "}";

	return $trig;
}

method verbose (Str $str) {

	if ( $ENV{VERBOSE} ) {
		print STDERR "[VERBOSE] $str\n";
		STDERR->flush();
	}
}

method trace(Str $str = '') {

	my $caller = (caller(1))[3];	
	
	if ($ENV{TRACE}) {
		print STDERR "[TRACE] [$caller] $str\n";
		STDERR->flush();		
	}	
}

##############################################################################
# private methods
##############################################################################

method _build_writer {

	return MySQL::ORM::Generate::Writer->new;
}

method _build_attribute_maker {

	return MySQL::ORM::Generate::AttributeMaker->new;
}

method _build_method_maker {

	return MySQL::ORM::Generate::MethodMaker->new;
}

1;
