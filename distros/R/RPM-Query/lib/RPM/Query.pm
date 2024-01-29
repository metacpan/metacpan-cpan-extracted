package RPM::Query;
use strict;
use warnings;
use base qw{Package::New};
use List::Util qw{uniq};
use IPC::Run3 qw{};
use RPM::Query::Package;
use RPM::Query::Capability;

our $VERSION = '0.03';

=head1 NAME

RPM::Query - Perl object overlay of the RPM query command

=head1 SYNOPSIS


  use RPM::Query;
  my $rpm      = RPM::Query->new;
  my $pkg      = $rpm->query('perl');
  my $requires = $pkg->requires;
  foreach my $capability (@$requires) {
    printf "Capability: %s\n", $capability->name;
    my $whatprovides = $capability->whatprovides;
    foreach my $package (@$whatprovides) { #could be zero or more but normally one
      printf "  Package: %s\n", $package->package_name;
    }
  }

=head1 DESCRIPTION

=head1 METHODS

=head2 query

Returns an the last object of the passed in package name or undef if not installed.

  my $package_obj = $rpm->query("my_package") or die("my_package is not installed");
  my $long_name   = $package_obj->package_name;

Wrapper around

  $ rpm --query | tail -n 1
  perl-5.16.3-299.el7_9.x86_64

=cut

sub query {
  my $self  = shift;
  my $name  = shift or die;
  my $array = $self->query_list($name);
  return $array->[-1];
}

=head2 query_list

  my $packages_aref = $rpm->query("kernel");

Wrapper around

  $ rpm -q kernel
  kernel-3.10.0-1160.76.1.el7.x86_64
  kernel-3.10.0-1160.80.1.el7.x86_64
  kernel-3.10.0-1160.81.1.el7.x86_64
  kernel-3.10.0-1160.83.1.el7.x86_64
  kernel-3.10.0-1160.88.1.el7.x86_64

=cut

sub query_list {
  my $self  = shift;
  my $name  = shift or die;
  my $array = $self->_run3_array('--query' => $name);
  return [map {RPM::Query::Package->new(package_name=>$_, parent=>$self)} @$array];
}

=head2 details

Returns a HASH data structure of the details of the passed in package name.

  my $hash    = $rpm->details("my_package");
  my $version = $hash->{'version'};

Wrapper around

  $ rpm --query perl --queryformat '%{name} %{version} ...'
  perl 5.16.3 ...

=cut

our @QUERY_FORMAT_FIELDS = qw{name version release epoch arch group size license packager url summary description sourcerpm sigmd5 buildtime buildhost installtime distribution vendor}; #rpm info plus

sub details {
  my $self   = shift;
  my $arg    = shift or die;
  my $format = join('|x1|', map {"%{$_}"} @QUERY_FORMAT_FIELDS); #delimiter is '|x1|'
  my $scalar = $self->_run3_scalar('--query' => $arg, '--queryformat' => $format); #isa ARRAY
  my %hash   = ();
  @hash{@QUERY_FORMAT_FIELDS} = split /\|x1\|/, $scalar; #hash slice assignment
  return \%hash;
}

=head2 verify

Returns true if verify is clean

Wrapper around

  $ rpm --verify perl && echo 1 || echo 0
  1

=cut

sub verify {
  my $self  = shift;
  my $name  = shift;
  my $error = $self->_run3_error('--verify' => $name);
  return !$error;
}

=head2 whatprovides

Returns a list of packages that provides the capability

  my $package = $rpm->whatprovides('perl(strict)'); #isa ARRAY of RPM::Query::Package

Wrapper around

  $ rpm --query --whatprovides 'perl(strict)'
  perl-5.16.3-299.el7_9.x86_64

=cut

sub whatprovides {
  my $self       = shift;
  my $capability = shift or die;
  my $array      = $self->_run3_array('--query' => '--whatprovides' => $capability);
  return [map {RPM::Query::Package->new(package_name=>$_, parent=>$self)} uniq sort @$array];
}

=head2 provides

Returns a list of capabilities that the installed package provides

  my $capabilities = $rpm->provides('perl'); #isa ARRAY of RPM::Query::Capability objects

Wrapper around

  $ rpm --query --provides 'perl'
  perl = 4:5.16.3-299.el7_9
  perl(AutoLoader) = 5.72
  perl(B) = 1.35
  perl(B::Section)
  ...

=cut

sub provides {
  my $self       = shift;
  my $capability = shift or die;
  my $array      = $self->_run3_array('--query' => '--provides' => $capability);
  return [map {RPM::Query::Capability->new(capability_name=>$_, parent=>$self)} uniq sort @$array];
}

=head2 requires

Returns a list of capabilities that the package requires

  my $capabilities = $rpm->requires('perl'); #isa ARRAY of RPM::Query::Capability objects

Wrapper around

  $ rpm --query --requires perl
  /usr/bin/perl
  libpthread.so.0()(64bit)
  perl >= 0:5.000
  ...

=cut

sub requires {
  my $self       = shift;
  my $capability = shift or die;
  my $array      = $self->_run3_array('--query' => '--requires' => $capability);
  return [map {RPM::Query::Capability->new(capability_name=>$_, parent=>$self)} uniq sort @$array];
}

=head2 whatrequires

Returns a list of packages that this capability requires

  my $capabilities = $rpm->whatrequires('perl'); #isa ARRAY of RPM::Query::Package objects

Wrapper around

  $ rpm --query --whatrequires perl
  perl-podlators-2.5.1-3.el7.noarch
  perl-Pod-Perldoc-3.20-4.el7.noarch
  perl-Text-ParseWords-3.29-4.el7.noarch
  perl-Pod-Usage-1.63-3.el7.noarch
  perl-threads-shared-1.43-6.el7.x86_64
  perl-Filter-1.49-3.el7.x86_64
  perl-Exporter-5.68-3.el7.noarch
  ...

=cut

sub whatrequires {
  my $self       = shift;
  my $capability = shift or die;
  my $array      = $self->_run3_array('--query' => '--whatrequires' => $capability);
  return [map {RPM::Query::Package->new(package_name=>$_, parent=>$self)} uniq sort @$array];
}

sub _run3_scalar {
  my $self   = shift;
  my @argv   = @_;
  my $stdout = '';
  my $error  = 0;
  IPC::Run3::run3 [$self->command => @argv], \undef, \$stdout, \$error;
  die("Error: Command returned $error") if $error;
  $stdout =~ s/\s+\Z//; #RTRIM
  return $stdout;
}

sub _run3_array {
  my $self   = shift;
  my @argv   = @_;
  my @stdout = ();
  my $error  = 0;
  IPC::Run3::run3 [$self->command => @argv], \undef, \@stdout, \$error;
  chomp @stdout;
  @stdout = () if (@stdout == 1
                    and (
                         $stdout[0] =~ m/\Ano package provides /
                          or
                         $stdout[0] =~ m/\Ano package requires /
                          or
                         $stdout[0] =~ m/\Apackage .* is not installed\Z/
                         )
                  );
  die("Error: Command returned $error") if $error;
  return \@stdout;
}

sub _run3_error {
  my $self  = shift;
  my @argv  = @_;
  my $error = 0;
  IPC::Run3::run3 [$self->command => @argv], \undef, \undef, \$error;
  return $error;
}

=head1 PROPERTIES

=head2 command

=cut

sub command {
  my $self           = shift;
  $self->{'command'} = shift if @_;
  $self->{'command'} = 'rpm' unless defined $self->{'command'};
  return $self->{'command'};
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis

=cut

1;
