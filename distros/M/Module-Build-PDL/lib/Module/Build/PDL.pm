package Module::Build::PDL;
use base 'Module::Build';
use PDL::Core::Dev;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

# To add a new property, you would call
# __PACKAGE__->add_property(property_name => $defaults);

# For build_elements and include_dirs, M::B::Base has these calls:
# __PACKAGE__->add_property(build_elements => [qw(PL support pm xs share_dir pod script)]);
# __PACKAGE__->add_property(include_dirs => []);

# Our goal is to put pd ahead of pm and xs, since pd files create pm and xs files,
# and to include the necessary PDL include files and linker options. This means we
# must change the default build_elements, include_dirs, and extra_linker_flags.

=begin didntwork

# The first shot might be to simply overwrite them with our own package's
# default properties.  We should be able to do this because M::B::PDL is a derived
# class, and although add_property guards against overWRITING properties, it shouldn't
# have trouble with us overRIDING the base class's property:
__PACKAGE__->add_property(build_elements => [qw(PL support pd pm xs share_dir pod script)]);
__PACKAGE__->add_property(include_dirs => [PDL::Core::Dev::whereami_any().'/Core']);
__PACKAGE__->add_property(extra_linker_flags => [$PDL::Config{MALLOCDBG}->{libs}]);

# Unfortunately, that didn't work.  I'm not entirely sure why.

=end didntwork

=cut

# My second shot is to create a M::B::PDL constructor that simply
# creates a M::B object that has been appropriately tweaked.
sub new {
	my $class = shift;
	# Build the M::B object in the usual way:
	my $self = $class->SUPER::new(@_);
	
	# Override some of the stuff important for PDL:
	$self->build_elements([qw(PL support pd pm xs share_dir pod script)]);
	$self->include_dirs([PDL::Core::Dev::whereami_any().'/Core']);
	# Only add the linker flags if they are defined.  Otherwise M::B
	# adds an undef to the linker arg list, which confuses the system
	if ($PDL::Config{MALLOCDBG}->{libs}) {
		$self->extra_linker_flags($PDL::Config{MALLOCDBG}->{libs})
	}
	
	# All done:
	return $self;
}

# Allow the person installing to force a PDL::PP rebuild
sub ACTION_forcepdlpp {
	my $self = shift;
	$self->log_info("Forcing PDL::PP build\n");
	$self->{FORCE_PDL_PP_BUILD} = 1;
	$self->ACTION_build();
}

# largely based on process_PL_files and process_xs_files in M::B::Base
sub process_pd_files {
	my $self = shift;
	# Get all the .pd files in lib
	my $files = $self->rscan_dir('lib', qr/\.pd$/);
	# process each in turn
	$self->process_pd($_) foreach (@$files);
}

sub process_pd {
	# Based heavily on process_xs
	my ($self, $file) = @_;
	
	# Remove the .pd extension to get the build file prefix, which
	# says where the .xs and .pm files should be placed when we run
	# PDL::PP on the .pd file
	(my $build_prefix = $file) =~ s/\.[^.]+$//;
	# Figure out the file's lib-less prefix, which tells perl where it
	# will be installed _within_ lib:

	(my $prefix = $build_prefix) =~ s|.*lib/||;
	# Build the module name (Surely there's a M::B function for this?)
	(my $mod_name = $prefix) =~ s|/|::|g;
	
	# see sub run_perl_command (yet undocumented)
	# PDL::PP's import argument are, in order:
	# Module name -> for example, PDL::Graphics::PLplot
	# Package name -> used in package line of the .pm file; for our purposes,
	#     this is identical to Module name.
	# Prefix -> the extensionless file name, PDL/Graphics/PLplot
	#    .pm and .xs extensions will be added to this when the files are
	#    produced, so this should include a lib/ prefix
	# Callpack -> an optional argument used for the XS PACKAGE keyword;
	#    if left blank, it will be identical to the module name
	my $PDL_arg = "-MPDL::PP qw[$mod_name $mod_name $build_prefix]";

	# Both $self->up_to_date and $self->run_perl_command are undocumented
	# so they could change in the future:
	$self->run_perl_command([$PDL_arg, $file])
		if ($self->{FORCE_PDL_PP_BUILD}
			or not $self->up_to_date($file, ["$build_prefix.pm", "$build_prefix.xs"]));
	
	$self->add_to_cleanup("$build_prefix.pm", "$build_prefix.xs");
	# Add the newly created .pm and .xs files to the list of such files?
	# No, because the current build process looks for all such files and
	# processes them, and it doesn't create that list until it's actually
	# processing the .pm and .xs files.
}

# working here
# Consider overriding the process_xs command so that if it's a normal xs file
# it just calls the SUPER method, but if the .xs file has an associated .pd
# file, it compiles it with the correct typemap, indludes, and libraries.

1; # Magic true value required at end of module
__END__

=head1 NAME

Module::Build::PDL - A Module::Build class for building PDL projects.


=head1 VERSION

This document describes Module::Build::PDL version 0.0.3.


