package Package::New::Dump;
use base qw{Package::New};
use strict;
use warnings;

our $VERSION='0.06';

=head1 NAME

Package::New::Dump - Simple base package from which to inherit

=head1 SYNOPSIS

  package My::Package;
  use base qw{Package::New::Dump}; #provides new, initialize and dump

=head1 DESCRIPTION

The Package::New::Dump object provides a consistent object constructor for objects.

=head1 RECOMMENDATIONS

I recommend using this package only during development and reverting back to L<Package::New> when in full production

=head1 USAGE

=head1 CONSTRUCTOR

See L<Package::New>

=cut

=head1 METHODS

=head2 dump

Returns the object serialized by L<Data::Dumper>

=cut

sub dump {
  my $self=shift();
  eval 'use Data::Dumper qw{}';
  if ($@) {
    return wantarray ? () : '';
  } else {
    my $depth=shift; $depth=2 unless defined $depth;
    my $d=Data::Dumper->new([$self]);
    $d->Maxdepth($depth);
    return $d->Dump;
  }
}

=head1 BUGS

Log on RT and contact the author.

=head1 SUPPORT

DavisNetworks.com provides support services for all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com
  http://www.DavisNetworks.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
