package Mojolicious::Plugin::StaticCompressor::Container;
# Complex cache container

use strict;
use warnings;
use utf8;

use Mojo::Asset::File;

use Mojolicious::Plugin::StaticCompressor::File;

sub new {
	my ($class, %hash) = @_;
	my $s = bless({}, $class);

	# Initialize
	$s->{config} = $hash{config};
	$s->{mojo_static} = $hash{config}->{mojo_static} || die('Not specified mojo_static');
	$s->{path_cache_dir} = $hash{config}->{path_cache_dir} || die('Not specified path_cache_dir');

	$s->{key} = undef;
	$s->{is_minify} = $hash{is_minify} || 0;
	$s->{extension} = $hash{extension} || undef;
	$s->{files} = undef;
	$s->{num_of_files} = undef;
	$s->{content} = undef;

	if(defined $hash{key}){
		# Initialize from the key (with load the path of files, from cached file)
		$s->{key} = $hash{key};
		$s->_init_from_key();
	} elsif(defined $hash{path_files_ref}) {
		# Initialize from the path of files
		$s->_init_from_source_files( $hash{path_files_ref} );
	}

	return $s;
}

# Get (or Generate) the key
sub get_key {
	my $s = shift;

	if(!defined $s->{key}){

		my $key = "";
		foreach my $file (@{$s->{files}}){
			if($key ne ""){
				$key .= ",";
			}
			$key .= $file->get_raw_path();
		}

		$key = Mojo::Util::sha1_sum($key);

		if($s->{is_minify} == 0){
			$key = "nomin-".$key;
		}
		$s->{key} = $key.'.'.$s->{extension};
	}

	return $s->{key};
}

# Get the extension
sub get_extension {
	my $s = shift;
	return $s->{extension};
}

# Get the processed content
sub get_content {
	my $s = shift;
	return $s->{content};
}

# Update with check for update of files. (Return: Not updated = 0 / Updated = 1)
sub update {
	my $s = shift;
	return $s->_cache();
}

# Initialize from the key
sub _init_from_key {
	my $s = shift;

	# Load parameters from the key
	if(defined $s->{key}){
		if($s->{key} =~ /^(nomin\-|)(\w+).(\w+)$/){
			# Minify
			if($1 eq 'nomin-'){
				$s->{is_minify} = 0;
			} else {
				$s->{is_minify} = 1;
			}
			# Extension
			$s->{extension} = $3;
		}
	}

	# Load the list from cached file
	my @paths_files = $s->_load_from_cache();

	# Process and (re)cache
	if(@paths_files){
		$s->_init_from_source_files( \@paths_files );
	} else {
		die("Can't load the information from cached file. You must access to page of import origin.");
	}
}

# Load from the cached file and return the list of file
sub _load_from_cache {
	my $s = shift;
	my $path_cache_file =  $s->{path_cache_dir}.$s->{key};

	if(-f $path_cache_file){ # If exist cached file
		my $content;
		# Load the file and check the update_at
		eval {
			my $cache = Mojo::Asset::File->new( path => $path_cache_file );
			$content = Encode::decode_utf8($cache->slurp());
			my $updated_at = (stat( $path_cache_file ))[9];
		};
		if($@){ die("Can't read the cache file:". $path_cache_file); }

		# Parse the file
		if($content =~ /^\/\*-{5}StaticCompressor-{5}\n((.+\n)+?)-{10}\*\/\n/){
			my @paths = split("\n", $1);
			$content =~ s/^\/\*-{5}StaticCompressor-{5}\n((.+\n)+?)-{10}\*\/\n//;
			$s->{content} = $content;
			return @paths;
		}

		$s->{content} = $content;
	}

	return;
}

# Initialize from the source files
sub _init_from_source_files {
	my ($s, $path_files_ref) = @_;

	$s->{files} = ();
	$s->{num_of_files} = 0;

	foreach my $path (@{$path_files_ref}){
		my $file = Mojolicious::Plugin::StaticCompressor::File->new(
			path_file => $path,
			extension => $s->{extension},
			is_minify => $s->{is_minify},
			config => $s->{config},
		);
		push(@{$s->{files}}, $file);
		$s->{num_of_files} += 1;
	}

	# Process and cache
	$s->_cache();
}

# Process and cache the container file
sub _cache {
	my $s = shift;
	my $path_cache_file =  $s->{path_cache_dir}.$s->get_key();

	if(-f $path_cache_file){ # If exist cached file
		# Check for update of container cache
		my $updated_at;
		eval {
			my $cache = Mojo::Asset::File->new( path => $path_cache_file );
			$updated_at = (stat( $path_cache_file ))[9];
		}; 
		unless(@$){
			# Check for update of single files / caches
			my $is_need_update = 0;
			foreach my $file (@{$s->{files}}){
				if($updated_at <= $file->get_updated_at()){
					$is_need_update = 1;
					last;
				}
			}

			if($is_need_update == 0){ # Latest already
				return 0;
			}
		}
	}

	my $content = "";
	my $paths_text = "";
	# Process the files
	foreach my $file (@{$s->{files}}){
		# Process of the file (Minify), and Combine it
		$content .= $file->get_content();

		if($paths_text ne ""){ $paths_text .= "\n"};
		$paths_text .= $file->get_raw_path();
	}
	$s->{content} = $content;
	
	# Save to container cache
	my $cache = Mojo::Asset::File->new();
	my $save_header = <<EOF;
/*-----StaticCompressor-----
$paths_text
----------*/
EOF
	$cache->add_chunk( Encode::encode_utf8($save_header.$content) );
	$cache->move_to( $path_cache_file );

	return 1;
}

1;
__END__
=head1 NAME

Mojolicious::Plugin::StaticCompressor::Container

=head1 SYNOPSIS

This is internal package.

Please see POD for L<Mojolicious::Plugin::StaticCompressor>.

L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor/blob/master/README.pod>

=head1 METHODS

=head2 new ( ... )

Initialize a instance of cache container.

=head2 get_key ( )

Get a cache key of the file. (If necessary, generate it.)

=head2 get_extension ( )

Get the extension of the file.

=head2 get_content ( )

Get the processed content of the file.

=head2 update ( )

Check for updates of source files. And if necessary, update cache.

=head1 SEE ALSO

L<Mojolicious::Plugin::StaticCompressor> ( L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor> )

=head1 COPYRIGHT AND LICENSE

Please see POD for L<Mojolicious::Plugin::StaticCompressor>.

L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor/blob/master/README.pod>