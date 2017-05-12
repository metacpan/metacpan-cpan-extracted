# -*- perl -*-

package TestUtil;

use strict;
use Exporter 'import';

our @EXPORT = qw(my_default_packages_file);

sub my_default_packages_file {
    if ($ENV{PERL_AUTHOR_TEST}) {
	return Parse::CPAN::Packages::Fast->_default_packages_file_interactive;
    }

    my $packages_file = eval { Parse::CPAN::Packages::Fast->_default_packages_file_batch };
    return undef if $packages_file && (!-r $packages_file || -z $packages_file);
    $packages_file;
}

1;

__END__
