package Module::Starter::AddModule;
use strict;

use 5.010;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

use parent qw(Module::Starter::Smart);

BEGIN {
	package # hide package from PAUSE
		Module::Starter::Smart;
	use parent qw(Module::Starter::Simple);
	}

use Cwd;

$VERSION = '1.005';

=encoding utf8

=head1 NAME

Module::Starter::AddModule - Add a new module to a distribution

=head1 SYNOPSIS

	# in the module-starter config
	
	plugins: Module::Starter::AddModule
	make: /whatever/make/you/like/dmake

	# from the command line
	# the --dist option specifies the dist directory
	% module-starter --module=Add::This::Module --dist=.

=head1 DESCRIPTION

C<Module::Starter::Simple> and C<Module::Starter::Smart> (which relies
on C<::Simple>) try to construct the MANIFEST file themselves. This is
the wrong approach since it doesn't not take into account build file
subclasses or F<MANIFEST.SKIP>.

Once you have the build file, let it do it's job by running its C<manifest>
target.

Furthermore, C<Module::Starter::Smart> doesn't explicitly inherit from
C<Module::Starter::Simple>, but this module inserts the inheritance
relationship for you automatically.

=over 4

=item create_MANIFEST

Overrides the C<create_MANIFEST> in C<Module::Starter::Simple> to use
the C<manifest> target of the build system instead of trying to create 
the C<MANIFEST> file directly. It automatically figures out the build
system you use.

This assumes that your C<make> program is called C<make>. If it's 
something else, such as C<dmake>, set the C<make> configuration. This
only matters if you are using F<Makefile.PL>.

=cut

sub create_MANIFEST {
    my $self = shift;

	require Distribution::Guess::BuildSystem;
	
	my $dist_dir = $self->basedir;
	die "The base directory" unless -d $dist_dir;
	
	$self->progress( "Regenerating MANIFEST" );
	
	my $make = $self->{make} // 'make'; #/
	
	eval {
		my $dir = cwd();
		chdir $dist_dir or die "Could not change to $dist_dir: $!\n";
		
		my $guesser = Distribution::Guess::BuildSystem->new(
			   dist_dir => '.'
			   );
		
		# it doesn't matter who makes the MANIFEST
		if( $guesser->uses_module_build ) {
			$self->verbose( "Detected Module::Build" );
			system( $^X, 'Build.PL' );
			system( './Build', 'manifest' );
			}
		elsif( $guesser->uses_makemaker or $guesser->uses_module_install ) {
			$self->verbose( "Detected ExtUtils::Makemaker or Module::Install" );
			system( $^X, 'Makefile.PL' );
			system( $make, 'manifest' );
			}
		
		chdir $dir or die "Could not change back to $dir: $!\n";
		} or die $@;
	
	return 1;
	}

=item basedir

Return the top-level directory for the distribution.

=cut

sub basedir { $_[0]->{basedir} || '' }
	
=back

=head1 SEE ALSO

L<Module::Starter::Smart>

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/module-starter-addmodule/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
