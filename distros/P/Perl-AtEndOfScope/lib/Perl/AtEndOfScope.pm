package Perl::AtEndOfScope;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.03';
our $EXC;

sub new {
  my $class=shift;
  my $I=[@_];
  return bless $I=>(ref($class)||$class);
}

sub DESTROY {
  my ($fn, @args)=@{$_[0]};
  undef $EXC;
  {
    local ($@, $a, $b, $_, $., $!, $^E, $?);
    eval {$fn->(@args)};
    $EXC=$@;
  }
}

1;

__END__

=head1 NAME

Perl::AtEndOfScope - run some code when a variable goes out of scope

=head1 SYNOPSIS

  use Perl::AtEndOfScope;
  use Cwd;
  {
    my $restorecwd=Perl::AtEndOfScope->new( sub{chdir $_[0]}, getcwd );
    chdir '/path/to/some/directory';
    ...
  }
  # now we are back to the old cwd

  # or better using the undocumented "chdir FILEHANDLE"
  use Perl::AtEndOfScope;
  {
    my $restorecwd=Perl::AtEndOfScope->new( sub{chdir $_[0]},
                                            do {opendir my $d, '.'; $d} );
    chdir '/path/to/some/directory';
    ...
  }
  # now we are back to the old cwd

=head1 DESCRIPTION

It's often necessary to do some cleanup at the end of a scope. This module
creates a Perl object and executes arbitrary code when the object goes out
of scope.

=head1 METHODS

=over 4

=item B<< Perl::AtEndOfScope->new( $sub, @args ) >>

the constructor. The code reference passed in $sub is called with @args
as parameter list when the object is destroyed.

While $sub is executed the following variables are preserved:

  $@, $a, $b, $_, $., $!, $^E, $?

This list can grow in future versions.

$sub is executed within an eval block. You can check

  $Perl::AtEndOfFile::EXC

to see if an exception has been thrown by it. $Perl::AtEndOfScope::EXC
is not stringified.

If multiple Perl::AtEndOfScope objects are destroyed at the same time
only the last exception thrown by one of them is saved.

=item B<DESTROY( $self )>

the destructor.

=back

=head1 EXPORT

Not an Exporter.

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
