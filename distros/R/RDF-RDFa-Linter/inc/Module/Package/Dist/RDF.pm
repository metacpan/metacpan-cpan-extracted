#line 1
package Module::Package::Dist::RDF;

my $explanation = q<
	This is the component of Module::Package::RDF which gets
	bundled with the distribution.
>;

use 5.005;
use strict;

BEGIN {
	$Module::Package::Dist::RDF::AUTHORITY = 'cpan:TOBYINK';
	$Module::Package::Dist::RDF::VERSION   = '0.009';
	@Module::Package::Dist::RDF::ISA       = 'Module::Package::Dist';
}

sub _main
{
	my ($self) = @_;
	$self->mi->trust_meta_yml;
	$self->mi->auto_install;
}

{
	package Module::Package::Dist::RDF::standard;
	use 5.005;
	use strict;
	BEGIN {
		$Module::Package::Dist::RDF::standard::AUTHORITY = 'cpan:TOBYINK';
		$Module::Package::Dist::RDF::standard::VERSION   = '0.009';
		@Module::Package::Dist::RDF::standard::ISA       = 'Module::Package::Dist::RDF';
	}
}

{
	package Module::Package::Dist::RDF::tobyink;
	use 5.005;
	use strict;
	BEGIN {
		$Module::Package::Dist::RDF::tobyink::AUTHORITY = 'cpan:TOBYINK';
		$Module::Package::Dist::RDF::tobyink::VERSION   = '0.009';
		@Module::Package::Dist::RDF::tobyink::ISA       = 'Module::Package::Dist::RDF';
	}
}

1;
