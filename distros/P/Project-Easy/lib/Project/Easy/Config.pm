package Project::Easy::Config;

use Class::Easy;

our %nonexistent_keys_in_config = ();
our @curr_patch_config_path = ();

#sub patch ($$);

sub parse {
	my $class    = shift;
	my $core     = shift;
	my $instance = shift;
	
	my $path  = $core->conf_path;
	my $fixup = $core->fixup_path_instance ($instance);
	
	# TODO: replace to real splitpath and join '/' for windows users
	my $root_path = $core->root->path;
	$root_path =~ s/\\/\//g;

	# here we want to expand some generic params
	my $expansion = {
		root   => $root_path,
		id     => $core->id,
		instance => $core->instance,
	};
	
	my $conf = $path->deserialize ($expansion);
	my $alt  = $fixup->deserialize ($expansion);
	
	patch ($conf, $alt);
	
	return $conf;
}

my $ext_syn = {
	'pl' => 'perl',
	'js' => 'json',
};

sub serializer {
	shift;
	my $type = shift;
	
	$type = $ext_syn->{$type}
		if exists $ext_syn->{$type};
	
	my $pack = "Project::Easy::Config::Format::$type";
	
	die ('no such serializer: ', $type)
		unless try_to_use ($pack);
	
	return $pack->new;
}

sub string_from_template {

    my $template  = shift;
    my $expansion = shift;

    return unless $template;

    foreach (keys %$expansion) {
        next unless defined $expansion->{$_};

        $template =~ s/\{\$$_\}/$expansion->{$_}/sg;
    }

    return $template;
}

sub patch {
	my $struct    = shift;
	my $patch     = shift;
    my $algorithm = shift || 'ordinary_patch';
    
    # $algorithm = ordinary_patch || undef_keys_in_patch || store_nonexistent_keys_in_struct
	
    return if ref $struct ne 'HASH' and ref $patch ne 'HASH';

    unless ( scalar keys %$struct ) {
        %$struct = %$patch;
        return;
    }
    
    my $algo_id = {
        ordinary_patch                      => 1,
        undef_keys_in_patch                 => 2,
        store_nonexistent_keys_in_struct    => 3,        
    };
    
	foreach my $k (keys %$patch) {
        
        push @curr_patch_config_path, $k;

		if (! exists $struct->{$k}) {
            if ( $algo_id->{$algorithm} == 2 ) {
                $struct->{$k} = _recursive_undef_struct($patch->{$k});
            }
            elsif ( $algo_id->{$algorithm} == 3 ) {
                _recursive_traverse_struct($patch->{$k}, join('.', @curr_patch_config_path));
            }
            else {
                $struct->{$k} = $patch->{$k};
            }
			
		} elsif (
			(! ref $patch->{$k} && ! ref $struct->{$k})
			|| (ref $patch->{$k} eq 'ARRAY' && (ref $struct->{$k} eq 'ARRAY'))
			|| (ref $patch->{$k} eq 'Regexp' && (ref $struct->{$k} eq 'Regexp'))
		) {
			if ( $algo_id->{$algorithm} == 2 ) {
                patch ($struct->{$k}, $patch->{$k}, $algorithm);
            }
            else {
                $struct->{$k} = $patch->{$k};
            }
		} elsif (ref $patch->{$k} eq 'HASH' && (ref $struct->{$k} eq 'HASH')) {
			patch ($struct->{$k}, $patch->{$k}, $algorithm);
		} elsif (ref $patch->{$k} eq 'CODE' && (ref $struct->{$k} eq 'CODE' || ! defined $struct->{$k})) {
			$struct->{$k} = $patch->{$k};
		}
	}
}

sub _recursive_undef_struct {
    my $data = shift;
    
    if ( ! ref $data ) {
        $data = undef;
    }
    else {
        if      ( ref $data eq 'ARRAY' ) {
            @$data = map { _recursive_undef_struct($_) } @$data;
        }
        elsif   ( ref $data eq 'HASH'  ) {
            %$data = map { $_ => _recursive_undef_struct($data->{$_}) } keys %$data;
        }
    }
    
    return $data;
}

sub _recursive_traverse_struct {
    my $data = shift;
    my $name = shift;
    
    if ( ! ref $data) {
        $nonexistent_keys_in_config{$name} = 1;
    }
    elsif ( ref $data eq 'ARRAY' ) {
        foreach my $element (@$data) {
            if (! ref $element) {
                $nonexistent_keys_in_config{$name} = 'ARRAY of ' . scalar @$data . ' elements';
            }
            else {
                _recursive_traverse_struct($element, $name);
            }
        }
    }
    elsif ( ref $data eq 'HASH'  ) {
        foreach my $key ( keys %$data ) {
            $nonexistent_keys_in_config{"$name.$key"} = 1 if (! ref $data->{$key});

            _recursive_traverse_struct($data->{$key}, "$name.$key");
        }
    }

    return $data;
}

1;
