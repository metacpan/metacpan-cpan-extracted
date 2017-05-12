#!/usr/bin/perl -c

package MooseX::GlobRef::Role::Object;

=head1 NAME

MooseX::GlobRef::Role::Object - An object role for MooseX::GlobRef

=head1 SYNOPSIS

  Moose::Util::MetaRole::apply_base_class_roles(
      for_class => $caller,
      roles => [ 'MooseX::GlobRef::Role::Object' ],
  );

  package My::IO::File;

  use Moose;

  extends 'Moose::Object', 'IO::File';
  with 'MooseX::GlobRef::Role::Object';

  has 'file' => ( is => 'ro', isa => 'Str', required => 1 );
  has 'mode' => ( is => 'ro', isa => 'Str', default => 'r' );

  sub BUILD {
      my ($fh) = @_;
      $fh->open( $fh->file, $fh->mode );
  };

  sub slurp {
    my ($fh) = @_;
    local $/ = undef;
    return $fh->getline;
  };

  my $io = My::IO::File->new( file => '/etc/passwd' );
  print "::::::::::::::\n";
  print $io->file, "\n";
  print "::::::::::::::\n";
  print $io->slurp;

=head1 DESCRIPTION

This is a role for L<Moose::Object> which is applied by L<MooseX::GlobRef>.
It allows to store Moose object in glob reference of file handle.

The L<MooseX::GlobRef> package should be used instead for Moose classes but
the C<MooseX::GlobRef::Role::Object> can be helpful if you want to extend
non-Moose classes like L<IO::File> or L<File::Temp>.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.0701';

use Moose::Role;


=head1 METHODS

=over

=item <<around>> B<dump>( I<maxdepth> : Int = 1 ) : Array|Str

Dumps the object itself and also a hash slot of glob reference of this object.
It returns an array or string depended on context.

See L<Moose::Object>.

=back

=cut

around 'dump' => sub {
    my $super = shift;
    my ($self, $maxdepth) = @_;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = $maxdepth || 1;
    my @dump = ( $super->(@_), Data::Dumper::Dumper( \%{*$self} ) );
    return wantarray ? @dump : join('', @dump);
};


no Moose::Role;

1;


=head1 SEE ALSO

L<MooseX::GlobRef>, L<Moose::Object>, L<Moose::Role>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2007, 2008, 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
