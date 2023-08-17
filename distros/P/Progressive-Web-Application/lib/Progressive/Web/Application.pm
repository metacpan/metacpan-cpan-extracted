package Progressive::Web::Application;
use 5.006;
use strict;
use warnings;
use Carp qw//;
use JSON;
use Colouring::In;
use Image::Scale;
use Cwd qw/abs_path/;
our $VERSION = '0.08';
our (%TOOL, %MANIFEST_SCHEMA);
BEGIN {
	%TOOL = (
		tainted => qr/^([\d\/\-\@\w.]+)$/,
		array_check => sub {
			my $ref = ref $_[0];
			Carp::croak(sprintf q/Value is not an ARRAY for field %s/, $_[1]) if !$ref || ref $_[0] ne 'ARRAY';
			return $_[0];
		},
		scalar_check => sub {
			Carp::croak(sprintf q/Value is not a scalar for field %s/, $_[1]) if ref $_[0];
			return $_[0];
		},
		colour_check => sub { Colouring::In->new($_[0])->toCSS; },
		JSON => JSON->new->utf8->pretty,
		to_json => sub { $TOOL{JSON}->encode($_[0]); },
		from_json => sub { return $TOOL{JSON}->decode($_[0]); },
		make_path => sub {
			my $path = abs_path();
			for (split '/', $_[0]) {
				$path .= "/$_";
				$path =~ $TOOL{tainted};
				if (! -d $1) {
					mkdir $1  or Carp::croak(qq/
						Cannot open file for writing $!
					/);
				}
			}
			return $path;
		},
		remove_abs => sub {
			my $abs = abs_path();
			$_[0] =~ s/$abs//;
			return $_[0];
		},
		abs => sub {
			return $_[0] if ($_[0] =~ m/^\//);
			return sprintf "%s/%s", abs_path(), $_[0];
		},
		write_file => sub {
			$TOOL{abs}->($_[0]) =~ $TOOL{tainted};
			open my $fh, '>', $1 or Carp::croak(qq/
				Cannot open file for writing $!
			/);
			print $fh $_[1];
			close $fh;
		},
		read_file => sub {
			$TOOL{abs}->($_[0])  =~ $TOOL{tainted};
			open my $fh, '<', $1 or Carp::croak(qq/
				Cannot open file for reading $!
			/);
			my $content = do { local $/; <$fh> };
			close $fh;
			chomp($content);
			return $content;
		},
		remove_file => sub { $TOOL{remove_directory}->($TOOL{abs}->($_[0])); },
		read_directory => sub {
			my ($val, %opts) = $TOOL{parse_params}->(@_);
			$val = $TOOL{abs}->($val);
			$val =~ $TOOL{tainted};
			opendir(my $DIR, $1) or die "Can't open $1$!";
			my @files;
			for my $file (grep {$_ !~ /^\./} readdir($DIR)) {
				my $path = sprintf "%s/%s", $val, $file;
				$path =~ $opts{blacklist_regex} && next if $opts{blacklist_regex};
				$path =~ $opts{whitelist_regex} || next if $opts{whitelist_regex};
				push @files, $opts{recurse} && -d $path
					?  map {
						sprintf "%s/%s", $file, $_;
					} $TOOL{read_directory}->($path, %opts)
					: $path;
			}
			closedir ($DIR) or die "Cant close $1$!";
			return @files;
		},
		remove_directory => sub {
			$TOOL{abs}->($_[0]) =~ $TOOL{tainted};
			if (-d $1) {
				my $d = $1;
				opendir(my $DIR, $1) or Carp::croak "Can't open $1$!";
				for my $file (grep { $_ !~ /^\./} readdir($DIR)) {
					my $path = sprintf "%s/%s", $_[0], $file;
					$TOOL{remove_directory}->($path);
				}
				closedir($DIR) or Carp::craok( "Can't close $1$!");
				rmdir($d);
			} else {
				unlink $1 or Carp::croak(qq/
					Cannot remove file $1$!
				/);
			}
			return 1;
		},
		valid_icon_sizes => { map {
			$_ => 1
		} "36x36", "48x48", "57x57", "60x60", "70x70", "72x72", "76x76",
			"96x96", "114x114", "120x120", "128x128", "150x150", "144x144",
			"152x152", "180x180", "192x192", "310x310" },
		valid_icon_types => { map {
			$_ => 1
		}  "image/png" },
		generate_icons => sub {
			my ($icon, %options) = $TOOL{parse_params}->(@_);
			Carp::croak('No initial icon passed to generate_icons') if !$icon;
			my $img = Image::Scale->new($icon);
			$options{outpath} = substr($icon, 0, rindex($icon, '/')) if !$options{outpath};
			$options{outpath} =~ s/\/$//;
			$TOOL{make_path}->($options{outpath});
			my @iconSizes = sort { $b->{width} <=> $a->{width} }
				map {
					my @s = split 'x', $_;
					{ width => $s[0] + 0, height => $s[0] + 0 }
				}  keys %{ $TOOL{valid_icon_sizes} };
			my @files;
			for my $size (@iconSizes) {
				$img->resize_gd_fixed_point({
					width => $size->{width},
					height => $size->{width},
					keep_aspect => 1
				});
				my $file = sprintf(
					'%s/%sx%s-%s.png',
					$options{outpath},
					$size->{width},
					$size->{height},
					$options{icon_name} || q|icon|
				);
				$TOOL{write_file}->(
					$file,
					$img->as_png()
				);
				push @files, {
					sizes => sprintf(q|%sx%s|, $size->{width}, $size->{height}),
					src => q|/| . $file,
					type => q|image/png|
				};
			}
			return @files;
		},
		identify_icon_size => sub {
			my $img = Image::Scale->new($TOOL{abs}->($_[0]));
			my $size = sprintf "%sx%s", $img->width(), $img->height();
			return $TOOL{valid_icon_sizes}->{$size} ? $size : undef;;
		},
		identify_icon_information => sub {
			my $root = shift;
			my @files;
			for my $file (@_) {
				my $type = sprintf( "image/%s", substr($file, rindex($file, q|.|) + 1));
				my $size;
				next unless ($TOOL{valid_icon_types}->{$type});
				next unless $size = $TOOL{identify_icon_size}->($file);
				$root ? $file =~ s/(.*$root)// : $TOOL{remove_abs}->($file);
				$file = q|/| . $file if $file !~ m/^\//;
				push @files, {
					src => $file,
					type => $type,
					sizes => $size
				};
			}
			return @files;
		},
		validate_icon_information => sub {
			for (qw/src sizes type/) {
				if (! defined $_[0]->{$_} ) {
					Carp::croak(
						sprintf
						q/Required field not passed for icon missing %s for %s/,
						$_,
						$TOOL{to_json}->($_[0])
					);
				}
				$TOOL{scalar_check}->($_[0]->{$_}, $_);
			}
			$_[0]->{src} = q|/| . $_[0]->{src} unless $_[0]->{src} =~ m/^\//;
			$TOOL{valid_icon_sizes}->{$_[0]->{sizes}}
				|| Carp::croak(
					sprintf
					q/Invalid size %s for icon %s/,
					$_[0]->{sizes},
					$TOOL{to_json}->($_[0])
				);
			$TOOL{valid_icon_types}->{$_[0]->{type}}
				|| Carp::croak(
					sprintf
					q/Invalid icon type %s for icon %s/,
					$_[0]->{types},
					$TOOL{to_json}->($_[0])
				);
			return $_[0];
		},
		parse_params => sub {
			return ( shift, (ref($_[0]) || "") eq q|HASH| ? %{$_[0]} : @_ );
		},
		identify_files_to_cache => sub {
			my ($directory, %options) = $TOOL{parse_params}->(@_);
			if (!$directory) {
				Carp::croak(
					q/no directory passed into identify_files_to_cache/
				);
			}
			my @files_to_cache;
			for my $dir (ref $directory ? @{$directory} : $directory) {
				push @files_to_cache, sort { $a cmp $b } map {
					$options{root} ? $_ =~ s/(.*$options{root})// : $TOOL{remove_abs}->($_);
					$_ = q|/| . $_ if $_ !~ m/^\//;
					$_ = sprintf("/%s%s", $options{pathpart}, $_) if $options{pathpart};
					$_;
				}  $TOOL{read_directory}->($dir, %options);
			}
			return @files_to_cache;
		},
		valid_orientation => {
			any => 1,
			natural => 1,
			landscape => 1,
			q|landscape-primary| => 1,
			q|landscape-secondary| => 1,
			portrait => 1,
			q|portrait-primary| => 1,
			q|portrait-secondary| => 1
		}
	);
	%MANIFEST_SCHEMA = (
		name => $TOOL{scalar_check},
		short_name => $TOOL{scalar_check},
		description => $TOOL{scalar_check},
		lang => $TOOL{scalar_check}, #TODO,
		dir => sub {
			$TOOL{scalar_check}->(@_);
			$_[0] =~ m/^(auto|ltr|rtl)$/;
			return $1 ? $_[0] : Carp::croak(sprintf q|Invalid display value passed %s|, $_[0]);
		},
		orientation => sub {
			$TOOL{scalar_check}->(@_);
			return $TOOL{valid_orientation}->{$_[0]} ? $_[0] : Carp::croak(sprintf q|Invalid orientation value passed %s|, $_[0]);
		},
		prefer_related_applications => sub { return (ref $_[0] ? ${$_[0]} : $_[0]) ? \1 : \0; },
		related_applications => sub {
			$TOOL{array_check}->(@_);
			for my $app (@{$_[0]}) {
				Carp::croak(q|related_applicaiton is not a HASH|) unless ref $app eq q|HASH|;
				for (qw/platform url/, ($app->{platform} || "") =~ m/play/i ? 'id' : ()) {
					Carp::croak(sprintf
						q|Missing required param %s in related_application %s|,
						$_,
						$TOOL{to_json}->($app)
					) unless $app->{$_};
				}
			}
			return $_[0];
		},
		iarc_rating_id => $TOOL{scalar_check}, # TODO parenting
		scope => $TOOL{scalar_check}, # TODO should validate a path
		screenshots => sub {
			$TOOL{array_check}->(@_);
			for my $screenshot (@{$_[0]}) {
				Carp::croak(q|screenshot is not a HASH|) unless ref $screenshot eq q|HASH|;
				map { 
					Carp::croak(sprintf
						q|Missing required param %s in screenshot %s|,
						$_,
						$TOOL{to_json}->($screenshot)
					) unless $screenshot->{$_};
				} qw/src sizes type/;
			}
			# TODO - once known to be fully supported...
			# Mechanize->screenshot
			# validate src sizes type can likely reuse icons
			return $_[0];
		},
		categories => $TOOL{array_check},
		start_url => $TOOL{scalar_check}, # TODO should validate a path
		icons => sub {
			my ($ref, @icons) = ref $_[0];
			push @icons, !$ref
				? $TOOL{identify_icon_information}->(
					$_[2], sort { $b cmp $a } $TOOL{read_directory}->($_[0])
				)
 				: $ref eq q|ARRAY|
					? map {
						 $MANIFEST_SCHEMA{icons}->($_);
					} @{$_[0]}
					: $ref eq q|HASH|
						? ($_[0]->{file}
							? $TOOL{generate_icons}->($_[0]->{file},
								root => $_[2], %{$_[0]}
							)
							: $TOOL{validate_icon_information}->($_[0])
						)
						: map { $TOOL{validate_icon_information}->($_) } $_[0]->(\%TOOL);
			if ($_[3]) {
				@icons = map {
					$_->{src} = q|/| . $_[3] . $_->{src} if $_->{src} !~ m/^\/$_[3]/;
					$_;
				} @icons;
			}
			return wantarray ? @icons : \@icons;
		},
		display => sub {
			$TOOL{scalar_check}->($_[0], q|display|);
			Carp::croak(sprintf
				q/Invalid display value passed %s must be one of standalone, minimal-ui, fullscreen or browser/, $_[0]
			) unless $_[0] =~ m/^(standalone|minimal\-ui|fullscreen|browser)$/;
			return $_[0];
		},
		background_color => $TOOL{colour_check},
		theme_color => $TOOL{colour_check},
		# TODO: once available https://developer.mozilla.org/en-US/docs/Web/Manifest/serviceworker
	);
}

sub new {
	my ($package, %args) = $TOOL{parse_params}->(@_);
	my $new = bless {}, $package;
	for (qw/root pathpart/) { $new->{$_} = $args{$_} if exists $args{$_}; }
	$new->set_manifest($args{manifest}) if $args{manifest};
	$new->set_params($args{params}) if $args{params};
	$new->set_template(%args);
	return $new;
}

sub set_template {
	my ($self, %args) = $TOOL{parse_params}->(@_);
	$self->{template_class} = sprintf(
		q|Progressive::Web::Application::Template::%s|,
		$args{template} || q|General|
	);
	eval "require $self->{template_class}" || Carp::croak $@;
	$self->{template} = $self->{template_class}->new();
}

sub set_pathpart { $_[0]->{pathpart} = $_[-1]; }

sub set_root { $_[0]->{root} = $_[-1]; }

sub has_manifest { $_[0]->{manifest} ? 1 : 0 }

sub manifest { $_[1] ? $TOOL{to_json}->($_[0]->{manifest}) : $_[0]->{manifest}; }

sub set_manifest {
	my ($self, %args) = $TOOL{parse_params}->(@_);
	for my $key (keys %args) {
		my $validate = $MANIFEST_SCHEMA{$key}
			or Carp::croak(sprintf q/Invalid key passed to setup manifest %s/, $key);
		my $val = $validate->($args{$key}, $key, $self->{root}, $self->{pathpart});
		$self->{manifest}{$key} = $val;
	}
	$self->{manifest};
}

sub clear_manifest { delete $_[0]->{manifest}; }

sub has_params { $_[0]->{params} ? 1 : 0 }

sub params { $_[1] ? $TOOL{to_json}->($_[0]->{params}) : $_[0]->{params}; }

sub set_params {
	my ($self, %args) = $TOOL{parse_params}->(@_);
	my $ftc = delete $args{files_to_cache};
	$self->{params} = {%{$self->{params} || {}}, %args};
	if ($ftc) {
		my %map = (
			ARRAY => sub { @{$ftc} },
			CODE => sub { @{$ftc->(\%TOOL)} },
			HASH => sub {
				$TOOL{identify_files_to_cache}->(
					$ftc->{directory},
					root => $self->{root},
					pathpart => $self->{pathpart},
					%{$ftc}
				);
			}
		);
		my $ref = ref $ftc;
		Carp::croak(q|currently set_params files_to_cache cannot handle | . $ref) unless $map{$ref};
		my @filesToCache = $map{$ref}->();
		unshift @filesToCache, $self->{params}{offline_path} if $self->{params}{offline_path};
		$self->{params}{files_to_cache} = \@filesToCache;
	}
	$self->{params}{cache_name} ||= q|Set-a-cache-name-v1|;
	$self->{params};
}

sub clear_params { delete $_[0]->{params}; }

sub template { $_[0]->{template} }

sub templates { $_[0]->{template}->render($_[0]->{params}); }

sub compile {
	my ($self, $root) = @_;
	$root ||= $self->{root};
	Carp::croak(
		q/No root directory provided to compile manifest and service worker/
	) unless $root;
	$TOOL{make_path}->($root);
	my %build = (
		($self->has_manifest ? (manifest => $self->manifest(1)) : ()),
		($self->has_params ? (templates => $self->templates()) : ()),
	);
	$TOOL{write_file}->(sprintf("%s/manifest.json", $root), $build{manifest}) if $build{manifest};
	if ($build{templates}) {
		for my $template (keys %{$build{templates}}) {
			$TOOL{write_file}->(
	 			sprintf("%s/%s", $root, $template),
				$build{templates}{$template}
			);
		}
	}
}

sub tools { return \%TOOL; }

sub manifest_schema { return \%MANIFEST_SCHEMA; }

__END__

=head1 NAME

Progressive::Web::Application - Utility for making an application 'progressive'

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

# vim MyApp/pwa.pl

	use Progressive::Web::Application;

	my $pwa = Progressive::Web::Application->new({
		root => 'root',
		pathpart => 'payments',
		manifest => {
			name => 'Progressive Web Application Demo',
			short_name => 'PWA Demo',
			icons => '/root/static/images/icons',
			start_url => '/',
			display => 'standalone',
			background_color => '#2b3e50',
			theme_color => '#2c3e50'
		},
		params => {
			offline_path => '/offline.html',
			cache_name => 'my-cache-name',
			files_to_cache  => [
				'/manifest.json',
				'/favicon.ico',
				'/static/css/bootstrap.min.css',
				'/static/css/lnation.css',
				...
			],
		}
	});

	$pwa->compile();

	...


=head1 DESCRIPTION

This module is a Utility for aiding you in creating Progressive Web Applications (PWA's). Progressive web apps use modern browser APIs along with traditional progressive enhancement strategy to create cross-platform applications. These apps work everywhere that a browser runs and provide several features that give them the same user experience advantages as native apps. 

PWAs should be discoverable, installable, linkable, network independent, progressive, re-engageable, responsive, and safe.

=head2 Discoverable

The eventual aim is that web apps should have better representation in search engines, be easier to expose, catalog and rank, and have metadata usable by browsers to give them special capabilities.

=head2 Installable

A core part of the apps experience is for users to have app icons on their home screen, that launch in a native container that feels integrated with the underlying platform.

=head2 Linkable

One of the most powerful features of the Web is to be able to link to an app at a specific URL - no app store needed, no complex installation process. This is how it has always been.

=head2 Network Independent

Can work when the network is unreliable, or even non-existent.

=head2 Progressive

Can be developed to provide a modern experience to fully capable browsers, and an acceptable (although not quite as shiny) experience in less capable browsers.

=head2 Re-engageable

One major advantage of native platforms is the ease with which users can be re-engaged by updates and new content, even when they aren't looking at the app or using their devices. Modern Web APIs allow us to do this too, using new technologies such as Service Workers for controlling pages, the Web Push API for sending updates straight from server to app via a service worker, and the Notifications API for generating system notifications to help engage users when they're not in the browser.

=head2 Responsive

Responsive web apps use technologies like media queries and viewport to make sure that their UIs will fit any form factor: desktop, mobile, tablet, or whatever comes next.

=head2 Safe

You can verify the true nature of a PWA by confirming that it is at the correct URL, whereas apps in apps stores can often look like one thing, but be another. Example - L<https://twitter.com/andreasbovens/status/926965095296651264>

=cut

=head1 Methods

=cut

=head2 new

Instantiate a new Progressive::Web::Application Object.

	Progressive::Web::Application->new();

=head3 options

=head4 root

The root(/) directory of your application, this is used to validate links and where any output from this module will be compiled/written.
	
	lnation:High lnation$ ls
	MyApp

	.......

	Progressive::Web::Application->new( 
		root => 'MyApp/root'
	);

=cut

=head4 pathpart

Is your application proxied to a path.

	https://localhost/admin/*

	.......

	Progressive::Web::Application->new(
		pathpart => 'admin'
	);

=cut

=head4 manifest 

A Hash reference of params to build the web app manifest. See manifest_schema for more information.

	Progressive::Web::Application->new(
		manifest => {
			name => 'Progressive Web Application Demo',
			short_name => 'PWA Demo',
			icons => '/root/static/images/icons',
			start_url => '/',
			display => 'standalone',
			background_color => '#2b3e50',
			theme_color => '#2c3e50'
		},
	);

=cut

=head4 template

A string that represents a template class. See Progressive::Web::Application::Template namespace for options.

	Progressive::Web::Application->new(
		template => 'General' # the default
	);

=cut

=head4 params

A Hash reference of params that are passed into the template. These are dynamic based upon the selected template
so check the documentation for more information on what is required. However the following have some addtional logic to aide you.

=over

=item cache_name

All templates will have a cache name, it is used to keep track of the version of the cache. Each release that has resource changes 
will require an update to the cache_name. This ensures your end users service workers clears the existing cache and re-fetch's the 
resources from your server.

	Progressive::Web::Application->new(
		params => {
			cache_name => 'my_cache_name_v2'
		}
	);

=item files_to_cache

You can pass in as an Array reference, Hash reference or Code block.

ARRAY - expects a list of files to be cached

	Progressive::Web::Application->new(
		params => {
			files_to_cache => [
				'resources/css/app.css',
				'resources/js/app.js',
				...
			]
		}
	);

HASH - params to be passed to $pwa->tools->{identify_files_to_cache}, see documentation for more information.

	Progressive::Web::Application->new(
		params => {
			files_to_cache => {
				directory => 'root/static',
				recurse => 1
			}
		}
	);

CODE - a custom code block that returns an Array references of files to cache.

	Progressive::Web::Application->new(
		params => {
			files_to_cache => sub {
				my $tool = @_;
				my @files = (
					$tool->{read_directory}->('root/static/js'),
					$tool->{read_directory}->('root/static/css'),
				);
				...
				return \@files;
			}
		}
	);

=back

=cut

=head2 set_template

Set the template class.

	$pwa->set_template(template => 'General');

=cut

=head2 set_pathpart

Set the pathpart of your application.

	$pwa->set_pathpart('somepath');

=cut

=head2 set_root

Set the root directory of your application.

	$pwa->set_root('MyApp/root');

=cut

=head2 has_manifest

Does the Progressive::Web::Applcation object have a manifest configured, returns true or false value (1|0).

	$pwa->has_manifest();

=cut

=head2 manifest

Return the configured manifest, if a true param is passed then this is returned as json.

	$pwa->manifest(1);

=cut

=head2 set_manifest

Set the manifest params see manifest_schema for full options.

	$pwa->set_manifest(
		name => 'Progressive Web Application Demo',
		short_name => 'PWA Demo',
		icons => '/root/static/images/icons',
		start_url => '/',
		display => 'standalone',
		background_color => '#2b3e50',
		theme_color => '#2c3e50'
	);

=cut

=head2 clear_manifest

Clear/Delete manifest from the object, this is usefull for when you call 'compile' to different outpaths multiple times within a script.

	$pwa->clear_manifest();

=cut

=head2 has_params

Does the Progressive::Web::Application have params configured, returns true or false value (1|0).

	$pwa->has_params();

=cut

=head2 params

Return the configured manifest, if a true param is passed then this is returned as json.

	$pwa->params(1);

=cut

=head2 set_params

Set the template params see the configured template for what is required.

	$pwa->set_params(
		offline_path => '/offline.html',
		cache_name => 'my-cache-name',
		files_to_cache  => [
			'/manifest.json',
			'/favicon.ico',
			'/static/css/bootstrap.min.css',
			'/static/css/lnation.css',
			...
		],
	);

=cut

=head2 clear_params

Clear/Delete params from the object, this is usefull for when you call 'compile' to different outpaths multiple times within a script.

	$pwa->clear_params();

=cut

=head2 template

Returns the template object.

	$pwa->template();

=cut

=head2 templates

Returns the rendered templates as a hash reference.

	$pwa->templates();

=cut

=head2 compile

This will write the manifest.json and any templates configured in the Template class into the root directory. You can optionally pass in a different path for the resources to be written. 

	$pwa->compile();

	...

	$pwa->compile('MyApp/root/resources');

=cut

=head2 manifest_schema 

=head3 name

Scalar - The applications 'full' name.

	$pwa->set_manifest(name => 'My Application Name');

The name member is a string that represents the name of the web application as it is usually displayed to the user (e.g., amongst a list of other applications, or as a label for an icon). name is directionality-capable, which means it can be displayed left-to-right or right-to-left based on the values of the dir and lang manifest members.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/name>

=head3 short_name

Scalar - The applications 'abbreviation' name

	$pwa->set_manifest(short_name => 'MyApp');

The short_name member is a string that represents the name of the web application displayed to the user if there is not enough space to display name (e.g., as a label for an icon on the phone home screen). short_name is directionality-capable, which means it can be displayed left-to-right or right-to-left based on the value of the dir and lang manifest members.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/short_name>

=head3 description

Scalar - Description of the application.

	$pwa->set_manifest(description => 'A description about my application');

The description member is a string in which developers can explain what the application does. description is directionality-capable, which means it can be displayed left to right or right to left based on the values of the dir and lang manifest members.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/description>

=head3 lang

Scalar - Language of the application 

	$pwa->set_manifest(lang => 'en-GB');

The lang member is a string containing a single language tag (L<https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang>). It specifies the primary language for the values of the manifest's directionality-capable members, and together with  dir determines their directionality.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/lang>

=head3 dir

Scalar - Direction of Lang (auto|ltr|rtl)

	$pwa->set_manifest(dir => 'ltr');

The base direction in which to display direction-capable members of the manifest. Together with the lang member, it helps to correctly display right-to-left languages.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/dir>

=head3 orientation

Scalar - orientation of the screen (any|natural|landscape|landscape-primary|landscape-secondary|portrait|portrait-primary|portrait-secondary)

	$pwa->set_manifest(orientation => 'natural');

The orientation member defines the default orientation for all the website's top-level browsing contexts. The orientation can be changed at runtime via the Screen Orientation API (L<https://developer.mozilla.org/en-US/docs/Web/API/Screen/orientation>)

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/orientation>

=head3 prefer_related_applications

Boolean - Prefer a related web application to recommend to 'install'.

	$pwa->set_manifest(prefer_related_applications => \1)

The prefer_related_applications member is a boolean value that specifies that applications listed in related_applications should be preferred over the web application. If the prefer_related_applications member is set to true, the user agent might suggest installing one of the related applications instead of this web app.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/prefer_related_applications>

=head3 related_applications

ArrayRef - A list of related application to recommend

	$pwa->set_manifest(related_applications => [
		{
			platform => "play",
			url => "https://play.google.com/store/apps/details?id=com.example.app1",
			id => "com.example.app1"
		}
	]);

The related_applications field is an array of objects specifying native applications that are installable by, or accessible to, the underlying platform - for example, a native Android application obtainable through the Google Play Store. Such applications are intended to be alternatives to the manifest's website that provides similar/equivalent functionality - like the native app equivalent.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/related_applications>

=head3 iarc_rating_id 

Scalar - International Age Rating Coalition (IARC) certification code

	$pwa->set_manifest(iarc_rating_id => 'e84b072d-71b3-4d3e-86ae-31a8ce4e53b7');

The iarc_rating_id member is a string that represents the International Age Rating Coalition (https://www.globalratings.com) certification code of the web application. It is intended to be used to determine which ages the web application is appropriate for.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/iarc_rating_id>

=head3 scope

Scalar - Applications scope

	$pwa->set_manifest(scope => '/app/');

The scope member is a string that defines the navigation scope of this web application's application context. It restricts what web pages can be viewed while the manifest is applied. If the user navigates outside the scope, it reverts to a normal web page inside a browser tab or window.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/scope>

=head3 screenshots

ArrayRef - Application screenshot previews

	$pwa->set_manifest(screenshots => [
		{
			src => "screenshot1.webp",
			sizes => "1280x720",
			type => "image/webp"
		}
	]);

The screenshots member defines an array of screenshots intended to showcase the application. These images are intended to be used by progressive web app stores.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/screenshots>

=head3 categories

ArrayRef - Application categories

	$pwa->set_manifest(categories => [
		"finance"
	]);

The categories member is an array of strings defining the names of categories that the application supposedly belongs to. There is no standard list of possible values, but the W3C maintains a list of known categories. (https://github.com/w3c/manifest/wiki/Categories)

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/categories>

=head3 start_url

Scalar - Start path the application will launch

	$pwa->set_manifest(start_url => '/home');

The start_url member is a string that represents the start URL of the web application - the prefered URL that should be loaded when the user launches the web application (e.g., when the user taps on the web application's icon from a device's application menu or homescreen).

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/start_url>

=head3 icons

Scalar - a directory path passed into $TOOL{identify_icon_information}

	$pwa->set_manifest(icons => 'root/static/images/icons');

HashRef - generate_icons or validate hash as an icon.

	$pwa->set_manifest(icons => {
		file => 'root/static/images/320x320-icon.png',
		outpath => 't/resources/icons',
	});

	...

	$pwa->set_manidest(icons => {
		sizes => '310x310',
		src => '/t/resources/320x320-icon.png',
		type => 'image/png'
	});

Code - Custom coderef that returns an array of icons

	$pwa->set_manidest(icons => sub {
		my $tool = shift;
	});

ArrayRef - itterate Scalar/Hash/Code

The icons member specifies an array of objects representing image files that can serve as application icons for different contexts. For example, they can be used to represent the web application amongst a list of other applications, or to integrate the web application with an OS's task switcher and/or system preferences.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/icons>

=head3 display

Scalar -  Browser display mode (standalone|minimal-ui|fullscreen|browser)

The display member is a string that determines the developers preferred display mode for the website. The display mode changes how much of browser UI is shown to the user and can range from "browser" (when the full browser window is shown) to "fullscreen" (when the app is full-screened). 

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/display>

=head3 background_color

Scalar - Background colour

The background_color member defines a placeholeder background color for the application page to display before its stylesheet is loaded. This value is used by the user agent to draw the background color of a shortcut when the manifest is available before the stylesheet has loaded.

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/background_color>

=head3 theme_color

Scalar - Theme colour

The theme_color member is a string that defines the default theme color for the application. This sometimes affects how the OS displays the site (e.g., on Android's task switcher, the theme color surrounds the site).

L<https://developer.mozilla.org/en-US/docs/Web/Manifest/theme_color>

=cut

=head2 tools

=head3 tainted

Returns a regex used to make paths/files taint safe.

	my $filename =~ $tools->{tainted};
	$1 # taint safe *\o/*

=head3 array_check

Validate the param is an Array, returns the param if valid and it will die/croak if invalid.

	my $arrayref = [qw/a b c/];
	$tool->{array_check}->($arrayref);

=head3 scalar_check

Validate the param is a Scalar (not a scalar reference), return the param if vaid and it will die/croak if invalid.

	my $string = 'abc';
	$tool->{scalar_check}->($string);

=head3 colour_check

Validate the param is a valid colour, returns the param if valid and it will die/croak if invalid.

	my $colour = '#000';
	$tool->{colour_check}->($colour);

=head3 JSON

Returns a JSON object with 'pretty' mode turned on.

	$tool->{JSON}->encode($ref);

=head3 to_json

Encodes the passed param as JSON.

	my $ref = { a => 'b' };
	$tool->{to_json}->($ref);

=head3 from_json

Decodes the passed json into a perl struct. 

	my $json = q|{"a":"b"}|;
	$tool->{from_json}->($ref);

=head3 make_path

Creates the path in the file system.

	$tool->{make_path}->('root/static/new/path');

=head3 remove_abs

Removes the absolute path from a file path.
	
	my $path = '/var/www/MyApp/root/static/images/icon/one.png';
	my $relative = $tool->{remove_abs}->($path);
	# 'root/static/images/icon/one.png'
	
=head3 abs

Converts a relative path into an absolute path.
	
	my $rel = 'root/static/images/icon/one.png';
	my $abs = $tool->{abs}->($rel);
	# '/var/www/MyApp/root/static/images/icon/one.png'

=head3 write_file

Creates/Writes a file.

	$tool->{write_file}->('root/static/images/icons/two.png', $png_data);	

=head3 read_file

Reads a file into memory.

	$tool->{read_file}->('root/static/images/icons/two.png');

=head3 remove_file

Removes/Deletes a file.

	$tool->{remove_file}->('root/static/images/icons/two.png');

=head3 read_directory

Reads a directory into an array of filenames. First argument should be the directory path, you can optionally pass the following options.

=over

=item recurse

Boolean to determine whether directories within the passed directory should be recursed.

=item blacklist_regex

A blacklist regex which will skip file paths that match it.

=item whitelist_regex

A whitelist regex which will skip file paths that do not match it.

=back

	$tool->{read_directory}->('root/static', 
		recurse => 1,
		blacklist_regex => qr/documentation/
	);

=head3 remove_directory

Removes/Deletes a directory.

	$tool->{remove_directory}->('root/static/images/icons');

=head3 valid_icon_sizes

Returns an Hash reference of known valid icon sizes, this is to cater for the various devices your application may be installed on.

	$tool->{valid_icon_sizes}->{'36x36'}; # valid
	$tool->{valid_icon_sizes}->{'1000x1000'}; # invalid

=head3 vaid_icon_types

Returns an Hash reference of currently supported icon types.

	$tool->{valid_icon_types}->{'image/png'};

=head3 generate_icons

Accepts an path to an icon and generates an icon for each of the valid_icon_sizes. You can optionally pass the following options.

=over

=item outpath

The directory the icons will be generated/written too (default is the directory of the original icon).

=item icon_name

The suffix that will applied to the icon name (default is 'icon')

=back

	$tool->{generate_icons}->('root/static/images/one.png', 
		outpath => 'root/static/images/icons'
	);

=head3 identify_icon_size

Identify an icons size and validate tagains valid_icon_sizes.

	$tool->{identify_icon_size}->('root/static/images/icon/my-icon.png');

=head3 identify_icon_information

Identify icon information from a passed file.

	$tool->{identify_icon_size}->('root', 'root/static/images/icon/my-icon.png');
	
	# {
	#	src => '/static/images/icon/my-icon.png',
	#	type => 'image/png',
	#	sizes => '36x36'
	# }

=head3 validate_icon_information

Validate a passed hashref is a valid 'icon' definition.

	my $icon = {
		src => '/static/images/icon/my-icon.png',
		type => 'image/png',
		sizes => '36x36'
	};
	$tool->{validate_icon_information}->($icon);

=head3 parse_params

Parse params, from a hash reference into a hash 'list'.

	my ($self, %hash) = $tool->{parse_params}->($self, { a => "b" });
	my ($self, %hash) = $tool->{parse_params}->($self, a => "b");

=head3 identify_files_to_cache

Returns a list of files/resources to cache. Accepts a directory or an Arrayref of directorys and optionally 
params that are passed to $tool{reaD_directory} see documentation for more information.

	my @files_to_cache = $tool->{identify_files_to_cache}->([
		'root/static/js',
		'root/static/css',
		'root/static/images'
	]);

=head3 valid_orientation

Returns an Hash reference of known orientations.

	$tool->{valid_icon_sizes}->{'landscape'}; # valid
	$tool->{valid_icon_sizes}->{'introverted'}; # invalid

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-progressive-web-application at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Progressive-Web-Application>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Progressive::Web::Application

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Progressive-Web-Application>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Progressive-Web-Application>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Progressive-Web-Application>

=item * Search CPAN

L<http://search.cpan.org/dist/Progressive-Web-Application/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Progressive::Web::Application
