package ReplaceMultiple;

use strict;
use warnings;

our $VERSION = 1.01;

our (@ISA, @EXPORT);
require Exporter; @ISA = qw(Exporter);
@EXPORT = qw(replace_multiple_inplace replace_multiple);

sub replace_multiple_inplace {
  my ($hash, $str_ref) = @_;
  my $obj = ReplaceMultiple->new($hash);
  return $obj->apply_inplace($str_ref);
}

sub replace_multiple {
  my ($hash, $str) = @_;
  my $obj = ReplaceMultiple->new($hash);
  return $obj->apply($str);
}

sub new {
  my ($class, $hash) = @_;
  my $re_str = "(" . (join '|', map { "\Q$_\E" } keys %$hash) . ")";
  my $self = bless {HASH=>$hash, RE=>qr/$re_str/}, $class;
  return $self;
}

sub apply_inplace {
  my ($self, $str_ref) = @_;
  $$str_ref =~ s/$self->{RE}/$self->{HASH}{$1}/g;
  return $$str_ref;
}

sub apply {
  my ($self, $str) = @_;
  my $str2 = $str;
  return $self->apply_inplace(\$str2);
}

1;
