use v5.14;
use warnings;

package Pantry::App;
# ABSTRACT: Internal pantry application superclass
our $VERSION = '0.012'; # VERSION

use App::Cmd::Setup 0.317 -app;

sub global_opt_spec {   # none yet, so just an empty stub
  return;
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App - Internal pantry application superclass

=head1 VERSION

version 0.012

=head1 DESCRIPTION

This class is the internal superclass for the Pantry application, containing
any common data or methods.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
