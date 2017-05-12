# Example usage:
#
# AddRule $file, [$file],
#     undef,
#     AppendConfig('CFLAGS_INCLUDE' => ' -I ./pip');

sub AppendConfig
{
	my (%append_config) = @_;
	
	return 
		sub
		{
        	my (
				$dependent_to_check
				, $config
				, $tree
				, $inserted_nodes
			) = @_ ;

			# Config is shared; get our own copy (note! this is not deep).
			$tree->{__CONFIG} = {%{$tree->{__CONFIG}}} ;

			while (my ($key, $value) = each %append_config)
			{
				my $config = $tree->{__CONFIG};
				$config->{$key} .= $value;
			}
		};
}


1;
