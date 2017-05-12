package Tenjin;

# ABSTRACT: Fast templating engine with support for embedded Perl.

use strict;
use warnings;
use Carp;

use Tenjin::Context;
use Tenjin::Template;
use Tenjin::Preprocessor;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

our $USE_STRICT = 0;
our $ENCODING = 'UTF-8';
our $BYPASS_TAINT   = 1; # unset if you like taint mode
our $TEMPLATE_CLASS = 'Tenjin::Template';
our $CONTEXT_CLASS  = 'Tenjin::Context';
our $PREPROCESSOR_CLASS = 'Tenjin::Preprocessor';
our $TIMESTAMP_INTERVAL = 10;

=head1 NAME

Tenjin - Fast templating engine with support for embedded Perl.

=head1 SYNOPSIS

	use Tenjin;

	$Tenjin::USE_STRICT = 1;	# use strict in the embedded Perl inside
					# your templates. Recommended, but not used
					# by default.

	$Tenjin::ENCODING = "UTF-8";	# set the encoding of your template files
					# to UTF-8. This is the default encoding used
					# so there's no need to do this if your
					# templates really are UTF-8.

	my $engine = Tenjin->new(\%options);
	my $context = { title => 'Tenjin Example', items => [qw/AAA BBB CCC/] };
	my $filename = 'file.html';
	my $output = $engine->render($filename, $context);
	print $output;

=head1 DESCRIPTION

Tenjin is a very fast and full-featured templating engine, implemented in
several programming languages, among them Perl.

The Perl version of Tenjin supports embedded Perl code, nestable layout template,
inclusion of other templates inside a template, capturing parts of or the entire
template output, file and memory caching, template arguments and preprocessing.

The original version of Tenjin is developed by Makoto Kuwata. This CPAN
version is developed by Ido Perlmuter and differs from the original in a
few key aspects:

=over

=item * Code is entirely revised, packages are separated into modules, with
a smaller number of packages than the original version. In particular, the
Tenjin::Engine module no longer exists, and is now instead just the Tenjin
module (i.e. this one).

=item * Support for rendering templates from non-file sources (such as
a database) is added.

