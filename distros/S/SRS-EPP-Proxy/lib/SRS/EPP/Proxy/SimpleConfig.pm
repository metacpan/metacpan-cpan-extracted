package SRS::EPP::Proxy::SimpleConfig;
{
  $SRS::EPP::Proxy::SimpleConfig::VERSION = '0.22';
}

# This package is a monkeypatch for MooseX::SimpleConfig, which;
#   a) does not allow multiple filenames to be passed as the configfile
#   b) requires that they *all* exist, or it blows up
# See rt.cpan.org#57027, apparently fixed in MooseX::SimpleConfig 0.07,
# but we still need this class here to pull in the
# MooseX::ConfigFromFile monkeypatch.

use Moose::Role;
with 'SRS::EPP::Proxy::ConfigFromFile';

use Config::Any ();

sub get_config_from_file {
	my ($class, $file) = @_;

	my $files_ref = ref $file eq 'ARRAY' ? $file : [$file];

	my $can_config_any_args = $class->can('config_any_args');
	my $extra_args = $can_config_any_args
		? $can_config_any_args->($class, $file)
		: {};
		
	local $SIG{__WARN__} = sub {
        return if $_[0] =~ /deprecated/i;
        print STDERR @_;
    };
		
	my $raw_cfany = Config::Any->load_files({
			%$extra_args,
			use_ext         => 1,
			files           => $files_ref,
			flatten_to_hash => 1,
		}
	);
	
	undef local $SIG{__WARN__};

	my %raw_config;
	foreach my $file_tested ( reverse @{$files_ref} ) {
		if ( !exists $raw_cfany->{$file_tested} ) {
			next;
		}

		my $cfany_hash = $raw_cfany->{$file_tested};
		die "configfile must represent a hash structure in file: $file_tested"
			unless $cfany_hash && ref $cfany_hash && ref $cfany_hash eq 'HASH';

		%raw_config = ( %raw_config, %{$cfany_hash} );
	}

	\%raw_config;
}

no Moose::Role;
1;

