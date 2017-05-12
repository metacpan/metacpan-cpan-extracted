package Padre::Plugin::XML::Document;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.10';
our @ISA     = 'Padre::Document';

sub task_syntax {
	return 'Padre::Task::SyntaxChecker::XML';
}

sub check_syntax {
	my $self  = shift;
	my %args  = @_;
	$args{background} = 0;
	return $self->_check_syntax_internals(\%args);
}

sub check_syntax_in_background {
	my $self  = shift;
	my %args  = @_;
	$args{background} = 1;
	return $self->_check_syntax_internals(\%args);
}

sub _check_syntax_internals {
	my $self = shift;
	my $args = shift;

	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	use Encode qw(encode_utf8);
	my $md5 = Digest::MD5::md5(encode_utf8($text));
	unless ( $args->{force} ) {
		if ( defined( $self->{last_checked_md5} )
		     && $self->{last_checked_md5} eq $md5
		) {
			return;
		}
	}
	$self->{last_checked_md5} = $md5;

	require Padre::Task::SyntaxChecker::XML;
	my $task = Padre::Task::SyntaxChecker::XML->new(
		text     => $text,
		filename => $self->editor->{Document}->filename,
		( exists $args->{on_finish} ? (on_finish => $args->{on_finish}) : () ),
	);
	if ( $args->{background} ) {
		# asynchronous execution (see on_finish hook)
		$task->schedule();
		return();
	}
	else {
		# serial execution, returning the result
		return () if $task->prepare() =~ /^break$/;
		$task->run();
		return $task->{syntax_check};
	}
}

sub comment_lines_str { return [ '<!--', '-->' ] }

1;
