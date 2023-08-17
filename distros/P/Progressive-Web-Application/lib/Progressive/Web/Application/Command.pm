package Progressive::Web::Application::Command;

use Progressive::Web::Application;
use Module::Find;
use Text::Wrap qw//;

our ($pwa_link, $width, @MANIFEST_HELP, %TEMPLATE_FIELDS);
BEGIN {
	$width = 72;
	$Text::Wrap::columns = $width;
	$pwa_link = 'https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps';
	@MANIFEST_HELP = (
		{
			key => 'name',
			field => 'Application Full Name',
			info => 'The name member is a string that represents the name of the web application as it is usually displayed to the user (e.g., amongst a list of other applications, or as a label for an icon). name is directionality-capable, which means it can be displayed left-to-right or right-to-left based on the values of the dir and lang manifest members.',
			required => 1,
		},
		{
			key => 'short_name',
			field => 'Application Short Name',
			info => 'The short_name member is a string that represents the name of the web application displayed to the user if there is not enough space to display name (e.g., as a label for an icon on the phone home screen). short_name is directionality-capable, which means it can be displayed left-to-right or right-to-left based on the value of the dir and lang manifest members.',
		},
		{
			key => 'description',
			field => 'Description',
			info => 'The description member is a string in which developers can explain what the application does. description is directionality-capable, which means it can be displayed left to right or right to left based on the values of the dir and lang manifest members.',
		},
		{
			key => 'lang',
			field => 'Application Language',
			info => q|The lang member is a string containing a single language tag (https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang). It specifies the primary language for the values of the manifest's directionality-capable members, and together with  dir determines their directionality.|
		},
		{
			key => 'dir',
			field => 'Application Language Direction',
			info => 'The base direction in which to display direction-capable members of the manifest. Together with the lang member, it helps to correctly display right-to-left languages.',
			map => {
				1 => 'auto',
				2 => 'ltr',
				3 => 'rtl'
			}
		},
		{
			key => 'display',
			field => 'display',
			info => 'The display member is a string that determines the developers’ preferred display mode for the website. The display mode changes how much of browser UI is shown to the user and can range from "browser" (when the full browser window is shown) to "fullscreen" (when the app is full-screened). (fullscreen, standalone, minimal-ui, browser)',
			map => {
				1 => 'standalone',
				2 => 'minimal-ui',
				3 => 'fullscreen',
				4 => 'browser',
			}
		},
		{
			key => 'iarc_rating_id',
			field => 'International Age Rating Coalition (IARC) certification code',
			info => 'The iarc_rating_id member is a string that represents the International Age Rating Coalition (https://www.globalratings.com) certification code of the web application. It is intended to be used to determine which ages the web application is appropriate for.'
		},
		{
			key => 'orientation',
			field => 'Orientation',
			info => q|The orientation member defines the default orientation for all the website's top-level browsing contexts.|,
			map => {
				1 => 'any',
				2 => 'natural',
				3 => 'landscape',
				4 => 'landscape-primary',
				5 => 'landscape-secondary',
				6 => 'portrait',
				7 => 'portrait-primary',
				8 => 'portrait-secondary'
			}
		},
		{
			key => 'scope',
			field => 'Scope',
			info => q|The scope member is a string that defines the navigation scope of this web application's application context. It restricts what web pages can be viewed while the manifest is applied. If the user navigates outside the scope, it reverts to a normal web page inside a browser tab or window.|
		},
		{
			key => 'start_url',
			field => 'Start Path',
			info => q|The start_url member is a string that represents the start URL of the web application — the prefered URL that should be loaded when the user launches the web application (e.g., when the user taps on the web application's icon from a device's application menu or homescreen).|
		},
		{
			key => 'theme_color',
			field => 'Theme Colour',
			info => q|The theme_color member is a string that defines the default theme color for the application. This sometimes affects how the OS displays the site (e.g., on Android's task switcher, the theme color surrounds the site).|
		},
		{
			key => 'background_color',
			field => 'Background Colour',
			info => 'The background_color member defines a placeholeder background color for the application page to display before its stylesheet is loaded. This value is used by the user agent to draw the background color of a shortcut when the manifest is available before the stylesheet has loaded.'
		},
		{
			key => 'icons',
			field => 'Icons',
			info => q|The icons member specifies an array of objects representing image files that can serve as application icons for different contexts. For example, they can be used to represent the web application amongst a list of other applications, or to integrate the web application with an OS's task switcher and/or system preferences.|,
			map => {
				1 => 'Directory',
				2 => 'Generate'
			},
			options => {
				Directory => [{
					key => 'icons',
					field => 'Path',
					info => q|The directory path to retrieve the icons|
				}],
				Generate => [{
					key => 'file',
					field => 'Icon File',
					info => q|The path to the icon to be used to generate|
				},{
					key => 'outpath',
					field => 'Out Directory Path',
					info => q|The directory that the icons will be written|
				}]
			},
			required => 1
		},
	);
#	{
#		key => "prefer_related_applications",
#		field => 'Prefer Related Application',
#		info => 'The prefer_related_applications member is a boolean value that specifies that applications listed in related_applications should be preferred over the web application. If the prefer_related_applications member is set to true, the user agent might suggest installing one of the related applications instead of this web app. (t/f)'
#	},
#	{
#		key => 'related_applications',
#		field => 'Related Applications',
#		info => 'The related_applications field is an array of objects specifying native applications that are installable by, or accessible to, the underlying platform — for example, a native Android application obtainable through the Google Play Store. Such applications are intended to be alternatives to the manifest's website that provides similar/equivalent functionality — like the native app equivalent.',
#	},
#	{
#		key => 'screenshots',
#		field => 'Screenshots',
#		info => 'The screenshots member defines an array of screenshots intended to showcase the application. These images are intended to be used by progressive web app stores.'
#	},
#	{
#		key => 'categories',
#		field => 'Categories',
#		info => 'The categories member is an array of strings defining the names of categories that the application supposedly belongs to. There is no standard list of possible values, but the W3C maintains a list of known categories. (https://github.com/w3c/manifest/wiki/Categories)'
#	}
	%TEMPLATE_FIELDS = (
		push_button_selector => {
			key => 'push_button_selector',
			field => 'Push Button Selector',
			info => 'A selector for an HTML button used to install the application.',
			required => 1
		},
	 	scope => {
			key => 'scope',
			field => 'Scope',
			info => q|The scope member is a string that defines the navigation scope of this web application's application context. It restricts what web pages can be viewed while the manifest is applied. If the user navigates outside the scope, it reverts to a normal web page inside a browser tab or window.|,
			required => 1
		},
		cache_name => {
			key => 'cache_name',
			field => 'Cache Name',
			info => 'Control the cache using a versioned name. Each time you deploy you should increment/modify this value so that your endusers caches are cleared on their next visit.',
			required => 1,
		},
		offline_path => {
			key => 'offline_path',
			field => 'Offline Path',
			info => 'The offline path should be a fallback offline "response" the content type of this "response" is up to you and your application/use case.',
			required => 1,
		},
		precache_endpoint => {
			key => 'precache_endpoint',
			field => 'Precache Endpoint',
			info => 'An API endpoint that returns an JSON array containing a list of resources/endpoints to add to the precache.',
			required => 1,
		},
		files_to_cache => {
			key => 'files_to_cache',
			field => 'Files To Pre Cache',
			info => 'We can cache the HTML, CSS, JS, and any static files that make up the application shell in the install event of the service worker.',
			map => {
				1 => 'List',
				2 => 'Directory',
			},
			options => { # we probably want a way of doing both... but no energy left)))
				'List' => [
					{
						key => 'files_to_cache',
						list => 1,
						info => q|Manually curate a list of endpoints/resources to pre-cache|,
						field => 'File (type f to finalise list)'
					},
				],
				Directory => [{
					key => 'directory',
					field => 'Directory',
					info => q|The Directory your resources exist under|
				},{
					key => 'recurse',
					field => 'Recurse (n/y)',
					info => q|Should we recurse the directory|
				},{
					key => 'blacklist_regex',
					field => 'Blacklist Regex',
					info => q|Files that match this regex will be skipped|
				},{
					key => 'whitelist_regex',
					field => 'Whitelist Regex',
					info => q|Files that do not match this regex will be skipped|
				}]
			},
			required => 1
		}
	);
}

sub wrap { Text::Wrap::wrap("", "", $_[0]) }

sub say { print wrap $_[0] . "\n";}

sub spacer { print '=' x $width . "\n"; }

sub title {
	my $spacer = (($width - (length($_[0]) + 2)) / 2);
	print '=' x $spacer . ' ' . $_[0] . ' ' . '=' x $spacer . "\n";
}

sub user_input { my $input; chomp($input = <STDIN>); return $input; };

sub field {
	my ($field, $pwa, $meth) = @_;
	my $uf = $field->{field};
	$uf .= ' (Required)' if $field->{required};
	$uf .= stringify_map($field->{map}) if $field->{map};
	print wrap "$uf: ";
	my $value = user_input;
	if ($value =~ m/^info$/i) {
		say $field->{info};
		return field(@_);
	}
	if ($value) {
		if ($field->{map} && $value =~ m/^\d*$/) {
			$value = $field->{map}->{$value};
			if (!$value) {
				say 'Error: Invalid map value passed';
				field(@_);
			}
		}
		if ($field->{options}) {
			my $options = $field->{options}->{$value};
			if (!$options) {
				say 'Error: Invalid option';
				return field(@_);
			}
			for (@{$options}) {
				if ($_->{list}) {
					$value = [];
					while((my $input = field($_)) !~ m/^e$/i) {
						push @{$value}, $input;
					}
				} else {
					my $ovalue = field($_);
					if ($_->{key} eq $field->{key}) {
						$value = $ovalue;
					} else {
						$value = {} if !ref $value;
						$value->{$_->{key}} = $ovalue;
					}
				}
			}
		}
		if ($meth) {
			eval { $pwa->$meth($field->{key} => $value); };
			if ($@) {
				$@ =~ s/at lib.*$//;
				print 'Error: ' . $@;
				return field(@_);
			}
		}
		return $value;
	} else {
		if ($field->{required}) {
			say 'Error: This field is required';
			return field(@_);
		}
	}
}

sub interface {
	my $pwa = Progressive::Web::Application->new();
	spacer;
	title 'PWA Utility CL';
	say q|Howdy, you're about to use the Progressive::Web::Application utility Command line application|;
	say q|For more information on what a PWA follow this link|;
	say $pwa_link;
	spacer;

	title q|Settings|;
	say q|Relative to your current terminal window where is the root folder of your application (MyApp/root)|;
	field({
		key => "root",
		field => 'Root Directory',
		required => 1
	}, $pwa, 'set_root');
	say q|Is your application proxied to a path part AKA (localhost/my/app/*)|;
	field({
		key => "path",
		field => 'Proxy Path (leave blank if at root(/))',
	}, $pwa, 'set_pathpart');
	spacer;

	title q|PWA Manifest|;
	say q|The web app manifest provides information about a web application in a JSON text file,|
	. q| necessary for the web app to be downloaded and be presented to the user similarly to a|
	. q| native app (e.g., be installed on the homescreen of a device, providing users with|
	. q| quicker access and a richer experience).|;
	spacer;
	print q|Would you like to create a manifest? (n/y): |;
	if (user_input =~ m/y/i) {
		manifest($pwa);
		say 'Manifest: ' . $pwa->manifest(1);
	} else {
		say q|No manifest will be created|;
	}
	spacer;

	title q|PWA Service Worker|;
	say q|A service worker is a type of web worker.|
	. q| It's essentially a JavaScript file that runs separately from the main browser thread,|
	. q| intercepting network requests, caching or retrieving resources from the cache, and |
	. q|delivering push messages.|;
	spacer;
	print q|Would you like to create a service worker (n/y): |;
	if (user_input =~ m/y/i) {
		service_worker($pwa);
		say 'Templates';
	} else {
		say q|No service worker will be created|;
	}
	spacer;

	if ($pwa->has_params || $pwa->has_manifest) {
		title 'Compiling';
		say 'About to compile';
		$pwa->compile();
		say 'Compiled';
		title 'PWA CLA Complete';
		spacer;
	} else {
		title 'Nothing to compile - bailing';
	}
}

sub manifest {
	my $pwa = shift;
	say q|Okay, lets create the manifest.|
	. q| Please complete the following form if you need help for a field type 'INFO'.|
	. q| You can skip optional fields by leaving them blank and pressing ENTER.|;
	field($_, $pwa, 'set_manifest') for @MANIFEST_HELP;
	say q|Manifest form complete|;
}

sub service_worker {
	my $pwa = shift;
	my @avail = map {substr($_, rindex($_, ':') + 1) }
		grep { $_ !~ m/Base$/ } findsubmod Progressive::Web::Application::Template;
	print wrap 'Please select a template that you would like to use'
		. stringify_templates(@avail) . ': ';
	my $val = user_input;
	if (!$avail[$val]) {
		say 'Error: Invalid template selected';
		service_worker($pwa);
	}
	say q|Template has loaded.|
	. q| Please complete the following form if you need help for a field type 'INFO'.|
	. q| You can skip optional fields by leaving them blank and pressing ENTER.|;
	$pwa->set_template(template => $avail[$val]);
	my @required = $pwa->template->required_params;
	field($TEMPLATE_FIELDS{$_}, $pwa, 'set_params') for (@required);
	say q|Service worker form complete|;
}

sub stringify_templates {
	my @templates = @_;
	' (' . (join ", ", map {
		$_ . '=' . $templates[$_]
	} ( 0 .. $#templates )) . ')';
}

sub stringify_map {
	my $map = shift;
	' (' .
		(join ', ', map {  $_ . '=' . $map->{$_} } sort keys %{$map})
	.  ')';
}

1;
