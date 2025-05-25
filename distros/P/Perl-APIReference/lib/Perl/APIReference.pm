package Perl::APIReference;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;
use version;
use Sereal::Decoder;

our $VERSION = '0.24';

use Class::XSAccessor
  getters => {
    'index' => 'index',
    'perl_version' => 'perl_version',
  };

sub _par_loader_hint {
  require Perl::APIReference::Generator;
  require Perl::APIReference::V5_040_002;
}

our %Perls;
SCOPE: {
  # Generate list of supported Perl versions from shorthand.
  my @perls = (
    [40, 0..2],
    [38, 0..4],
    [36, 0..3],
    [34, 0..3],
    [32, 0..1],
    [30, 0..3],
    [28, 0..3],
    [26, 0..4],
    [24, 0..4],
    [22, 0..4],
    [20, 0..2],
    [18, 0..2],
    [16, 0..3],
    [14, 0..4],
    [12, 0..5],
    [10, 0..1],
    [8,  0..9],
    [6,  0..2],
  );

  foreach my $p (@perls) {
    my $major = $p->[0];
    foreach my $minor (@$p[1..$#$p]) {
      my $v = sprintf("V5_%03u_%03u", $major, $minor);
      my $num = sprintf("5.%03u", $major);
      $num .= sprintf("%03u", $minor) if $minor > 0;
      $Perls{$num} = $v;
    }
  }
};

our $NewestAPI       = '5.040002';
our $NewestStableAPI = '5.040002';

# Aliases
$Perls{'5.04'}     = $Perls{'5.040'};
$Perls{'5.040000'} = $Perls{'5.040'};
$Perls{'5.038000'} = $Perls{'5.038'};
$Perls{'5.036000'} = $Perls{'5.036'};
$Perls{'5.034000'} = $Perls{'5.034'};
$Perls{'5.032000'} = $Perls{'5.032'};
$Perls{'5.03'}     = $Perls{'5.030'};
$Perls{'5.030000'} = $Perls{'5.030'};
$Perls{'5.028000'} = $Perls{'5.028'};
$Perls{'5.026000'} = $Perls{'5.026'};
$Perls{'5.024000'} = $Perls{'5.024'};
$Perls{'5.022000'} = $Perls{'5.022'};
$Perls{'5.02'}     = $Perls{'5.020'};
$Perls{'5.020000'} = $Perls{'5.020'};
$Perls{'5.018000'} = $Perls{'5.018'};
$Perls{'5.016000'} = $Perls{'5.016'};
$Perls{'5.014000'} = $Perls{'5.014'};
$Perls{'5.012000'} = $Perls{'5.012'};
$Perls{'5.010000'} = $Perls{'5.010'};
$Perls{'5.01'}     = $Perls{'5.010'};
$Perls{'5.008000'} = $Perls{'5.008'};
$Perls{'5.006000'} = $Perls{'5.006'};
#$Perls{'5.000'} = $Perls{5};

sub _get_class_name {
  my $class_or_self = shift;
  my $version = shift;
  return exists $Perls{$version} ? "Perl::APIReference::" . $Perls{$version} : undef;
}

sub new {
  my $class = shift;
  my %args = @_;
  my $perl_version = $args{perl_version};
  croak("Need perl_version")
    if not defined $perl_version;
  $perl_version = $NewestStableAPI if lc($perl_version) eq "newest";
  $perl_version = $NewestAPI if lc($perl_version) eq "newest_devel";

  $perl_version = version->new($perl_version)->numify();
  croak("Bad perl version '$perl_version'")
    if not exists $Perls{$perl_version};

  my $classname = __PACKAGE__->_get_class_name($perl_version);
  eval "require $classname;";
  croak("Bad perl version ($@)") if $@;

  return $classname->new(perl_version => $perl_version);
}

sub as_yaml_calltips {
  my $self = shift;

  my $index = $self->index();
  my %toyaml;
  foreach my $entry (keys %$index) {
    my $yentry = {
      cmd => '',
      'exp' => $index->{$entry}{text},
    };
    $toyaml{$entry} = $yentry;
  }
  require YAML::Tiny;
  return YAML::Tiny::Dump(\%toyaml);
}

# only for ::Generator
sub _new_from_parse {
  my $class = shift;

  return bless {@_} => $class;
}

# only for ::Generator
sub _dump_as_class {
  my $self = shift;
  my $version = $self->perl_version;
  my $classname = $self->_get_class_name($version);
  if (not defined $classname) {
    die "Can't determine class name for Perl version '$version'."
      . " Do you need to add it to the list of supported versions first?";
  }
  my $file_name = $classname;
  $file_name =~ s/^.*::([^:]+)$/$1.pm/;
  
  require Sereal::Encoder;
  my $data = $self->{'index'};
  my $dump = Sereal::Encoder->new({
    compress           => Sereal::Encoder::SRL_ZSTD(),
    compress_level     => 22,
    compress_threshold => 1,
    dedupe_strings     => 1,
    sort_keys          => 1,
  })->encode($data);
  
  open my $fh, '>', $file_name or die $!;
  binmode $fh;
  print $fh <<HERE;
package $classname;
use strict;
use warnings;
use Sereal::Decoder;
use parent 'Perl::APIReference';

sub new {
  my \$class = shift;
  my \$pos = tell(*DATA);
  binmode(*DATA);
  local \$/ = undef;

  my \$data = <DATA>;
  \$data =~ s/^\\s+//;

  my \$self = bless({
    'index'      => Sereal::Decoder::decode_sereal(\$data),
    perl_version => '$version',
  } => \$class);

  seek(*DATA, \$pos, 0);

  return \$self;
}

1;

HERE
  print $fh "__DATA__\n";
  print $fh $dump;
}


1;
__END__

=head1 NAME

Perl::APIReference - Programmatically query the perlapi

=head1 SYNOPSIS

  use Perl::APIReference;
  my $api = Perl::APIReference->new(perl_version => '5.40.2');
  my $api_index_hash = $api->index;

=head1 DESCRIPTION

This module allows accessing the perlapi documentation for multiple
releases of perl as an index (a hash).

Currently, ll stable releases between 5.6.0 and 5.40.2 are supported.
To add support for another release, simply send me the
release's F<perlapi.pod> via email or via an RT ticket and I'll add it
in the next release.

API docs for development releases
may be dropped from the distribution
at any time. The general policy on this is to try
and ship the APIs for the newest development release.

=head1 METHODS

=head2 new

Constructor. Takes the C<perl_version> argument which specifies the
version of the perlapi that you want to use. The version has to be
in the form C<5.008009> to indicate perl 5.8.9. For the initial
releases in a new family (5.10.0, etc), the shortened forms
C<5.010> and C<5.01> can be used.

Special C<perl_version> settings are C<newest> and C<newest_devel>
which correspond to the newest available stable and experimental
perl API versions.

=head2 index

Returns the index of perlapi entries and their documentation as a hash
reference.

=head2 perl_version

Returns the API object's perl version. Possibly normalized to the
floating point form (C<version-E<gt>new($version)-E<gt>numify()>).

=head2 as_yaml_calltips

Dumps the index as a YAML file in the format used by the Padre calltips.
Requires L<YAML::Tiny>.

=head1 SEE ALSO

L<perlapi>

L<Perl::APIReference::Generator>

L<Padre>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
