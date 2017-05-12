#
# vim:ts=2:sw=2
# Package: Orac::Shell::Format
# Controls the output formats of data.
#

package Shell::Format;

use DBI::Format;
use Data::Dumper;
use strict;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');


my $formats;
sub load_formats {
    my ($sh) = @_;
    my (@pi, @formats);

	# First, look at the list of formatters available through DBI::Format.

	$formats = DBI::Format::available_formatters;

    foreach my $where (qw{Shell/Format Shell_Format}) {
	my $mod = $where; $mod =~ s!/!::!g; #/
	my @dir = map { -d qq{$_/$where} ? (qq{$_/$where}) : () } @INC;
	foreach my $dir (@dir) {
	    opendir DIR, $dir or warn "Unable to read $dir: $!\n";
	    push @pi, map { s/\.pm$//; "${mod}::$_" } grep { /\.pm$/ }
	        readdir DIR;
	    closedir DIR;
	}
    }
    foreach my $pi (@pi) {
			# local $DBI::Shell::SHELL = $sh; # publish the current shell
			#$sh->log("Loading $pi");
			eval qq{ use $pi };
			warn("Unable to load $pi: $@") if $@;
			unless($@) {
				$pi =~ m/::(\w+)$/i;
				$formats->{lc $1} = $pi;
			}
    }
#	print Dumper($formats);
return (sort keys %$formats);
}

#
# For now, formatters is a simply pass-thru to DBI::Format.
#
sub formatter {
	my $self = shift;
	my $type = shift;

return DBI::Format->formatter($type);
}


1;
__END__
