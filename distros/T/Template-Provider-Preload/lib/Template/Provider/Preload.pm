package Template::Provider::Preload;

=pod

=head1 NAME

Template::Provider::Preload - Preload templates to save memory when forking

=head1 SYNOPSIS

  my $template = Template->new(
      LOAD_TEMPLATES => [
          Template::Provider::Preload->new(
              PRECACHE     => 1,
              PREFETCH     => '*.tt',
              INCLUDE_PATH => 'my/templates',
              COMPILE_DIR  => 'my/cache',
  
              # Parser options should go here instead of to the
              # parent Template constructor.
              INTERPOLATE  => 1,
              PRE_CHOMP    => 1,
          );
      ],
  );

=head1 DESCRIPTION

One of the nicer things that the Template Toolkit modules do in the default
L<Template::Provider> is provide two powerful caching features.

The first is to cache the result of the slow and expensive compilation
phase, storing the Perl version of the template in a specific cache
directory. This mechanism is disabled by default, and enabled with
the C<COMPILE_DIR> parameter.

The second is that the compiled templates will be cached in memory the
first time they are used, based on template path. This feature is enabled
by default and permitted to grow to infinite size. It can be limited or
disabled via the C<CACHE_SIZE> param.

The default cache strategy works just fine in a single-process application,
and in fact in many such cases is the optimum caching strategy.

However, the default cache strategy can perform horribly in several
situations relating to large-scale and high-demand applications.

B<Template::Provider::Preload> can be used to create caching strategies
that are more appropriate for heavily forking applications such as
clustered high-traffic mod_perl systems.

=head1 USE CASES

While B<Template::Provider::Preload> is useful in many high-forking
scenarios, we will use the (dominant) case of a forking Apache
application in all of the following examples. You should be able to
exchange all uses of terms like "Apache child" with your equivalent
interchangably.

=head2 High-Security Server

In some very high security environments, the web user will not have the
right to create any files whatsoever, including temporary files.

This prevents the use of the compilation cache, and the template update
checks in the provider greatly complicate the possibility of building
the cache in advance offsite.

By allowing all templates to be compiled to memory in advance, you can
use templates at their full speed without the penalty of parsing and
compiling every template once per Apache child process.

Most of the following cases also assume a well-control static production
environment, where the template content will not change (and a web server
restart is done each time a new version of the application is deployed).

=head2 Large Templates, Many Templates

Under the default cache strategy (with a compilation directory enabled)
the first Apache child that uses each template will compile and cache
the template. Each Apache child that uses the templates will then need
to separately load the compiled templates into memory.

With web servers often having 20 or 50 or 100 child processes each,
templates that expand into 10 meg of memory for a single process
(which can be quite possible with a reasonable number of templates) can
easily expand into a gigabyte of memory that contributes nothing other
than to eat into your more useful object or disk caches.

With large numbers of large templates on multi-core servers with many
many child processes, you can even put yourself in the situation of
needing to requisition additional web servers due to memory contraints,
rather than CPU constraints.

Memory saved by loading a template once instead of 100 times can be
retasked to enable higher throughput (by providing more children) or
reduced latency (by boosting various caches).

=head2 Networked Templates

In cluster environments where all front-end servers will use a common
back-end Network-Attached Storage to store the website, reducing the number,
frequency and size of disk interations (both reads and stats) is an
important element in reducing or eliminating disk contention and network
load on what is often a critical shared resource.

Reducing the number of template-related requests serves a triple purpose of
reducing the size, speed, capacity and cost of required networking
equipment, allowing additional front-end server growth with lower change of
requiring (highly disruptive) upgrades to central network or storage kit,
and eliminating high-latency network IO requests from the web pipeline.

By compiling and loading all of the common templates in advance into a
seperate pre-fork memory cache (hereafter "precache") you can create an
environment in which the individual Apache children will not need issue
network filesystem requests except in the case of rare and unusual website
requests that load rarely used templates.

This can be taken to the extreme by loading every possible template into
the precache, which will eliminate template entirely and enable more-unusual
tricks like allowing the web server to disconnect entirely from the
source of the templates.

=head1 FEATURES

B<Template::Provider::Preload> provides two additional caching features
that can be used on their own to implement the most common caching strategy,
or in combination with the default cache settings to allow for more varied
and subtle caching strategies.

=head2 Template Search and Compilation

B<Template::Provider::Preload> provides the C<prefetch> method that can be
used to search the template include path and compile/load templates in bulk.

The set of templates to load can be defined very flexibly, allowing you to
preload templates at various levels. Typical examples might be loading the
entire template library, loading only the common include templates (page
headers and footers etc), or loading all templates accessible by the public
while not loading rarely used staff or administration templates.

=head2 Secondary Pre-Fork Cache

B<Template::Provider::Preload> adds an optional third cache that sits
between the disk compilation cache and the run-time memory cache.

The precache is designed to cache templates in memory separately from
the run-time memory cache. Holding pre-fork templates in a separate
cache allows the normal cache to behave appropriately at run-time for
templates that aren't in the precache, without being distracted by the
precache entries and without having to stat the precache templates

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Params::Util       ();
use Template::Provider ();
use File::Find::Rule   ();
use Class::Adapter::Builder
	ISA      => 'Template::Provider',
	AUTOLOAD => 1;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}





#####################################################################
# Constructor

=pod

=head2 new

  my $provider = Template::Provider::Preload->new(
      PRECACHE     => 1,
      PREFETCH     => '*.tt',
      INCLUDE_PATH => 'my/templates',
      COMPILE_DIR  => 'my/cache',
  );

