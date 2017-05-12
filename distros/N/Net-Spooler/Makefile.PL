# -*- perl -*-

use strict;
use ExtUtils::MakeMaker;

my %opts = ( 'NAME' => 'Net::Spooler',
	     'VERSION_FROM' => 'lib/Net/Spooler.pm',
	     'PREREQ_PM' => { 'Net::Daemon' => 0,
			      'File::Spec' => 0,
			      'Data::Dumper' => 0
			  },
	     'clean' => { 'FILES' => 'tmp' },
	     'dist' => { 'COMPRESS' => 'gzip -9', 'SUFFIX' => '.gz' }
	     );
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'ABSTRACT_FROM'} = 'lib/Net/Spooler.pm';
    $opts{'AUTHOR'} = 'Jochen Wiedmann <joe@ispsoft.de>';
}

WriteMakefile(%opts);

package MY;

sub postamble {
    <<"EOF";

pm_to_blib: README

README: lib/Net/Spooler.pm
\tpod2text lib/Net/Spooler.pm >README

EOF
}

sub libscan {
    my $self = shift; my $path = shift;
    $path =~ /\~$/ ? undef : $path;
}
