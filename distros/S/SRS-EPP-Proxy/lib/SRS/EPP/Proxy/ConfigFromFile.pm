package SRS::EPP::Proxy::ConfigFromFile;
{
  $SRS::EPP::Proxy::ConfigFromFile::VERSION = '0.22';
}

use Moose::Role;
with 'MooseX::ConfigFromFile', { -excludes => "new_with_config" };

# this package is a monkeypatch for MooseX::ConfigFromFile, which
# unnecessarily uses metaprogramming to retrieve the default value
# - as it does not use the logic that the regular constructor does,
# specifying eg a sub to the default breaks it.
# See rt.cpan.org#57023

sub new_with_config {
	my ($class, %opts) = @_;

	my $configfile;

	if(defined $opts{configfile}) {
		$configfile = $opts{configfile}
	}
	else {
		$configfile = $class->configfile
	}

	if(defined $configfile) {
		%opts = (%{$class->get_config_from_file($configfile)}, %opts);
	}

	$class->new(%opts);
}

no Moose::Role;
1;

