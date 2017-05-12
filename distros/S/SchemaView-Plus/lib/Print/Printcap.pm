package Print::Printcap;

use strict;
use vars qw/$VERSION/;

$VERSION = '0.01';

=head1 NAME

Hints - Perl extension for parsing /etc/printcap

=head1 SYNOPSIS

	use Print::Printcap;

	my $printcap = new Print::Printcap;

	print join ',',$printcap->printers();

=head1 DESCRIPTION

Simple parser for /etc/printcap.

=head1 THE PRINT::PRINTCAP CLASS

=head2 new

Constructor create instance of Print::Printcap class and parse /etc/printcap. 
Optional argument is -file => 'filename' for specifying alternate printcap
file.

	my $printcap = new Print::Printcap;

=cut

sub new {
	my $class = shift;
	my $obj = bless { -file => '/etc/printcap', printers => [] }, $class;
	my %par = @_;
	for (keys %par) { $obj->{$_} = $par{$_}; }
	$obj->parse_printcap;
	return $obj;
}

sub parse_printcap {
	my $obj = shift;
	my $file = shift || $obj->{-file};

	open F,$file or return;
	while (<F>) {
		chomp;
		s/#.*$//;  s/\s+$//;  s/^\s+//;
		next unless $_;
		next if /^:/;
		next if /^\|/;
		next if /^all:/;
		if (/^include (.*)/) {
			$obj->parse_printcap($_);
			next;
		}
		s/:.*$//;  s/\|.*$//;
		push @{$obj->{printers}},$_;
	}
	close F;
}

=head2 printers

Return list of printers from /etc/printcap.

	my @printers = $printcap->printers();

=cut

sub printers {
	my $obj = shift;
	return @{$obj->{printers}};
}

1;

__END__

=head1 VERSION

0.01

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>).

=head1 SEE ALSO

perl(1), svplus(1), printcap(5).

=cut

