package Project::Easy::Helper;

use Class::Easy;

use Project::Easy::Config::File;

sub config {
	
	my @params = @ARGV;
	@params = @_
		if scalar @_;
	
	my ($package, $libs) = &_script_wrapper(); # Project name and "libs" path
	
	my $core   = $::project;  # Project singleton
	my $config = $core->config;
	
	my $templates = file->__data__files ();   # Got all "data files" at end of file
	
	# Local config absolute path
	my $config_file  = $core->fixup_path_instance ($core->instance);
	my @config_serializer = ();
	
	# first, we need to detect scope of config
	if ($params[0] =~ /--(project|global)/) {
		shift @params;
		
		# Global config absolute path
		$config_file = $core->conf_path;
		push @config_serializer, 'undef_keys_in_patch';
	} elsif ($params[0] =~ /-{1,2}f(?:ile)?/) {
		shift @params;
		$config_file = Project::Easy::Config::File->new (shift @params);
		
		# try to load config
		local $@;
		$config = eval {$config_file->deserialize;};
		die "config file ($config_file) access error: $!"
			if $!;

		die "config file ($config_file) cannot be deserialized"
			if $@;
	}
	
	my ($key, $command, @remains) = @params;
	
	unless (defined $key) {
		print "requested config file name is: ", $config_file, "\n";
		print $templates->{'config-usage'}, "\n";
		return;
	}
	
	if ($key eq '-e') {
		system ($ENV{EDITOR}, $config_file);
		return;
	}
	
	#  $key      = "key1.key2.key3..."
	#  $key_eval = "{key1}->{key2}->{key3}..."
	my $key_path = "{" . join ('}->{', split (/\./, $key)) . '}';
	my $key_eval = "\$config->$key_path";

	my $struct     = eval $key_eval;
	my $ref_struct = ref $struct;

	if (!defined $command or ($command eq 'dump' and !$ref_struct)) {
		print "'$key' => ";
		
		if ($ref_struct eq 'HASH') {
			print "HASH with keys: ", join ', ', keys %$struct;
		
		} elsif ($ref_struct eq 'ARRAY') {
			print "ARRAY of ", scalar @$struct;
		
		} elsif (!$ref_struct) {
			print "'", (defined $struct ? $struct : 'null'), "'";
		}
		print "\n";
		return 1;
	}

	my $conf_package = $package->conf_package;		# Project::Easy::Config

	# Init serializer to parse config file
	my $serializer_json = $conf_package->serializer ('json');
	
	if ($command =~ /^(?:--)?dump$/) {
		print "\"$key\" => ";
		print $serializer_json->dump_struct ($struct);
		print "\n";
		return 1;
	}
	
	# set or = can: create new key (any depth), modify existing
	# template can: create new key (any depth)
	if ($command eq 'set' or $command eq '=' or $command eq 'template') {
		
		die "you must supply value for modify config"
			unless scalar @remains;
		
		# check for legitimity
		die "you cannot set/template complex value such as HASH/ARRAY. remove old key first"
			if $ref_struct;
		
		die "you cannot update scalar value with template. remove old key first"
			if $command eq 'template' and defined $struct; # any setter
		
		# patch creation for config files
		
		my $fixup_struct = {};
		
		if ($command eq 'template') {

			my $template = $serializer_json->parse_string (
				$templates->{'template-' . $remains[0]}
			);
			
			eval "\$fixup_struct->$key_path = \$template";
		} else {
			eval "\$fixup_struct->$key_path = \$remains[0]";
		}
        
		
		# storing modified config
		$config_file->patch ($fixup_struct, @config_serializer);
        #warn(Dumper($config_file->contents));

		return 1;
	}

	print $templates->{'config-usage'}, "\n";
	
	return;
}


1;

__DATA__

