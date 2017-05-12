package PPM::Make::CPAN;
use strict;
use warnings;
use PPM::Make;
use PPM::Make::Config qw(HAS_PPM);

our $VERSION = '0.9904';

sub new {
  my ($class, %opts) = @_;
  my $self = {cpan_meta => $opts{cpan_meta},
              opts => \%opts};
  bless $self, $class;
}

sub make_ppm_install {
  my $self = shift;
  my %opts = %{$self->{opts}};
  for (qw(cfg)) {
    my $given = 'no-' . $_;
    next unless $opts{$given};
    my $passed = 'no_' . $_;
    $opts{$passed} = delete $opts{$given};
  }
  my %args;
  for (qw(area force nodeps)) {
    $args{$_} = delete $opts{$_};
  }

  my $ppm = PPM::Make->new(%opts, cpan_meta => $self->{cpan_meta});
  $ppm->make_ppm();
  my $ppd = $ppm->{ppd};
  my @args = ('ppm', 'install', $ppd);
  if (HAS_PPM >= 3) {
    for my $bool_arg (qw(force nodeps)) {
      next unless defined $args{$bool_arg};
      push @args, "--$bool_arg";
    }
    for my $str_arg (qw(area)) {
      next unless defined $args{$str_arg};
      push @args, "--$str_arg", $args{$str_arg};
    }
  }
  print "@args\n";
  system(@args);
  return $?;
}

# placeholder for future CPAN.pm
#sub check_prereqs {
#  my ($self, @prereqs) = @_;
#  my $cpan_meta = $self->{cpan_meta};
#  foreach (@prereqs) {
#    my $id = $cpan_meta->instance('CPAN::Module', $_->[0]);
#    warn "********$_->[0]********", $id->as_string, "*********\n";
#  }
#  return @prereqs;
#}

1;

__END__

=head1 NAME

PPM::Make::CPAN - helper module for using ppm within CPAN.pm

=head1 SYNOPSIS

  my $ppm = PPM::Make::CPAN->new(%opts);
  $ppm->make_ppm_install();

=head1 DESCRIPTION

C<PPM::Make::CPAN> is used to build a PPM (Perl Package Manager) 
distribution from a CPAN source distribution and then install it with 
the C<ppm> utility. See L<PPM::Make> for a discussion of details on
how the ppm package is built. Available options are

=over

=item no-cfg =E<gt> 1

Do not read a .ppmcfg configuration file specifying options to
pass to L<PPM::Make>.

=item force =E<gt> 1

If the package or module requested is already installed, PPM
installs nothing. The C<force> option can be used to make PPM install
a package even if it's already present. With C<force> PPM resolves
file conflicts during package installation or upgrade by allowing
files already installed by other packages to be overwritten and
ownership transferred to the new package. This may break the package
that originally owned the file. This is available within PPM4 only.

=item nodeps =E<gt> 1

The C<nodeps> option makes PPM attempt to install the package without
resolving any dependencies the package might have. This is available
within PPM4 only.

=item area =E<gt> $area

By default, new packages are installed in the "site" area, but if
the "site" area is read only, and there are user-defined areas set
up, the first user-defined area is used as the default instead. Use
the C<area> option to install the package into an alternative
location.

=back

=head1 COPYRIGHT

This program is copyright, 2008, by
Randy Kobes E<lt>r.kobes@uwinnipeg.caE<gt>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM::Make>, and L<PPM>.

=cut
