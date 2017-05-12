package Mojolicious::Plugin::StaticCompressor;
use Mojo::Base 'Mojolicious::Plugin';

use warnings;
use strict;
use utf8;
our $VERSION = '1.0.0';

use Encode qw//;
use File::Find qw//;
use FindBin;
use Mojo::IOLoop;

use Mojolicious::Plugin::StaticCompressor::Container;

our $static;			# Instance of Mojo::Asset
our %containers;		# Hash of Containers
our $config;			# Hash-ref (Configuration items)

sub register {
	my ($self, $app, $conf) = @_;
	
	# Initilaize
	%containers = ();
	$static = $app->static;
	$config = _load_options( $app, $conf );

	# Add "js" helper
	$app->helper(js => sub {
		my $self = shift;
		my @file_paths = _generate_list( (@_) );;
		return _generate_import('js', 1, \@file_paths);
	});

	# Add "css" helper
	$app->helper(css => sub {
		my $self = shift;
		my @file_paths = _generate_list( (@_) );;
		return _generate_import('css', 1, \@file_paths);
	});

	# Add "js_nominify" helper
	$app->helper(js_nominify => sub {
		my $self = shift;
		my @file_paths = _generate_list( (@_) );;
		return _generate_import('js', 0, \@file_paths);
	});

	# Add "css_nominify" helper
	$app->helper(css_nominify => sub {
		my $self = shift;
		my @file_paths = _generate_list( (@_) );;
		return _generate_import('css', 0, \@file_paths);
	});

	unless($config->{is_disable}){ # Enable

		# Check the cache directory
		if(!-d $config->{path_cache_dir}){
			mkdir $config->{path_cache_dir};
		}
		
		# Add hook
		$app->hook(
			before_dispatch => sub {
				my $self = shift;
				if($self->req->url->path->contains('/'.$config->{url_path_prefix})
					&& $self->req->url->path =~ /\/$config->{url_path_prefix}\/(.+)$/){
					my $container_key = $1;
					
					eval {
						my $cont = Mojolicious::Plugin::StaticCompressor::Container->new(
							key => $container_key,
							config => $config,
						);

						if(!defined $containers{$cont->get_key()}){
							$containers{$cont->get_key()} = $cont;
						}
						
						$self->render( text => $cont->get_content(), format => $cont->get_extension() );
					};

					if($@){
						$self->render( text => $@, status => 400 );
					}
				}
			}
		);

		# Automatic cleanup
		_cleanup_old_files();

		# Start background loop
		if($config->{is_background}){
			_start_background_loop();
		}
	}
}

# Load the options
sub _load_options {
	my ($app, $option) = @_;
	my $config = {};

	# Disable
	my $disable = $option->{disable} || 0;
	my $disable_on_devmode = $option->{disable_on_devmode} || 0;
	$config->{is_disable} = ($disable eq 1 || ($disable_on_devmode eq 1 && $app->mode eq 'development')) ? 1 : 0;

	# Debug
	$config->{is_debug} = $option->{is_debug} || 0;

	# Prefix
	my $prefix = $option->{url_path_prefix} || 'auto_compressed';
	$config->{url_path_prefix} = $prefix;

	# Path of cache directory
	$config->{path_cache_dir} = $option->{file_cache_path} || $FindBin::Bin.'/'.$prefix.'/';
	$config->{path_single_cache_dir} = $config->{path_cache_dir}.'single/';

	# Background processing
	$config->{is_background} = $option->{background} || 0;
	$config->{background_interval_sec} = $option->{background_interval_sec} || 5;

	# Automatic cleanup
	$config->{is_auto_cleanup} = $option->{auto_cleanup} || 1;

	# Expires seconds for automatic cleanup
	$config->{auto_cleanup_expires_sec} = $option->{auto_cleanup_expires_sec} || 60 * 60 * 24 * 7; # 7days

	# Others
	$config->{mojo_static} = $static;

	return $config;
}

sub _generate_import {
	my ($extension, $is_minify, $path_files_ref) = @_;

	if($config->{is_disable}){
		return Mojo::ByteStream->new( _generate_import_raw_tag( $extension, $path_files_ref ) );
	}

	my $cont = Mojolicious::Plugin::StaticCompressor::Container->new(
		extension => $extension,
		is_minify => $is_minify,
		path_files_ref => $path_files_ref,
		config => $config,
	);

	if(defined $containers{$cont->get_key()}){
		$containers{$cont->get_key()}->update();
	} else {
		$containers{$cont->get_key()} = $cont;
	}

	return Mojo::ByteStream->new( _generate_import_processed_tag( $extension, "/".$config->{url_path_prefix}."/".$cont->get_key() ) );
}

# Generate of import HTML-tag for processed
sub _generate_import_processed_tag {
	my ($extension, $url) = @_;
	if ($extension eq 'js'){
		return "<script src=\"$url\"></script>\n";
	} elsif ($extension eq 'css'){
		return "<link rel=\"stylesheet\" href=\"$url\">\n";
	}
}

# Generate of import HTML-tag for raw
sub _generate_import_raw_tag {
	my ($extension, $urls_ref) = @_;
	my $tag = "";
	if ($extension eq 'js'){
		foreach(@{$urls_ref}){
			$tag .= "<script src=\"$_\"></script>\n";
		}
	} elsif ($extension eq 'css'){
		foreach(@{$urls_ref}){
			$tag .= "<link rel=\"stylesheet\" href=\"$_\">\n";
		}
	}
	return $tag;
}

