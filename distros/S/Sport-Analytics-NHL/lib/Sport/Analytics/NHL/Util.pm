package Sport::Analytics::NHL::Util;

use strict;
use warnings FATAL => 'all';

use Carp;
use File::Basename;
use File::Path qw(mkpath);
use Data::Dumper;

use parent 'Exporter';

$SIG{__DIE__} = sub { Carp::confess( @_ ) };

=head1 NAME

Sport::Analytics::NHL::Util - Simple system-independent utilities

=head1 SYNOPSIS

Provides simple system-independent utilities. For system-dependent utilities see Sports::Analytics::NHL::Tools .

  use Sport::Analytics::NHL::Util
  debug "This is a debug message";
  verbose "This is a verbose message";
  my $content = read_file('some.file');
  write_file($content, 'some.file');
  $table = read_tab_file('some.tab.file');

=head1 FUNCTIONS

=over 2

=item C<debug>

Produces message to the STDERR if the DEBUG level is set ($ENV{HOCKEYDB_DEBUG})

=item C<verbose>

Produces message to the STDERR if the VERBOSE ($ENV{HOCKEYDB_VERBOSE})or the DEBUG level are set.

=item C<read_file>

 Reads a file into a scalar
 Arguments: the filename
 Returns: the scalar with the filename contents

=item C<write_file>

 Writes a file from a scalar, usually replacing the non-breaking space with regular space
 Arguments: the content scalar
            the filename
 Returns: the filename written

=item C<read_tab_file>

 Reads a tabulated file into an array of arrays
 Arguments: the tabulated file
 Returns: array of arrays with the data

=item C<fill_broken>

Fills a hash (player, event, etc.) with preset values. Usually happens with broken items.
Arguments:
 * the item to fill
 * the hash with the preset values to use
Returns: void.

=item C<get_seconds>

 Get the number of seconds in MM:SS string
 Arguments: the MM:SS string
 Returns: the number of seconds

=back

=cut

our @EXPORT = qw(
	debug verbose
	read_file write_file
	fill_broken
	get_seconds
);

sub debug ($) {

	my $message = shift;

	print STDERR "$message\n" if $ENV{HOCKEYDB_DEBUG};
}

sub verbose ($) {

	my $message = shift;

	print STDERR "$message\n" if $ENV{HOCKEYDB_VERBOSE} || $ENV{HOCKEYDB_DEBUG};
}

sub read_file ($;$) {

	my $filename = shift;
	my $no_strip = shift || 0;
	my $content;

	debug "Reading $filename ...";
	open(my $fh, '<', $filename) or die "Couldn't read file $filename: $!";
	{
		local $/ = undef;
		$content = <$fh>;
	}
	close $fh;
#	$content =~ tr/ / /;
	$content =~ s/\xC2\xA0/ /g unless $no_strip;
	$content;
}

sub read_tab_file ($) {

	my $filename = shift;
	my $table = [];

	debug "Reading tabulated $filename ...";
	open(my $fh, '<', $filename) or die "Couldn't read file $filename: $!";
	while (<$fh>) {
		chomp;
		my @row = split(/\t/);
		push(@{$table}, [@row]);
	}
	close $fh;
	$table;
}

sub write_file ($$;$) {

	my $content  = shift;
	my $filename = shift;
	my $no_strip = shift || 1;

	debug "Writing $filename ...";
	mkpath(dirname($filename)) unless -d dirname($filename);
	$content =~ s/\xC2\xA0/ /g unless $no_strip;
	open(my $fh, '>', $filename) or die "Couldn't write file $filename: $!";
	binmode $fh, ':utf8';
	print $fh $content;
	close $fh;
	$filename;
}

sub fill_broken($$;$) {

	my $item = shift;
	my $broken = shift;

	return unless $broken;
	for my $field (keys %{$broken}) {
		$item->{$field} = $broken->{$field};
	}
}

sub get_seconds ($) {

	my $time = shift;

	unless (defined $time) {
		print "No time supplied\n";
		die Dumper [caller];
	}
	return $time if $time =~ /^\d+$/;
	$time =~ /^\-?(\d+)\:(\d+)$/;
	$1*60 + $2;
}


=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Util

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Util>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Util>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Util>

=back

=cut

1;
