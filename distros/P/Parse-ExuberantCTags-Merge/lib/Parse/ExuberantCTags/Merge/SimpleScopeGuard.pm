package Parse::ExuberantCTags::Merge::SimpleScopeGuard;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.00';

use Class::XSAccessor
  constructor => 'new',
  accessors => {
    files => 'files',
  };

sub add_files {
  my $self = shift;
  my $files = $self->files || [];

  push @$files, @_;
  $self->files($files);
  return(1);
}

sub cleanup {
  my $self = shift;
  foreach my $file ( @{$self->files || []} ) {
    if (defined $file and -f $file) {
      unlink $file;
    }
  }
  $self->files([]);
  return();
}

sub DESTROY {
  my $self = shift;
  $self->cleanup;
}

1;
__END__

=head1 NAME

Parse::ExuberantCTags::Merge::SimpleScopeGuard - A simple-minded scope guard for cleanup

=head1 SYNOPSIS

  use Parse::ExuberantCTags::Merge::SimpleScopeGuard;
  {
    my $guard = Parse::ExuberantCTags::Merge::SimpleScopeGuard->new(
      files => [qw/to be cleaned up/],
    );
    # ...
  }
  # files deleted.

=head1 DESCRIPTION

For internal use only.

=head1 METHODS

=head2 new

Constructor, may take C<files> parameter with an array reference of file
names/paths. Make sure that these are either absolute paths or that
you're still in the same working directory when the scope guard fires.

=head2 files

Set a new bunch of files to guard.

=head2 add_files

Takes one or more file names as argument and appends to the list of guarded
files.

=head2 cleanup

Delete the guarded files

=head2 DESTROY

Calls C<cleanup> on object destruction.

=head1 SEE ALSO

L<Guard>

L<Scope::Guard>

and many more on CPAN.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
