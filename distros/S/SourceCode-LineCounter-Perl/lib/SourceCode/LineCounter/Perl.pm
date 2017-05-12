package SourceCode::LineCounter::Perl;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

use Carp qw(carp);

$VERSION = '1.02';

=head1 NAME

SourceCode::LineCounter::Perl - Count lines in Perl source code

=head1 SYNOPSIS

	use SourceCode::LineCounter::Perl;

	my $counter    = SourceCode::LineCounter::Perl->new;

	$counter->count( $file );
	
	my $total_lines   = $counter->total;
	
	my $pod_lines     = $counter->documentation;
	
	my $code_lines    = $counter->code;
	
	my $comment_lines = $counter->comment;

	my $comment_lines = $counter->blank;
	
	
=head1 DESCRIPTION

This module counts the lines in Perl source code and tries to classify
them as code lines, documentation lines, and blank lines.

Read a line

If it's a blank line, record it and move on to the next line

If it is the start of pod, mark that we are in pod, and count
it as a pod line and move on

If we are in pod and the line is blank, record it as a blank line
and a pod line, and move on.

If we are ending pod (with C<=cut>, record it as a pod line and 
move on.

If we are in pod and it is not blank, record it as a pod line and
move on.

If we are not in pod, guess if the line has a comment. If the
line has a comment, record it.

Removing comments, see if there is anything left. If there is,
record it as a code line.

Move on to the next line.

=cut

=over 4

=item new

=cut

sub new {
	my( $class, %hash ) = @_;
	
	my $self = bless {}, $class;
	$self->_init;
	
	$self;
	}
	
=item reset

Reset everything the object counted so you can use the same object
with another file.

=cut

sub reset {
	$_[0]->_init;	
	}

=item accumulate( [ BOOLEAN ] )

With no argument, returns the current setting as true or false.

With one argument, sets the value for accumulation. If that's true,
the counter will add to the count from previous calls to C<counter>.
If false, C<counter> starts fresh each time.

=cut

sub accumulate {
	my( $self ) = @_;
	
	$self->{accumulate} = !! $_[1] if @_ > 1;

	return $self->{accumulate};
	}

=item count( FILE )

Counts the lines in FILE. The optional second argument, if true,
adds those counts to the counts from the last run. By default,
previous results are cleared.

=cut

sub count {
	my( $self, $file ) = @_;

	my $fh;
	unless( open $fh, "<", $file ) {
		carp "Could not open file [$file]: $!";
		return;
		}
		
	$self->_clear_line_info unless $self->accumulate;

	LINE: while( <$fh> ) {
		chomp;
		$self->_set_current_line( \$_ );
		
		$self->_total( \$_ );
		$self->add_to_blank if $self->_is_blank( \$_ );
		
		foreach my $type ( qw( _start_pod _end_pod _pod_line ) ) {
			$self->$type( \$_ ) && $self->add_to_documentation && next LINE;
			}
			
		$self->add_to_comment if $self->_is_comment( \$_ );
		$self->add_to_code if $self->_is_code( \$_ );
		}
		
	$self;
	}
	
sub _clear_line_info {
	$_[0]->{line_info} = {};
	}

sub _set_current_line {
	$_[0]->{line_info}{current_line} = \ $_[1];
	}
	
sub _init {
	my @attrs = qw(total blank documentation code comment accumulate);
	foreach ( @attrs ) { $_[0]->{$_} = 0 unless defined $_[0]->{$_} }
	$_[0]->_clear_line_info;
	};
	
=item total

Returns the total number of lines in the file

=cut

sub total  { $_[0]->{total}   }

sub _total { ++ $_[0]->{total} }

=item documentation

Returns the total number of Pod lines in the file, including
and blank lines in Pod.

=cut

sub documentation { $_[0]->{documentation} }

=item add_to_documentation

Add to the documentation line counter if the line is documentation.

=cut

sub add_to_documentation {	
	$_[0]->{line_info}{documentation}++;
	$_[0]->{documentation}++;
	
	1;	
	}

sub _start_pod {
	return if $_[0]->_in_pod;
	return unless ${$_[1]} =~ /^=\w+/;
	
	$_[0]->_mark_in_pod;
	
	1;
	}

sub _end_pod {
	return unless $_[0]->_in_pod;
	return unless ${$_[1]} =~ /^=cut$/;
	
	$_[0]->_clear_in_pod;

	1;
	}

sub _pod_line {
	return unless $_[0]->_in_pod;
	}
	
sub  _mark_in_pod { $_[0]->{line_info}{in_pod}++   }
sub       _in_pod { $_[0]->{line_info}{in_pod}     }
sub _clear_in_pod { $_[0]->{line_info}{in_pod} = 0 }


=item code

Returns the number of non-blank lines, whether documentation
or code.

=cut

sub code { $_[0]->{code} }

=item add_to_code( LINE )

Add to the code line counter if the line is a code line.

=cut

sub add_to_code {
	$_[0]->{line_info}{code}++;
	++$_[0]->{code};
	}

sub _is_code {
	my( $self, $line_ref ) = @_;
	return if grep { $self->$_() } qw(_is_blank _in_pod);
		
	# this will be false for things in strings!
	( my $copy = $$line_ref ) =~ s/\s*#.*//;
	
	return unless length $copy;

	1;
	}

=item comment

The number of lines with comments. These are the things
that start with #. That might be lines that are all comments
or code lines that have comments.

=cut

sub comment { $_[0]->{comment} }

=item add_to_comment

Add to the comment line counter if the line has a comment. A line
might be counted as both code and comments.

=cut

sub add_to_comment {
	$_[0]->{line_info}{comment}++;
	++$_[0]->{comment};
	}

sub _is_comment {
	return if $_[0]->_in_pod;
	return unless ${$_[1]} =~ m/#/;
	1;
	}

=item blank

The number of blank lines. By default, these are lines that
match the regex qr/^\s*$/. You can change this in C<new()>
by specifying the C<line_ending> parameter. 

=cut

sub blank  { $_[0]->{blank} }

=item add_to_blank

Add to the blank line counter if the line is blank.

=cut

sub add_to_blank {	
	$_[0]->{line_info}{blank}++;
	++$_[0]->{blank};
	}

sub _is_blank {
	return unless defined $_[1];
	return unless ${$_[1]} =~ m/^\s*$/;
	1;
	}

=back

=head1 TO DO

=over 4

=item * Generalized LineCounter that can dispatch to language
delegates.

=back

=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github

	https://github.com/briandfoy/sourcecode-linecounter-perl

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
