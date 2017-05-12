=head1 NAME

PDLA::Install::Files

=head1 SYNOPSIS

  use Inline with => 'PDLA';
  # or alternatively, if your XS module uses PDLA:
  use ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new(qw(MyPackage PDLA));

=head1 DESCRIPTION

This module is for use by L<ExtUtils::Depends> and L<Inline>. There are
no user-serviceable parts inside.

=cut

package PDLA::Install::Files;
# support ExtUtils::Depends
require PDLA::Core::Dev;

our $VERSION = '2.009';

$self = {
  'typemaps' => [ &PDLA::Core::Dev::PDLA_TYPEMAP ],
  'inc' => &PDLA::Core::Dev::PDLA_INCLUDE,
  'libs' => '',
  'deps' => [],
};
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};
$CORE = undef;
foreach (@INC) {
  if ( -f "$_/PDLA/Install/Files.pm") { $CORE = $_ . "/PDLA/Install/"; last; }
}

sub deps { }
# support: use Inline with => 'PDLA';

require Inline;

sub Inline {
  my ($class, $lang) = @_;
  return {} if $lang eq 'Pdlapp';
  return unless $lang eq 'C';
  unless($ENV{"PDLA_Early_Inline"} // ($Inline::VERSION >= 0.68) ) {
      die "PDLA::Inline: requires Inline version 0.68 or higher to make sense\n  (yours is $Inline::VERSION). You should upgrade Inline, \n   or else set \$ENV{PDLA_Early_Inline} to a true value to ignore this message.\n";
  }
  +{
    TYPEMAPS      => [ &PDLA::Core::Dev::PDLA_TYPEMAP ],
    INC           => &PDLA::Core::Dev::PDLA_INCLUDE,
    AUTO_INCLUDE  => &PDLA::Core::Dev::PDLA_AUTO_INCLUDE,
    BOOT          => &PDLA::Core::Dev::PDLA_BOOT,
  };
}

1;