=item * Ability to set the encoding of your templates is added (Tenjin will decode
template files according to this encoding; by default, Tenjin will decode 

=item * HTML is encoded and decoded using the L<HTML::Entities> module,
instead of internally.

=item * The C<pltenjin> script is not provided, at least for now.

=back

To make it clear, the CPAN version of Tenjin might find itself diverting
a bit in the future from the original Tenjin's roadmap. Although my aim
is to be as compatible as possible (and this version is always updated
with features and changes from the original), I cannot guarantee it (but I'll
do my best). Please note that version 0.05 (and above) of this module is
NOT backwards compatible with previous versions.

=head2 A NOTE ABOUT ENCODING

When Tenjin opens template files, it will automatically decode their contents
according to the selected encoding (UTF-8 by default), so make sure your template
files are properly encoded. Tenjin also writes cache files of compiled template
structure. These will be automatically encoded according to the selected encoding.

When it comes to UTF-8, it might interest you to know how Tenjin behaves:

=over

=item 1. "UTF-8" is the default encoding used. If for some reason, either before
running C<< Tenjin->new() >> or during, you provide an alternate spelling (such
as "utf8" or "UTF8"), Tenjin will convert it to UTF-8.

=item 2. When reading files, Tenjin uses "<:encoding(UTF-8)", while when writing
files, Tenjin uses ">:utf8", as recommended by L<this article|https://secure.wikimedia.org/wikibooks/en/w/index.php?title=Perl_Programming/Unicode_UTF-8&oldid=2020796>.

=back

=head1 METHODS

=head2 new( \%options )

This creates a new instant of Tenjin. C<\%options> is a hash-ref
containing Tenjin's configuration options:

=over

=item * B<path> - Array-ref of filesystem paths where templates will be searched

=item * B<prefix> - A string that will be automatically prepended to template names
when searching for them in the path. Empty by default.

=item * B<postfix> - The default extension to be automtically appended to template names
when searching for them in the path. Don't forget to include the
dot, such as '.html'. Empty by default.

=item * B<cache> - If set to 1 (the default), compiled templates will be cached on the
filesystem (this means the template's code will be cached, not the completed rendered
output).

=item * B<preprocess> - Enable template preprocessing (turned off by default). Only
use if you're actually using any preprocessed Perl code in your templates.

=item * B<layout> - Name of a layout template that can be optionally used. If set,
templates will be automatically inserted into the layout template,
in the location where you use C<[== $_content ==]>.

=item * B<strict> - Another way to make Tenjin use strict on embedded Perl code (turned
off by default).

=item * B<encoding> - Another way to set the encoding of your template files (set to "UTF-8"
by default).

=back

=cut

sub new {
	my ($class, $options) = @_;

	my $self = {};
	foreach (qw[prefix postfix layout path cache preprocess templateclass strict encoding]) {
		$self->{$_} = delete $options->{$_};
	}
	$self->{cache} = 1 unless defined $self->{cache};
	$self->{init_opts_for_template} = $options;
	$self->{templates} = {};
	$self->{prefix} = '' unless $self->{prefix};
	$self->{postfix} = '' unless $self->{postfix};

	$Tenjin::ENCODING = $self->{encoding}
		if $self->{encoding};

	# if encoding is utf8, make sure it's spelled UTF-8 and not otherwise
	$Tenjin::ENCODING = 'UTF-8'
		if $Tenjin::ENCODING =~ m/^utf-?8$/i;

	$Tenjin::USE_STRICT = $self->{strict}
		if defined $self->{strict};

	return bless $self, $class;
}

=head2 render( $tmpl_name, [\%_context, $use_layout] )

Renders a template whose name is identified by C<$tmpl_name>. Remember that a prefix
and a postfix might be added if they where set when creating the Tenjin instance.

C<$_context> is a hash-ref containing the variables that will be available for usage inside
the templates. So, for example, if your C<\%_context> is C<< { message => 'Hi there' } >>, then you can use C<$message> inside your templates.

C<$use_layout> is a flag denoting whether or not to render this template into a layout
template (when doing so, the template will be rendered, then the rendered output will be
added to the context hash-ref as '_content', and finally the layout template will be rendered with the revised context and returned.

If C<$use_layout> is 1 (which is the default in case it is undefined),
then Tenjin will use the layout template that was set when creating the
Tenjin instance (via the 'layout' configuration option). If you want to use a different layout template (or if you haven't defined a layout
template when creating the Tenjin instance), then you must add the layout template's name
to the context as '_layout'. You can also just pass the layout template's name as C<$use_layout>, but C<< $_context->{_layout} >> has precedence.

If C<$use_layout> is 0, then a layout template will not be used,
even if C<< $_context->{_layout} >> is defined.

Note that you can nest layout templates as much as you like, but the only
way to do so is by setting the layout template for each template in the
nesting chain with C<< $_context->{_layout} >>.

Please note that by default file templates are cached on disk (with a '.cache') extension.
Tenjin automatically deprecates these cache files every 10 seconds. If you
find this value is too low, you can override the C<$Tenjin::TIMESTAMP_INTERVAL>
variable with your preferred value.

=cut

sub render {
	my ($self, $template_name, $_context, $use_layout) = @_;

	$_context ||= {};
	$_context->{'_engine'} = $self;

	# use a layout template by default
	$use_layout = 1 unless defined $use_layout;

	# start rendering the template, and if use_layout is true
	# then render the layout template with the original output, and
	# keep doing so if the layout template in itself is nested
	# inside other layout templates until there are no layouts left
	my $output;
	while ($template_name) {
		# get the template
		my $template = $self->get_template($template_name, $_context); # pass $_context only for preprocessing

		# render the template
		$output = $template->render($_context);

		# should we nest into a layout template?
		# check if $use_layout is 0, and if so bolt
		# check if $_context->{_layout} is defined, and if so use it
		# if not, and $use_layout is the name of a template, use it
		# if $use_layout is just 1, then use $self->{layout}
		# if no layout has been found, loop will finish
		last if defined $use_layout && $use_layout eq '0';
		$template_name = delete $_context->{_layout} || $use_layout;
		undef $use_layout; # undef so we don't nest infinitely
		$template_name = $self->{layout} if $template_name && $template_name eq '1';

		$_context->{_content} = $output;
	}

	# return the output
	return $output;
}

=head2 register_template( $template_name, $template )

Receives the name of a template and its L<Tenjin::Template> object
and stores it in memory for usage by the engine. This is useful if you
need to use templates that are not stored on the file system, for example
from a database.

Note, however, that you need to pass a template object who's already been
converted and compiled into Perl code, so if you have a template with a
certain name and certain text, these are the steps you will need to perform:

	# create a Tenjin instance
	my $tenjin = Tenjin->new(\%options);

	# create an empty template object
	my $template = Tenjin::Template->new();

	# compile template content into Perl code
	$template->convert($tmpl_content);
	$template->compile();

	# register the template with the Tenjin instance
	$tenjin->register_template($tmpl_name, $template);

=cut

sub register_template {
	my ($self, $template_name, $template) = @_;

	$template->{timestamp} = time;
	$self->{templates}->{$template_name} = $template;
}

=head1 INTERNAL METHODS

=head2 get_template( $template_name, $_context )

Receives the name of a template and the context object and tries to find
that template in the engine's memory. If it's not there, it will try to find
it in the file system (the cache file might be loaded, if present). Returns
the template's L<Tenjin::Template> object.

=cut

sub get_template {
	my ($self, $template_name, $_context) = @_;

	## get cached template
	my $template = $self->{templates}->{$template_name};

	## check whether template file is updated or not
	undef $template if ($template && $template->{filename} && $template->{timestamp} + $TIMESTAMP_INTERVAL <= time);

	## load and register template
	unless ($template) {
		my $filename = $self->to_filename($template_name);
		my $filepath = $self->find_template_file($filename);
		$template = $self->create_template($filepath, $template_name, $_context);  # $_context is passed only for preprocessor
		$self->register_template($template_name, $template);
	}

	return $template;
}

=head2 to_filename( $template_name )

Receives a template name and returns the proper file name to be searched
in the file system, which will only be different than C<$template_name>
if it begins with ':', in which case the prefix and postfix configuration
options will be appended and prepended to the template name (minus the ':'),
respectively.

=cut

sub to_filename {
	my ($self, $template_name) = @_;

	if (substr($template_name, 0, 1) eq ':') {
		return $self->{prefix} . substr($template_name, 1) . $self->{postfix};
	}

	return $template_name;
}

=head2 find_template_file( $filename )

Receives a template filename and searches for it in the path defined in
the configuration options (or, if a path was not set, in the current
working directory). Returns the absolute path to the file.

=cut

sub find_template_file {
	my ($self, $filename) = @_;

	my $path = $self->{path};
	if ($path) {
		my $sep = $^O eq 'MSWin32' ? '\\\\' : '/';
		foreach my $dirname (@$path) {
			my $filepath = $dirname . $sep . $filename;
			return $filepath if -f $filepath;
		}
	} else {
		return $filename if -f $filename;
	}
	my $s = $path ? ("['" . join("','", @$path) . "']") : '[]';
	croak "[Tenjin] $filename not found in path (path is $s).";
}

=head2 read_template_file( $template, $filename, $_context )

Receives a template object and its absolute file path and reads that file.
If preprocessing is on, preprocessing will take place using the provided
context object.

=cut

sub read_template_file {
	my ($self, $template, $filename, $_context) = @_;

	if ($self->{preprocess}) {
		if (! defined($_context) || ! $_context->{_engine}) {
			$_context ||= {};
			$_context->{'_engine'} = $self;
		}
		my $pp = $Tenjin::PREPROCESSOR_CLASS->new();
		$pp->convert($template->_read_file($filename));
		return $pp->render($_context);
	}

	return $template->_read_file($filename, 1);
}

=head2 cachename( $filename )

Receives a template filename and returns its standard cache filename (which
will simply be C<$filename> with '.cache' appended to it.

=cut

sub cachename {
	my ($self, $filename) = @_;

	return $filename . '.cache';
}

=head2 store_cachefile( $cachename, $template )

Receives the name of a template cache file and the corresponding template
object, and creates the cache file on disk.

=cut

sub store_cachefile {
	my ($self, $cachename, $template) = @_;

	my $cache = $template->{script};
	if (defined $template->{args}) {
		my $args = $template->{args};
		$cache = "\#\@ARGS " . join(',', @$args) . "\n" . $cache;
	}
	$template->_write_file($cachename, $cache, 1);
}

=head2 load_cachefile( $cachename, $template )

Receives the name of a template cache file and the corresponding template
object, reads the cache file and stores it in the template object (as 'script').

=cut

sub load_cachefile {
	my ($self, $cachename, $template) = @_;

	my $cache = $template->_read_file($cachename, 1);
	if ($cache =~ s/\A\#\@ARGS (.*)\r?\n//) {
		my $argstr = $1;
		$argstr =~ s/\A\s+|\s+\Z//g;
		my @args = split(',', $argstr);
		$template->{args} = \@args;
	}
	$template->{script} = $cache;
}

=head2 create_template( $filename, $_context )

Receives an absolute path to a template file and the context object, reads
the file, processes it (which may involve loading the template's cache file
or creating the template's cache file), compiles it and returns the template
object.

=cut

sub create_template {
	my ($self, $filename, $template_name, $_context) = @_;

	my $cachename = $self->cachename($filename);

	my $class = $self->{templateclass} || $Tenjin::TEMPLATE_CLASS;
	my $template = $class->new(undef, $template_name, $self->{init_opts_for_template});

	if (! $self->{cache}) {
		$template->convert($self->read_template_file($template, $filename, $_context), $filename);
	} elsif (! -f $cachename || (stat $cachename)[9] < (stat $filename)[9]) {
		$template->convert($self->read_template_file($template, $filename, $_context), $filename);
		$self->store_cachefile($cachename, $template);
	} else {
		$template->{filename} = $filename;
		$self->load_cachefile($cachename, $template);
	}
	$template->compile();

	return $template;
}

1;

=head1 SEE ALSO

The original Tenjin website is located at L<http://www.kuwata-lab.com/tenjin/>. In there check out
L<http://www.kuwata-lab.com/tenjin/pltenjin-users-guide.html> for detailed usage guide,
L<http://www.kuwata-lab.com/tenjin/pltenjin-examples.html> for examples, and
L<http://www.kuwata-lab.com/tenjin/pltenjin-faq.html> for frequently asked questions.

Note that the Perl version of Tenjin is referred to as plTenjin on the Tenjin website,
and that, as opposed to this module, the website suggests using a .plhtml extension
for the templates instead of .html (this is entirely your choice).

L<Tenjin::Template>, L<Catalyst::View::Tenjin>, L<Dancer::Template::Tenjin>.

=head1 CHANGES

Version 0.05 of this module broke backwards compatibility with previous versions.
In particular, the Tenjin::Engine module does not exist any more and is
instead integrated into this one. Templates are also rendered entirely
different (as per changes in the original tenjin) which provides much
faster rendering.

Upon upgrading to versions 0.05 and above, you MUST perform the following changes
for your applications (or, if you're using Catalyst, you must also upgrade
L<Catalyst::View::Tenjin>):

=over

=item * C<use Tenjin> as your normally would, but to get an instance
of Tenjin you must call C<< Tenjin->new() >> instead of the old method
of calling C<< Tenjin::Engine->new() >>.

=item * Remove all your templates cache files (they are the '.cache' files
in your template directories), they are not compatible with the new
templates structure and WILL cause your application to fail if present.

=back

Version 0.06 (this version) restored the layout template feature which was
accidentally missing in version 0.05, and the ability to call the utility
methods of L<Tenjin::Util> natively inside templates. You will want to
remove your templates' .cache files when upgrading to 0.6 too.

=head1 AUTHOR

Ido Perlmuter E<lt>ido at ido50.netE<gt>

Forked from plTenjin 0.0.2 by Makoto Kuwata (L<http://www.kuwata-lab.com/tenjin/>).

=head1 ACKNOWLEDGEMENTS

I would like to thank the following people for their contributions:

=over

=item * Makoto Kuwata

The original developer of Tenjin.

=item * John Beppu E<lt>beppu at cpan.orgE<gt>

For introducing me to Tenjin and helping me understand the way it's designed.

=item * Pedro Melo E<lt>melo at cpan.orgE<gt>

For helping me understand the logic behind some of the original Tenjin aspects
and helping me fix bugs and create tests.

=back

=head1 BUGS

    Please report any bugs or feature requests on the L<GitHub project page|https://github.com/ido50/Tenjin/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tenjin

You can also read the documentation online on L<metacpan|https://metacpan.org/pod/Tenjin>.

=head1 LICENSE AND COPYRIGHT

Tenjin is licensed under the MIT license.

	Copyright (c) 2007-2016 the aforementioned authors.

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

See http://dev.perl.org/licenses/ for more information.

=cut