# Start background process loop
sub _start_background_loop {
	my $id = Mojo::IOLoop->recurring( $config->{background_interval_sec} => sub {
		foreach my $key (keys %containers){
			if( $containers{$key}->update() ){
				warn "[StaticCompressor] Cache updated in background - $key";
			}
		}
	});
}

# Cleanup
sub _cleanup_old_files {
	File::Find::find(sub {
		my $path = $File::Find::name;
		my $now = time();
		if( -f $path && $path =~ /^(.*)\.(js|css)$/ ){
			my $updated_at = (stat($path))[9];
			if($config->{auto_cleanup_expires_sec} < ($now - $updated_at)){
				warn "DELETE: $path";
				#unlink($config->{path_cache_dir}) || die("Can't delete old file: $path");
			}
		}
	}, $config->{path_cache_dir});
}

#Generate one dimensional array 
sub _generate_list{
	my @temp = @_;
	my @file_paths;
	while (@temp) {
		my $next = shift @temp;
		if (ref($next) eq 'ARRAY') {
			unshift @file_paths, @$next;
		}
		else {
		    push @file_paths, $next;
		}
	}
	return @file_paths;
}

1;
__END__
=head1 NAME

Mojolicious::Plugin::StaticCompressor - Automatic JS/CSS minifier & compressor for Mojolicious

=head1 SYNOPSIS

Into the your Mojolicious application:

  sub startup {
    my $self = shift;

    $self->plugin('StaticCompressor');
    ~~~

(Also, you can read the examples using the Mojolicious::Lite, in a later section.)

Then, into the template in your application:

  <html>
  <head>
    ~~~~
    <%= js '/foo.js', '/bar.js' %> <!-- minified and combined, automatically -->
    <%= css '/baz.css' %> <!-- minified, automatically -->
    ~~~~
  </head>

However, this module has just launched development yet. please give me your feedback.

=head1 DESCRIPTION

This Mojolicious plugin is minifier and compressor for static JavaScript file (.js) and CSS file (.css).

=head1 INSTALLATION (from GitHub)

  $ git clone git://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor.git
  $ cpanm ./p5-Mojolicious-Plugin-StaticCompressor

=head1 METHODS

Mojolicious::Plugin::StaticCompressor inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

Register plugin in L<Mojolicious> application.

=head1 HELPERS

You can use these helpers on templates and others.

=head2 js $file_path [, ...]

Example of use on template file:

  <%= js '/js/foo.js' %>

This is just available as substitution for the 'javascript' helper (built-in helper of Mojolicious).

However, this helper will output a HTML-tag including the URL which is a compressed files. 

  <script src="/auto_compressed/124015dca008ef1f18be80d7af4a314afec6f6dc"></script>

When this script file has output (just received a request), it is minified automatically.

Then, minified file are cached in the memory.

=head3 Support for multiple files

In addition, You can also use this helper with multiple js-files:

  <%= js '/js/foo.js', '/js/bar.js' %>

In this case, this helper will output a single HTML-tag.

but, when these file has output, these are combined (and minified) automatically.

=head2 css $file_path [, ...]

This is just available as substitution for the 'stylesheet' helper (built-in helper of Mojolicious).

=head2 js_nominify $file_path [, ...]

If you don't want Minify, please use this.

This helper is available for purposes that only combine with multiple js-files.

=head2 css_nominify $file_path [, ...]

If you don't want Minify, please use this.

This helper is available for purposes that only combine with multiple css-files.

=head1 CONFIGURATION

You can set these options when call the plugin from your application.

=head2 disable_on_devmode

You can disable a combine (and minify) when running your Mojolicious application as 'development' mode (such as a running on  the 'morbo'), by using this option:

  $self->plugin('StaticCompressor', disable_on_devmode => 1);

(default: 0 (DISABLE))

=head2 url_path_prefix

You can set the prefix of directory path which stores away a automatic compressed (and cached) file.

The directory that specified here, will be made automatically.

(default: "auto_compressed")

=head2 background

You can allow background processing to this plugin. (This option is EXPERIMENTAL.)

If this option is disabled, a delay may occur in front-end-processing because this module will re-process it when static file has re-write.

This option will be useful to prevent it with automatic background processing.

(default: 0 (DISABLE))

=head2 background_interval_sec

When you enable "background", this option is available.

(default:  604800 sec (7 days))

=head2 auto_cleanup

This option provides automatic clean-up of old cache file.

(default: 1 (ENABLE))

=head2 auto_cleanup_expires_sec

When you enable "auto_cleanup", this option is available.

(default:  604800 sec (7 days))

=head1 KNOWN ISSUES

=over 4

=item * Support for LESS and Sass.

=back

Your feedback is highly appreciated!

https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor/issues

=head1 EXAMPLE OF USE

Prepared a brief sample app for you, with using Mojolicious::Lite:

example/example.pl

  $ morbo example.pl

Let's access to http://localhost:3000/ with your browser.

=head1 REQUIREMENTS

=over 4

=item * Mojolicious v3.8x or later (Operability Confirmed: v3.88, v4.25)

=item * Other dependencies (cpan modules).

=back

=head1 SEE ALSO

L<https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor>

L<Mojolicious>

L<CSS::Minifier>

L<JavaScript::Minifier>

=head1 CONTRIBUTORS

Thank you to:

=over 4

=item * jakir-hayder L<https://github.com/jakir-hayder>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Masanori Ohgita (http://ohgita.info/).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Thanks, Perl Mongers & CPAN authors. 
