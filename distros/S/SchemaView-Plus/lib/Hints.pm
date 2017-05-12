package Hints;

use strict;
use vars qw/$VERSION/;
use IO::Handle;
use IO::File;

$VERSION = '0.02';

=head1 NAME

Hints - Perl extension for hints databases

=head1 SYNOPSIS

	use Hints;

	my $hints = new Hints;

	$hints->load_from_file('my.hints');

	print $hints->random();

=head1 DESCRIPTION

In many programs you need hints database and methods for accessing this
database. Extension Hints is object oriented abstract module, you can
use file-base of hints or make descendant with own base.

=head1 THE HINTS CLASS

=head2 new

Constructor create instance of Hints class. Than call C<init()> constructor
for build implicit database (descendant ussually re-implement these method).

	my $hints = new Hints;

=cut

sub new {
	my $class = shift;
	my $obj = bless { base => [], last => 0 }, $class;
	$obj->clear();
	srand (time() ^ ($$ + ($$ << 15)));
	return $obj->init(@_);
}

=head2 init

This method was called from C<new()> constructor for building implicit
database. Base class define only abstract version. Return value of C<init()>
method must be instance (typically same as calling instance). You can use
this to change class or stop making instance by returning of undefined value.

=cut

sub init {
	return shift;
}

=head2 load_from_file (FILE, SEPARATOR)

Loading all hints from file specified as first argument. Hints separator is
determined by second argument. If separator is undefined than default separator
is used (^---$). Separator argument is regular expression.

You can also use file handle or reference to array instead of filename.

	$hints->load_from_file('my.hints','^**SEPARATOR**$');
	$hints->load_from_file(\*FILE,'^**SEPARATOR**$');
	$hints->load_from_file(\@lines,'^**SEPARATOR**$');

=cut

sub load_from_file {
	my $obj = shift;
	my $file = shift;
	my $separator = shift || '^---$';
	my $ioref;

	return unless defined $file;
	my @lines = ();
	if (ref $file eq 'ARRAY') {
		@lines = @$file;
	} elsif (ref $file) {
		eval {
			$ioref = *{$file}{IO};
		};
		return if $@;
		@lines = <$ioref>;
	} else {
		return unless $ioref = new IO::File $file;
		@lines = <$ioref>;
	}

	my @current = ();
	for (@lines) {
		chomp;
		if (/$separator/) {
			push @{$obj->{base}},[ @current ];
			@current = ();
		} else {
			push @current,$_;	
		}
	}
	$ioref->close() unless ref $file;
	push @{$obj->{base}},\@current if @current;
}

=head2 clear

This method clear hints database.

	$hints->clear;

=cut

sub clear {
	my $obj = shift;

	$obj->{base} = [];
}

=head2 format

Method is used for formatting hint before returning. Ussually redefined by
descendant. In abstract class making one long line from multilines.

=cut

sub format {
	my $obj = shift;
	my $output = join ' ',@_;
	$output =~ s/\s+$//;
	return $output;
}

=head2 first

Return first hint from database.

	my $hint = $hints->first;

=cut

sub first {
	my $obj = shift;
	$obj->{iterator} = 0;
	return $obj->next;
}

=head2 next

Return next hint from database (used after first).
If no hint rest undefined value is returned.

	my $hint = $hints->first;
	do {
		print $hint."\n";
	} if (defined $hint = $hints->next);

=cut

sub next {
	my $obj = shift;
	$obj->{last} = $obj->{iterator};
	return $obj->item($obj->{iterator}++);
}

=head2 random

Return random hint from database.

	my $hint = $hints->random;

=cut

sub random {
	my $obj = shift;
	my $l;
	do {
		$l = rand($obj->count());
		last if $obj->count() == 1;
	} while ($l == $obj->{last});
	return $obj->item($obj->{last} = $l);
}

=head2 count

Return number of hints in database.

	my $number = $hints->count;

=cut

sub count {
	my $obj = shift;
	return scalar @{$obj->{base}};
}

=head2 item NUMBER

Return NUMBER. item from database.

	# return last hint
	my $hint = $hints->item($hints->count - 1);

=cut

sub item {
	my $obj = shift;
	my $number = shift;
	$obj->{last} = $number;
	return $obj->format(@{$obj->{base}->[$number]});
}

=head2 forward

Return next hint after last wanted hint from database.

	my $random_hint = $hints->random;
	my $next_hint   = $hints->forward;

=cut

sub forward {
	my $obj = shift;
	$obj->{last} = 0 if ++$obj->{last} >= $obj->count;
	return $obj->item($obj->{last});	
}

=head2 backward

Return previous hint before last wanted hint from database.

	my $random_hint = $hints->random;
	my $prev_hint   = $hints->backward;

=cut

sub backward {
	my $obj = shift;
	$obj->{last} = $obj->count() - 1 if --$obj->{last} < 0;
	return $obj->item($obj->{last});	
}

1;

__END__

=head1 VERSION

0.02

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>) for making
user-friendly interface.

=head1 SEE ALSO

perl(1), svplus(1), Hints::Base(3), Hints::Base::svplus(3).

=cut

