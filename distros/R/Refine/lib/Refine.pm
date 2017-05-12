package Refine;

=head1 NAME

Refine - Refine an instance with new methods

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Refine> is a module that export C<$_refine> which can be used to add
methods object instances. Each C<$_refine> call on the object will create a
new class with the new refined methods and rebless the instance into that
class, which keeps the original class as it was.

This is an EXPERIMENTAL release. The class generator might change in future releases.

=head1 SYNOPSIS

  use Refine;
  use Data::Dumper ();

  my $obj = Some::Class->new;

  # add the dump() method to the $obj instance
  $obj->$_refine(
    dump => sub { Data::Dumper->new([$_[0])->Terse(1)->SortKeys(1)->Dump },
  );

=head1 OPTIONAL MODULES

=over 4

=item * Sub::Name

If you have L<Sub::Name> installed, the methods will have proper names,
instead of "__ANON__". This will make stacktraces easier to read.

=back

=cut

use strict;
use warnings;
use Carp ();
use constant SUB_NAME => eval 'require Sub::Name;1' ? 1 : 0;
use base 'Exporter';

our $VERSION = '0.01';
our @EXPORT = '$_refine';

my %PRIVATE2PUBLIC;

our $_refine = sub {
  my ($self, %patch) = @_;
  my $class = ref $self;
  my $private_name = join ':', $class, map { $_, $patch{$_} } sort keys %patch;
  my $refined_class = $PRIVATE2PUBLIC{$private_name};

  unless ($class) {
    Carp::confess("Can only add methods to instances, not $self");
  }

  unless ($refined_class) {
    my $base_class = $class;

    if ($class =~ s!::WITH::(.*)!!) {
      $patch{$_} ||= '' for grep { !/^_\d+$/ } split /::/, $1;
    }

    my $i = 0;
    my $public_name = substr +("$class\::WITH::" .join '::', sort keys %patch), 0, 180;

    do {
      $refined_class = "$public_name\::_$i";
      $i++;
    } while ($refined_class->can('new'));
    $PRIVATE2PUBLIC{$private_name} = $refined_class;
    eval "package $refined_class;use base '$base_class';1" or Carp::confess("Failed to refine $class: $@");

    for my $n (grep { $patch{$_} } keys %patch) {
      no strict 'refs';
      *{"$refined_class\::$n"} = SUB_NAME ? Sub::Name::subname("$refined_class\::$n", $patch{$n}) : $patch{$n};
    }
  }

  no strict 'refs';
  bless $self, $refined_class;
  $self;
};

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
