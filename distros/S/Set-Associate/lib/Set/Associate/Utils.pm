use 5.006;
use strict;
use warnings;

package Set::Associate::Utils;

# ABSTRACT: Shared Guts between Set::Associate modules

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

require Exporter;
*import = \&Exporter::import;    ## no critic (ProhibitCallsToUnexportedSubs)

our @EXPORT_OK = qw( _warn_nonmethod );

sub _carp {
  require Carp;
  goto \&Carp::carp;
}

sub _blessed {
  require Scalar::Util;
  goto \&Scalar::Util::blessed;
}

## no critic (RequireArgUnpacking)
sub _warn_nonmethod {
  if ( defined $_[0] and not ref $_[0] ) {
    return if $_[0]->isa( $_[1] );
  }
  if ( defined $_[0] and _blessed( $_[0] ) ) {
    return if $_[0]->isa( $_[1] );
  }
  _carp( $_[1] . '->' . $_[2] . ' should be called as a method' );
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::Utils - Shared Guts between Set::Associate modules

=head1 VERSION

version 0.004001

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
