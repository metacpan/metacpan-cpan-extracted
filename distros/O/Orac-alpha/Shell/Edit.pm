#
# Shell edit menu support.
#

package Shell::Edit;
use strict;

use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter ();
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT_OK = qw(edit);


sub new {
	my $proto = shift; 
	my $class = ref($proto) || $proto;

	my $self  = {
			editor					=> shift->options->editor,
		};
	bless($self, $class);
}

#
# Edit the current statement in a external editor.
#
sub external_edit {
	my ($self, $buffer) = @_;
	warn qq{Empty buffer...}, return unless $buffer;

	# Determine the current statement:
	my $tmp_file = $self->_save( $buffer );

	my $sys_call = $self->editor . " $tmp_file"; 
	print STDERR qq{System call: $sys_call};
	system( $sys_call );

	my $st = $self->_load( $tmp_file );

	unlink( $tmp_file );

	$st;
}

sub _load {
	my ($self, $file) = @_;
	return unless $file;

	open( LOAD_FILE, "<$file" ) || do {
		warn "Unable to open $file: $!\n";
		return undef;
	};

	my $st;
	while( <LOAD_FILE> ) {
		$st .= $_;
	}

	close( LOAD_FILE );
	return $st;
}

sub _save {
	my ($self, $buffer) = @_;
	return unless $buffer;

	my $file = qq{$main::orac_home/tmp$$.sql};

	print STDERR "Writing: $buffer to File: $file\n";

	open( SAVE_FILE, "> ${file}" ) || do {
		warn "Unable to save to ${file}: $!\n";
		return undef;
	};

	print SAVE_FILE "${buffer}\n";

	close( SAVE_FILE );

	return $file;
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}

1;
