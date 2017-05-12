package Mojolicious::Plugin::StaticCompressor::File;
# Single-file cache container

use strict;
use warnings;
use utf8;

use Encode;
use JavaScript::Minifier qw//;
use CSS::Minifier qw//;
use Mojo::Asset::File;
use Mojo::Util qw//;

sub new {
	my ($class, %hash) = @_;
	my $s = bless({}, $class);

	# Initialize 
	$s->{mojo_static} = $hash{config}->{mojo_static} || die('Not specified mojo_static');
	$s->{path_cache_dir} = $hash{config}->{path_cache_dir} || die('Not specified path_cache_dir');
	$s->{path_single_cache_dir} = $hash{config}->{path_single_cache_dir} || die('Not specified path_single_cache_dir');

	$s->{file_key} = undef;
	$s->{path_file} = $hash{path_file} || die('Not specified path_file'); # Path of raw file
	$s->{extension} = $hash{extension} || die('Not specified extension');
	$s->{is_minify} = $hash{is_minify} || 0;

	$s->{is_use_cache} = ($s->{is_minify}) ? 1 : 0;
	$s->{updated_at} = undef; # Updated_at of processed (epoch sec)
	$s->{content} = undef; # processed content
	$s->{path_cached_file} = undef;

	if(defined $s->{path_file} && $s->{is_use_cache}){
		$s->_load_file();
	}

	return $s;
}

# Generate the key of file
sub get_key {
	my $s = shift;
	if($s->{is_use_cache}){
		if(!defined $s->{file_key}){
			$s->{file_key} = Mojo::Util::sha1_sum( $s->{path_file} ).'.'.$s->{extension};
		}
		return $s->{file_key};
	} else {
		return;
	}
}

# Get the processed content
sub get_content {
	my $s = shift;
	# Check for update of source file
	$s->_load_file();
	return $s->{content};
}

# Get for updated_at
sub get_updated_at {
	my $s = shift;
	# Check for update of source file
	$s->_load_file();
	return $s->{updated_at};
}

# Get the path of file (raw)
sub get_raw_path {
	my $s = shift;
	return $s->{path_file};
}

# Processing the file
sub _process {
	my $s = shift;
	$s->_load_file();
	if($s->{is_minify}){
		$s->_minify();
	}
}

# Check and make the single cache directory
sub _check_cache_dir {
	my $s = shift;
	if(! -d $s->{path_single_cache_dir}){
		# Make the directory
		mkdir( $s->{path_single_cache_dir} ) || die("Can't make a directory: ".$s->{path_single_cache_dir});
	}
}

# Load content from the file and process
sub _load_file {
	my $s = shift;
	if(! $s->{is_use_cache}){
		my $asset;
		eval {
			$asset = $s->{mojo_static}->file($s->{path_file});
			my $updated_at = (stat($asset->path()))[9];
			if(!defined $s->{updated_at} || $s->{updated_at} < $updated_at){ # Is Updated
				$s->{content} = Encode::decode_utf8($asset->slurp());
				$s->{updated_at} = $updated_at;
			}
		}; if($@){ die ("Can't read static file: ". $s->{path_file} ."\n$@"); }
		return;
	}

	$s->_check_cache_dir();

	# Generate cache path
	$s->{path_cached_file} = $s->{path_single_cache_dir}.$s->get_key();

	# Load the file from cache
	if(defined $s->{path_cached_file}){
		eval{
			my $cache = Mojo::Asset::File->new( path => $s->{path_cached_file} );
			$s->{updated_at} = (stat($s->{path_cached_file}))[9];
			$s->{content} = $cache->slurp();
		};
	}

	# Load the file and check for update
	my ($asset, $updated_at, $raw_content);
	eval {
		$asset = $s->{mojo_static}->file($s->{path_file});
		$updated_at = (stat($asset->path()))[9];
		$raw_content = Encode::decode_utf8($asset->slurp());
	}; if($@){ die ("Can't read static file: ".$asset->path()."\n$@"); }

	# Process and cache
	if(!defined $s->{updated_at} || $s->{updated_at} < $updated_at){ # Is Updated
		$s->{content} = $raw_content;
		$s->{updated_at} = $updated_at;
		
		if($s->{is_minify}){
			# Process the file
			$s->_minify();
			# Cache to the file
			my $cache = Mojo::Asset::File->new();
			$cache->add_chunk( Encode::encode_utf8($s->{content}) );
			$cache->move_to( $s->{path_cached_file} );
		}
	}
}

# Minify the content
sub _minify {
	my $s = shift;

	if($s->{extension} eq 'js'){
		$s->{content} = JavaScript::Minifier::minify(input => $s->{content});
	} elsif($s->{extension} eq 'css'){
		$s->{content} = CSS::Minifier::minify(input => $s->{content});
	} else {
		die('Not supported file type');
	}
}

1;
__END__
=head1 NAME

Mojolicious::Plugin::StaticCompressor::File

=head1 SYNOPSIS

This is internal package that manipulate for single file.

Please see POD for L<Mojolicious::Plugin::StaticCompressor>.

L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor/blob/master/README.pod>

=head1 METHODS

=head2 new ( ... )

Initialize a instance for single file.

=head2 get_key ( )

Get a cache key of the file. (If necessary, generate it.)

=head2 get_content ( )

Get the processed content of the file.
(Check for updates of source files. And if necessary, update cache.)

=head2 get_updated_at ( )

Get te updated_at (epoch seconds) from of the file.
(Check for updates of source files. And if necessary, update cache.)

=head2 get_raw_path ( )

Get a path of the source file.

=head1 SEE ALSO

L<Mojolicious::Plugin::StaticCompressor> ( L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor> )

=head1 COPYRIGHT AND LICENSE

Please see POD for L<Mojolicious::Plugin::StaticCompressor>.

L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor/blob/master/README.pod>