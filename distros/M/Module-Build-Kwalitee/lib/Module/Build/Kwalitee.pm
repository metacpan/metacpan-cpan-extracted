=head1 NAME

Module::Build::Kwalitee - Module::Build subclass with prepackaged tests

=cut

package Module::Build::Kwalitee;
use strict;
use warnings;

use base qw( Module::Build );
use File::Spec::Functions qw( splitpath catfile catdir );
use File::Find::Rule;
use File::Copy;
use File::Path;

our $VERSION = '0.24';


# slightly cheeky trick: Module::Build::Kwalitee::Stub is
# actually a tiny Module::Build::Kwalitee package, overriding the
# build_requires() method of Module::Build to add our test
# dependencies. We don't have to duplicate these deps.
use Module::Build::Kwalitee::Stub;

=head1 SYNOPSIS

This module requires this bit of magic in your Build.PL:

  use lib 'mbk';
  use Module::Build::Kwalitee;

  Module::Build::Kwalitee->new(
    module_name => 'Foo::Bar',
      ...,
    },
  )->create_build_script();

=head1 DESCRIPTION

Module::Build::Kwalitee subclasses Module::Build to provide
boilerplate tests for your project. It does this by overriding
C<new()> and copying tests to your F<t> directory when you run
'perl Build.PL'.

Module::Build::Kwalitee gets over the bootstrapping problem by
overriding Module::Build's C<distdir> target, adding a "mbk"
directory to your distribution containing a small stub
Module::Build::Kwalitee which just overrides Module::Build's
build_requires() method to add the dependencies of its tests.

Module::Build::Kwalitee tests are not automatically added to
F<MANIFEST> so if you want them shipped with your distribution
you will have to do this manually.


=head2 Tests

Several boilerplate tests are added to t/:

=over

=item compile test

=item C<use strict> test

=item C<use warnings> tests

=item POD syntax & coverage tests

=item 'use lib' test

=back

=cut

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  unless (-d "t") {
    warn "Creating t/ dir for tests...\n";
    mkdir "t" or die "Can't create dir: $!";
  }

  my $path = $INC{"Module/Build/Kwalitee.pm"};
  $path =~ s/\.pm$//;

  map {
    my (undef, undef, $filename) = splitpath( $_ );
    copy($_, catfile('t', $filename)) or die "Can't copy file: $!";
  } File::Find::Rule->file()->name( '*.t' )->in( $path );

  return $self;
}


# ACTION_distdir is documented
sub ACTION_distdir {
  my $self = shift;
  $self->SUPER::ACTION_distdir;

  # where's the distribution directory?
  my $dist_dir = $self->dist_dir;
  die "No _build dir '$dist_dir'" unless -d $dist_dir;

  # create the mbk folder in the dist dir
  mkpath([catdir($dist_dir, qw(mbk Module Build Kwalitee))])
    or die "Cannot create directory";

  # copy in the module stub
  my $stub = $INC{"Module/Build/Kwalitee/Stub.pm"};
  my $dest = catfile($dist_dir, qw(mbk Module Build Kwalitee.pm));
  copy($stub, $dest) or die "Can't copy file ($stub -> $dest) $!";

  # munge the manifest so it contains an entry for the shipped
  # stub if there exists a manifest in the distribution
  my $manifest = catfile($dist_dir, "MANIFEST");
  if (-e $manifest) {
    chmod 0644, $manifest;
    open MANIFEST, ">>$manifest"
      or die "can't open manifest '$manifest' for writing: $!";
    print MANIFEST catfile(qw(mbk Module Build Kwalitee.pm)), "\n";
    chmod 0444, $manifest;
    close MANIFEST;
  }
}

1;

# these are mixed in from ./Stub.pm, and confuse the pod parser for
# some versions of the pod parser.
# new is documented
# build_requires is documented
# recommends is documented


__END__


=head1 ADDITIONAL FEATURES

You can get the C<t/003pod.t> to report which functions are not
documented by using the C<SHOW_NAKED> enviromental variable

  bash$ SHOW_NAKED=1 perl -Ilib t/003compile.t

=head1 SEE ALSO

L<Module::Build>

=head1 AUTHOR

Stig Brautaset <stig@brautaset.org>,
Mark Fowler <mark@twoshortplanks.com>,
Norman Nunley <nnunley@fotango.com>,
Chia-liang Kao <clkao@clkao.org>,
et al.

=cut
