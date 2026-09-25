# ABSTRACT: rpm packaging layer of the NVIDIA driver setups (experimental)

package Rex::GPU::NVIDIA::Setup::Rpm;
our $VERSION = '0.002';
use Moo;
use Rex::Logger ();
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup';


sub package_manager { 'dnf' }


sub package_manager_command {
  my ( $self ) = @_;
  return $self->package_manager;
}


sub install_packages {
  my ( $self, $plan ) = @_;
  Rex::Logger::info('  Installing: '.join(', ', @{ $plan->{packages} }));
  my $pkg_str = join(' ', @{ $plan->{packages} });
  $self->run_cmd($self->package_manager_command.' install -y '.$pkg_str, auto_die => 0);
}


sub verify_query {
  my ( $self, $what ) = @_;
  return 'rpm -q '.$what;
}

sub verify_packages {
  my ( $self, $plan ) = @_;
  my $pm = $self->package_manager;
  for my $driver_pkg (@{ $plan->{verify} }) {
    my $check = $self->run_cmd($self->verify_query($driver_pkg).' 2>&1', auto_die => 0);
    die "$driver_pkg not installed after $pm install — check $pm output\n"
      if $? != 0;
  }
}


sub installed_driver_version {
  my ( $self, $source ) = @_;
  my $pkg = $self->_with_branch($source->{fabric_manager_match}, $source);
  die "The driver source names no package to read the driver version from "
    ."(fabric_manager_match); the driver is installed, Fabric Manager is not\n"
    unless defined $pkg;
  return $self->_rpm_version($pkg);
}

sub install_versioned_package {
  my ( $self, $pkg, $version ) = @_;
  $self->run_cmd($self->package_manager_command.' install -y '.$pkg.'-'.$version, auto_die => 0);
}

sub verify_versioned_package {
  my ( $self, $pkg, $version ) = @_;
  $self->verify_packages({ verify => [ $pkg ] });
  my $installed = $self->_rpm_version($pkg);
  die "$pkg is ".( $installed // 'unknown' ).' after '.$self->package_manager
    ." install, not the driver's $version\n"
    unless defined $installed && $installed eq $version;
}


sub installed_fabric_managers {
  my ( $self ) = @_;
  my $out = $self->run_cmd(q{rpm -qa --qf '%{NAME} %{VERSION}\n' 'nvidia-fabric*manager*' 2>/dev/null},
    auto_die => 0);
  my @present;
  for my $line (split /\n/, $out // '') {
    my ( $name, $version ) = split ' ', $line;
    push @present, [ $name, $version ] if $self->_is_fabric_manager_name($name);
  }
  return @present;
}

sub _rpm_version {
  my ( $self, $pkg ) = @_;
  my $v = $self->run_cmd("rpm -q --qf '%{VERSION}' $pkg 2>&1", auto_die => 0);
  return if $? != 0 || !defined $v;
  chomp $v;
  return $v;
}

# Pure (karr #26): is this `rpm -q --qf '%{VERSION}'` output a version of
# driver branch $branch ("580.178.04" is branch 580)? Anything else -- another
# branch, "package ... is not installed", empty -- is false.
sub _rpm_version_in_branch {
  my ( $self, $version, $branch ) = @_;
  return 0 unless defined $version && defined $branch;
  return $version =~ /^\Q$branch\E\./ ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup::Rpm - rpm packaging layer of the NVIDIA driver setups (experimental)

=head1 VERSION

version 0.002

=head1 DESCRIPTION

B<Experimental>, like L<Rex::GPU::NVIDIA::Setup>. The rpm half shared by
L<Rex::GPU::NVIDIA::Setup::RHEL> (C<dnf>) and
L<Rex::GPU::NVIDIA::Setup::SUSE> (C<zypper>): the package manager's
C<install -y> run directly and C<rpm -q> as the only evidence of an
install. The initramfs is rebuilt with the base class's C<dracut>.

=head2 package_manager

The command that installs packages on this layer: C<dnf> here,
C<zypper> in L<Rex::GPU::NVIDIA::Setup::SUSE>. It also names the package
manager in the L</verify_packages> error.

=head2 package_manager_command

The invocation L</install_packages> and L</install_versioned_package> run:
L</package_manager> here; L<Rex::GPU::NVIDIA::Setup::SUSE> prefixes the
zypp lock wait. Error messages keep naming L</package_manager>.

=head2 install_packages

C<< <package_manager_command> install -y >> of C<< $plan->{packages} >> through
L<Rex::GPU::NVIDIA::Setup/run_cmd> with C<auto_die =E<gt> 0> -- B<never>
L<Rex::Commands::Pkg/pkg>. C<Rex::Pkg::Dnf> dies on any non-zero exit, and
the DKMS module build or initramfs regeneration in a driver package's
scriptlets routinely exits non-zero on success. Whether the install worked
is decided by L</verify_packages>, not by this exit code.

=head2 verify_packages

Dies unless L</verify_query> succeeds for every entry in
C<< $plan->{verify} >>. An empty list verifies nothing.

=head2 verify_query

  my $cmd = $self->verify_query('nvidia-driver');

The C<rpm> query L</verify_packages> runs for one entry: C<rpm -q NAME>, so
an entry is a package name. L<Rex::GPU::NVIDIA::Setup::SUSE> asks
C<rpm -q --whatprovides> instead, so its entries can be capabilities.

=head2 installed_driver_version

C<rpm -q --qf '%{VERSION}'> of the source's C<fabric_manager_match>
package (C<nvidia-driver>): C<580.95.05>.

=head2 install_versioned_package

C<< <package_manager_command> install -y PKG-VERSION >> with C<auto_die =E<gt> 0>,
the name-version form without an epoch: NVIDIA's driver packages carry epoch
3, its C<nvidia-fabricmanager> epoch 0, so the driver's full EVR would not
match. There is no availability check before the driver install on this
layer; a missing version fails the install, and
L</verify_versioned_package> dies.

=head2 verify_versioned_package

L</verify_query> of the package, then C<rpm -q --qf '%{VERSION}'> must be
C<$version>.

=head2 installed_fabric_managers

C<rpm -qa> of C<nvidia-fabric*manager*>: every installed Fabric Manager
package with its version.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA::Setup>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-gpu/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