The C<new> constructor accepts all the same parameters as the underlying
L<Template::Provider> class, with two additions.

The C<PRECACHE> param indicates that the secondary prefetch cache should
be created and used for this provider. The precatch is not
size-constrained by the C<CACHE_SIZE> param, that option only affects
the default run-time cache.

The C<PREFETCH> param indicates that an immediate C<prefetch> request
should be made at constructor time to pre-populate the cache (the
precache if it exists, or the run-time cache otherwise) with a specified
set of templates.

The value of C<PREFETCH> can be either a single string or a
L<File::Find::Rule> object, which will be passed to prefetch.
Alternatively, if the C<PREFETCH> param is an C<ARRAY> reference,
the reference will be flattened to a list, allowing you to provide more
than one file type string to C<prefetch>.

Returns a L<Template::Provider::Preload> object, or throws an excpetion
(dies) on error.

=cut

sub new {
	my $class    = shift;
	my %param    = @_;
	my $precache = delete $param{PRECACHE};
	my $prefetch = delete $param{PREFETCH};

	# Create the provider as normal
	my $self = $class->SUPER::new(
		Template::Provider->new(%param),
	);

	# Create the precache if needed
	if ( $precache ) {
		$self->{PRECACHE} = {};
	}

	# Prefetch immediately if needed
	if ( defined $prefetch ) {
		my @args = Params::Util::_ARRAYLIKE($prefetch)
			? ( @$prefetch )
			: (  $prefetch );
		$self->prefetch( @args );
	}

	return $self;
}





#####################################################################
# Bulk Preloading

=pod

=head2 prefetch

  # Load all .tt templates into memory
  $provider->prefetch;
  
  # Load all .html and .eml templates into memory
  $provider->prefetch('*.html', '*.eml');
  
  # Load all templates inside a SVN checkout into memory
  use File::Find::Rule;
  use File::Find::Rule::VCS;
  $provider->prefetch(
      File::Find::Rule->ignore_svn->file->readable->ascii
  );

The C<prefetch> method is used to specify that a set of template
files should be immediately compiled (with the compiled templates
cached if possible) and then the compiled templates are loaded into
memory.

When used in combination with C<PRECACHE> the C<prefetch> method creates
a caching strategy where the template files will never be looked at once
the call to C<prefetch> has completed. Both positive (template found) and
negative (not found or error) results will be cached.

When filling the precache, the use of the internal cache will be
temporarily disabled to avoid polluting the run-time cache state.

Selection of the files to compile is done via a L<File::Find::Rule> search
across all C<INCLUDE_PATH> directories. If the same file exists within more
than one C<INCLUDE_PATH> directory, only the first one will be compiled.

In the canonical usage, the C<prefetch> method takes a single parameter,
which should be a L<File::Find::Rule> object. The method will call C<file>
and C<relative> on the filter you pass in, so you should consider the
C<prefetch> method to be destructive to the filter.

As a convenience, if the method is passed a series of strings, a new
rule object will be created and the strings will be used to specific the
required files to compile via a call to the C<name> method.

As a further convenience, if the method is passed no params, a default
filter will be created for all files ending in .tt.

Returns true on success, or throws an exception (dies) on error.

=cut

sub prefetch {
	my $self     = shift;
	my $object   = $self->_OBJECT_;
	my @names    = $self->_find(@_);
	my $precache = $self->{PRECACHE};
	if ( $precache ) {
		# Disable the internal cache while prefetching to prevent
		# prefetched documents from polluting the cache.
		my $size = $object->{SIZE};
		$object->{SIZE} = 0;

		# Fetch and add to the precache if not in it already
		foreach my $name ( @names ) {
			next if $precache->{$name};
			$precache->{$name} = [ $object->fetch($name) ];
		}

		# Enable the internal cache now that we're done
		$object->{SIZE} = $size;
	} else {
		# Just pull them to get them into the child's cache
		foreach my $name ( @names ) {
			$object->fetch($name);
		}
	}
	return 1;
}

sub _find {
	my $self   = shift;
	my $filter = $self->_filter(@_)->relative->file;
	my $paths  = $self->paths;
	my %seen   = ();
	return grep { not $seen{$_}++ } map { $filter->in($_) } @$paths;
}

sub _filter {
	my $self = shift;
	unless ( @_ ) {
		# Default filter
		return File::Find::Rule->name('*.tt')->file;
	}
	if ( Params::Util::_INSTANCE($_[0], 'File::Find::Rule') ) {
		return $_[0];
	}
	my @names = grep { defined Params::Util::_STRING($_) } @_;
	if ( @names == @_ ) {
		return File::Find::Rule->name(@names)->file;
	}
	Carp::croak("Invalid filter param");
}





#####################################################################
# Template::Provider Methods

sub fetch {
	my $self = shift;
	my $name = shift;

	# If caching and we get a name in the cache, return it
	if ( $self->{PRECACHE} and not ref $name ) {
		my $cached = $self->{PRECACHE}->{$name};
		return @$cached if $cached;
	}

	# Otherwise, hand off to the child
	return $self->_OBJECT_->fetch( $name, @_ );
}

1;

=pod

=head1 CAVEATS

The B<Template::Provider::Preload> precaching logic assumes a stable
production environment in which the template files will not be changed.

It is assumed that if a production release is made, then there will be
a server or application restart that allows the caches to be refilled
and then the children reforked.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-Preload>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Template>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
