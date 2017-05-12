#
#
#

package Shell::File;
use Tk;
use Tk::FileSelect;

use strict;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');


#$FSref = $top->FileSelect(-directory => $start_dir);
              #$top            - a window reference, e.g. MainWindow->new
              #$start_dir      - the starting point for the FileSelect
#$file = $FSref->Show;
              #Executes the fileselector until either a filename is
              #accepted or the user hits Cancel. Returns the filename
              #or the empty string, respectively, and unmaps the
              #FileSelect
#$FSref->configure(option => value[, ...])
              #Please see the Populate subroutine as the configuration
              #list changes rapidly.

sub get_file {
	my $self = shift;
	my $fs = $self->{dbiwd}->FileSelect( -directory => "$main::orac_home/sql" );
	return $fs->Show;
}

#
# save command if called with a buffer values of 1, skips the statement
# or buffer message.
#
sub save {
	my ($self, $buffer) = @_;
	my $ans;

	# Prevent users from saving empty buffers.
	do {
		$self->status(qq{Entry buffer is empty.});
		return undef;
	} unless($self->is_empty());

	if (!$buffer) {
		my $dialog = $self->dbiwd->Dialog(
			-text => 'Save Current Statement or Current Entry Buffer?',
			-bitmap => 'question',
			-title => 'Save File Dialog',
			-default_button => 'Statement',
			-buttons => [qw/Statement Buffer Cancel/]
		);

		$ans = $dialog->Show();

		return if ($ans =~ m/Cancel/i);

	} else {
			$ans = qq{Buffer};
		}

	my $statement = $self->current->statement;
	$statement = $self->entry_txt->get( '1.0', 'end' ) if ($ans =~ m/Buffer/i);

	my $file = $self->get_file();

	# User presses the cancel button.

        ############
        #
        # AJD - 17/11/1999 Fix Below - old line commented out
        #
        ############

	#return undef unless (length($file) > 0);

	return undef unless ((defined($file)) && (length($file) > 0));

	my $confirm;
	if (-f $file) {
		$confirm = $self->dbiwd->Dialog(
			-text => "File exists!  Overwrite current file\n${file}?",
			-bitmap => 'warning',
			-title => "Confirm overwrite",
			-default_button => 'No',
			-buttons => [ qw/Yes No Cancel/ ]
		);

		my $ans = $confirm->Show();

		return undef if ($ans =~ m/Cancel/i);
	}

	open( SAVE_FILE, "> ${file}" ) || do {
		warn "Unable to save to ${file}: $!\n";
		return undef;
	};

	print SAVE_FILE "${statement}\n";

	return close( SAVE_FILE );
}

sub load {
	my $self = shift;

	my $file = $self->get_file;
	# User presses the cancel button.
	return undef unless ( defined($file) and length($file) > 0 );
	my $ans = 'Replace';
	if ($self->is_empty) {
	my $dialog = $self->dbiwd->Dialog(
		-text => 'Append or Replace current entry buffer?',
		-bitmap => 'question',
		-title => 'Load File Dialog',
		-default_button => 'Append',
		-buttons => [qw/Append Replace Cancel/]);

		$ans = $dialog->Show;

		return if $ans =~ m/Cancel/i;
	}

	$self->clear_all if $ans =~ m/Replace/i;

	open( LOAD_FILE, "<$file" ) || do {
		warn "Unable to open $file: $!\n";
		return undef;
	};

	while( <LOAD_FILE> ) {
		$self->entry_txt->insert( 'end', $_ );
	}

	return close( LOAD_FILE );
}

sub is_empty {
	my $self = shift;
	my $txt = $self->entry_txt->get( '1.0', 'end' );
	chomp $txt;
	print STDERR qq{Length: } . length( $txt ) . qq{ Value: (} . $txt . qq{)\n}
		if ($self->debug);
	return length( $txt );
}
sub view {
	my $self = shift;

}

1;
