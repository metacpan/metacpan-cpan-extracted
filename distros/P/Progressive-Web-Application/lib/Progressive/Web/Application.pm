package Progressive::Web::Application;
use 5.006;
use strict;
use warnings;
use Carp qw//;
use JSON;
use Colouring::In;
use Image::Scale;
use Cwd qw/abs_path/;
our $VERSION = '0.02';
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
					mkdir $1 or Carp::craok(qq/
						Cannot create path $1 $!
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
			close $fh && chomp($content);
			return $content;
		},
		remove_file => sub { $TOOL{remove_directory}->($TOOL{abs}->($_[0])); },
		read_directory => sub {
			my ($val, %opts) = $TOOL{parse_params}->(@_);
			$val = $TOOL{abs}->($val);
			$val =~ $TOOL{tainted};
			opendir(my $DIR, $1) or die "Cant open $1$!";
			my @files;
			for my $file (grep {$_ !~ /^\./} readdir($DIR)) {
				my $path = sprintf "%s/%s", $val, $file;
				$path =~ $opts{blacklist_regex} && next if $opts{blacklist_regex};
				$path =~ $opts{whitelist_regex} || next if $opts{whitelist_regex};
				push @files, $opts{recurse} && -d $path
					?  map {
						sprintf "%s/%s", $file, $_;
					} $TOOL{read_directory}->($path)
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
					cannot remove file $1$!
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
			my $img = Image::Scale->new($icon) || Carp::croak "Invalid file";
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
			my $img = Image::Scale->new($TOOL{abs}->($_[0])) || Carp::croak "Invalid file";
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
				$app->{$_} or Carp::croak(sprintf
					q|Missing required param %s in related_application %s|,
					$_,
					$TOOL{to_json}->($app)
				)
				for (qw/platform url/, ($app->{platform} || "") =~ m/play/i ? 'id' : ());
			}
			return $_[0];
		},
		iarc_rating_id => $TOOL{scalar_check}, # TODO parenting
		scope => $TOOL{scalar_check}, # TODO should validate a path
		screenshots => sub {
			$TOOL{array_check}->(@_);
			for my $screenshot (@{$_[0]}) {
				Carp::croak(q|screenshot is not a HASH|) unless ref $screenshot eq q|HASH|;
				$screenshot->{$_} or Carp::croak(sprintf
					q|Missing required param %s in screenshot %s|,
					$_,
					$TOOL{to_json}->($screenshot)
				)
				for (qw/src sizes type/);
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
	exists $args{$_} && do {$new->{$_} = $args{$_}} for qw/root pathpart/;
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
			or Carp::croak(sprintf q/Invalid key passed to setup manifest %s/, $key)
				and return;
		my $val = $validate->($args{$key}, $key, $self->{root}, $self->{pathpart});
		$self->{manifest}{$key} = $val;
	}
	$self->{manifest};
}

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

sub template { $_[0]->{template} }

sub templates { $_[0]->{template}->render($_[0]->{params}); }

sub compile {
	my ($self, $root) = @_;
	$root = $self->{root} || Carp::croak(
		q/No root directory provided to compile manifest and service worker/
	) unless $root;
	$TOOL{make_path}->($root);
	my %build = (
		($self->has_manifest ? (manifest => $self->manifest(1)) : ()),
		($self->has_params ? (templates => $self->templates()) : ()),
	);
	$TOOL{write_file}->(sprintf("%s/manifest.json", $root), $build{manifest}) if $build{manifest};
	if ($build{templates} && keys %{$self->{params}} > 1) {
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

Version 0.02

=cut

=head1 SYNOPSIS

# vim MyApp/pwa.pl

	use Progressive::Web::Application;

	my $pwa = Progressive::Web::Application->new({
		root => 'root',
		pathpart => 'payments',
		manifest => {
			name => 'Progressive Web Application Demo',
			short_name => 'PWA Demo",
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

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

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
