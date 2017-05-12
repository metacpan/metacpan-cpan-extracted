package Oogaboogo::Date;

use 5.012004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Oogaboogo::Date ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
day mon	
);

our $VERSION = '0.01';


# Preloaded methods go here.

my @day = qw(ark dip wap sen pop sep kir);
my @mon = qw(diz pod bod rod sip wax lin sen kun fiz nap dep);

sub day {
	my $num = shift @_;
	die "$num is not a valid day number" unless 0 <= $num and $num <= 6;
	$day[$num];
}

sub mon {
	my $num = shift @_;
	die "$num is not a valid month" unless 0 <= $num and $num <= 11;
	$mon[$num];
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Oogaboogo::Date - Perl extension for converting Month and Day to the Oogaboogo Language.

=head1 SYNOPSIS

  use Oogaboogo::Date;
  my($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime;

  my $day_name = day($wday);
  my $mon_name = mon($mon);

=head1 DESCRIPTION

The Oogaboogoo language is hard to learn.  So, we provide a Perl extension
to convert the month and day

=head2 EXPORT

None by default.


=head1 SEE ALSO

=head1 AUTHOR

Jacob Perkins, E<lt>jacobperk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jacob Perkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