=head1 SYNOPSIS

    use strict;
    use warnings;
    use Module::Build::PDL;
    
    my $builder = Module::Build::PDL->new(
        dist_name           => 'PDL-My-Mod',
        license             => 'perl',
        dist_author         => 'Your Name <yourname@example.com>',
        dist_version_from   => 'lib/PDL/My/Mod.pd',
        requires => {
            'Test::More' => 0,
            'PDL'        => 0,
        },
        add_to_cleanup      => [ 'PDL-My-Mod-*' ],
    );
    
    $builder->create_build_script();

  
=head1 DESCRIPTION

Module::Build::PDL is to PDL distributions what Module::Build is to most
perl distributions.  The only difference between the two (at the moment)
is that Module::Build::PDL knows how to handle .pd files (files that
use PDL::PP to generate compiled PDL functions).

Although I should probably give a basic tutorial here at some point,
for now I will simply tell you to refer to L<Module::Build> for an
explanation of how to use C<Build> files and L<Module::Build::Authoring>
for an explanation of how to use the module itself in your own
distributions.

Note that C<Module::Build::PDL> includes an additional action:
C<forcepdlpp>. This will force your .pd files to be rebuilt, which is
handy if they have an external dependency that has changed. To use
this, simpy issue the following command:

 $ ./Build forcepdlpp

See L</CONFIGURATION AND ENVIRONMENT> below for more details on how to
set up your distribution.

=head1 VERSION SKEW

I found out the hard way that if you are working on a module and you
update the version, you must rerun C<Build.PL>. Experienced programmers
probably already knew that, but I didn't and I hope this note will help
any new module maintainers as they update their work.

=head1 DIAGNOSTICS

None yet, but surely I need to add some.

=begin author_examples

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=end author_examples

=head1 CONFIGURATION AND ENVIRONMENT

To create a M::B::PDL build, you should probably begin with something like
L<Module::Starter>.  Then edit the C<Build.PL> file so that it uses
C<Module::Build::PDL> instead of C<Module::Build>.

The use (by C<Module::Build>) of the lib directory is important.  Here
is a brief explanation if you are not familiar with how this works.
Suppose you want to install a pure-perl module called My::Foo::Bar.  You
would put the file Bar.pm in the directory C<lib/My/Foo>.  Anything you
put in C<lib/> will be processed, so you don't need to tell the builder
anything about where to look for your files.  This means that if you
wanted to distribute multiple modules C<My::Foo>, C<My::Foo::Base>,
C<My::Foo::Bar>, and C<PDL::My::Foo>, your directory structure should
look something like this:

 Build.PL
 Changes
 ignore.txt
 MANIFEST
 README
 lib/
  My/
   Foo.pm
   Foo/
    Base.pm
    Bar.pm
  PDL/
   My/
    Foo.pm

In other words, put the files in lib where you would expect to find them
once everything is compiled and installed.

So far, I've only described what C<Module::Build> does.  The only new
capability provided by C<Module::Build::PDL> (so far) is that if you
have a .pd file in your C<lib/> directory, C<Module::Build::PDL> will
properly process it for you.

=head1 DEPENDENCIES

L<PDL>, L<Module::Build>

=head1 TODO

I have a number of things that I need to add to this module.

=over

=item 1. Typemaps

Right now, you must manually include the typemap.pdl file in you lib
directory.  This could easily be automatically copied over during the
object creation process, but I've not yet implemented it.

=item 2. External Dependencies

I need to add some sort of systematized method for checking for external
dependencies.  This will require some thought and planning.  At the
moment, I think that we should put a separate directory in the
distribution's root directory called C<ext_dep> or some such thing.  Any
module that depends on an external dependency - and which should not be
compiled if that external dependency is not found - should have an
identically named test file in C<ext_dep>.  For example, to create
C<PDL::My::Foo>, you would have the files C<lib/PDL/My/Foo.pd> and
C<ext_dep/PDL/My/Foo.pm>.  The C<ext_dep> file would be 'used' and its
return value would determine if the external dependency could be found.
This would also need to have a natural extension for subdirectories,
where C<GSL> is a good example.

=item 3. Automatic M::B::PDL Dependence

This module needs to have a build-in dependence on itself, naturally.

=item 4. Better documentation

Obviously.

=item 5. Tests

I'm not even quite sure how to write tests for this, but they really
should be done. (TODO: check the output of various logs.)

=back

=head1 BUGS, LIMITATIONS, AND SUPPORT

First see TODO above.

You have a number of avenues in which you can report bugs, submit ideas,
or get help.  These include:

=over

=item Make an Annotation

If you have any module documentation recommendations or suggestions,
you should note them on AnnoCPAN.  I intend to check the annotations on
a regular basis and incorporate them into my documentation on a regular
basis.  This module's annotations are located at
L<http://annocpan.org/dist/Module-Build-PDL>.

=item Help via Email

Although this is a free-standing module, it will (hopefully soon) be
moved into L<PDL>.  As such, you can probably get help from the PDL
mailing list, which is explained here: L<http://pdl.perl.org/maillists/>

=item Report a Bug or Feature Request

You can send bugs and feature requests to
C<bug-module-build-pdl@rt.cpan.org>, or submit them through the web
interface at L<http://rt.cpan.org>.

=back



=head1 AUTHOR

David Mertens, with help from Judd Taylor.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, David Mertens. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
