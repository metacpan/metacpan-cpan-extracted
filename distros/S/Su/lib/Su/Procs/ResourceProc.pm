package Su::Procs::ResourceProc;
use strict;
use warnings;
use Su::Template;

=pod

=head1 NAME

Su::Procs::ResourceProc - The process to load resource strings.

=head1 SYNOPSYS

 my $su = Su->new.
 my $value = $su->resolve('resource');

=head1 DESCRIPTION

The process to load resource strings.

=head1 FUNCTIONS

=over

=cut

my $model = {};

=item new()

Constructor.

=cut

sub new {
  return bless { model => $model }, shift;
}

=item process()

The main method for this process class.

=cut

sub process {
  my $self             = shift if ( $_[0] && ref $_[0] eq __PACKAGE__ );
  my $self_module_name = shift if ( $_[0] && $_[0]     eq __PACKAGE__ );
  my $model = keys %{ $self->{model} } ? $self->{model} : $model;

  my $param = shift;
  return $model->{$param};
} ## end sub process

=item map_filter()

This method is called if specified as a map filter class.

=cut

sub map_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;

  for (@results) {

  }

  return @results;
} ## end sub map_filter

=item reduce_filter()

This method is called if specified as a reduce filter class.

=cut

sub reduce_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;
  my $result;
  for (@results) {

  }

  return $result;
} ## end sub reduce_filter

=item scalar_filter()

This method is called if specified as a scalar filter class.

=cut

sub scalar_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $result = shift;

  return $result;
} ## end sub scalar_filter

=item model()

The accessor to the model.

=cut

sub model {
  my $self             = shift if ref $_[0] eq __PACKAGE__;
  my $self_module_name = shift if $_[0]     eq __PACKAGE__;
  my $arg              = shift;
  if ($arg) {
    if ($self) { $self->{model} = $arg; }
    else {
      $model = $arg;
    }
  } else {
    if ($self) {
      return $self->{model};
    } else {
      return $model;
    }
  } ## end else [ if ($arg) ]
} ## end sub model

1;

=back

=cut
