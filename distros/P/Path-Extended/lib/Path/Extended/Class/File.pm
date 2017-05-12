package Path::Extended::Class::File;

use strict;
use warnings;
use base qw( Path::Extended::File );

sub _initialize {
  my ($self, @args) = @_;

  my $file = File::Spec->catfile( @args );
  $self->_set_path($file);
  $self->{is_dir}    = 0;
  $self->{_compat}   = 1;

  $self;
}

sub new_foreign {
  my ($class, $type, @args) = @_;
  $class->new(@args);
}

sub absolute {
  my $self = shift;
  $self->{_base} = undef;
  $self;
}

sub relative {
  my $self = shift;
  my $base = @_ % 2 ? shift : undef;
  my %options = @_;
  $self->{_base} = $base || $options{base} || File::Spec->curdir;
  $self;
}

sub dir        { shift->parent }
sub volume     { shift->parent->volume }
sub cleanup    { shift } # is always clean
sub as_foreign { shift } # does nothing

1;

__END__

=head1 NAME

Path::Extended::Class::File

=head1 DESCRIPTION

L<Path::Extended::Class::File> behaves pretty much like L<Path::Class::File> and can do some extra things. See appropriate pods for details.
=head1 COMPATIBLE METHODS

=head2 dir

returns a parent L<Path::Extended::Class::Dir> object of the file.

=head2 absolute, relative

change how to stringify internally and return the file object (instead of the path itself).

=head2 volume

returns a volume of the path (if any).

=head1 INCOMPATIBLE METHODS

=head2 cleanup

does nothing but returns the object to chain. L<Path::Extended::Class> should always return a canonical path.

=head2 as_foreign

does nothing but returns the object to chain. L<Path::Extended::Class> doesn't support foreign path expressions.

=head2 new_foreign

returns a new L<Path::Extended::Class::File> object whatever the type is specified.

=head1 SEE ALSO

L<Path::Extended::Class>, L<Path::Extended::File>, L<Path::Class::File>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
