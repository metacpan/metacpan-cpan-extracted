
package Getfile;

use Exporter;
@ISA = 'Exporter';
@EXPORT = '_getfile';

sub _getfile {
	my $filename = shift;
	if (defined $filename) {
		local *FILE;
		open FILE, $filename or return undef;
		local $/ = undef;
		my $content = <FILE>;
		close FILE;
		$content = undef if $content eq '';
		return $content;
	}
	return undef;
}

1;

