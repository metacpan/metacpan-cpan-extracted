package Regexp::Copy;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Regexp::Storable;

require Carp;
require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw( );
@EXPORT_OK = qw(re_copy);
$VERSION = '0.06';


bootstrap Regexp::Copy $VERSION;

sub re_copy {
  for (@_) {
    if (uc(ref($_)) eq ref($_) && !$_->isa('Regexp')) {
      Carp::croak "parameters to re_copy must be blessed and isa(Regexp)";
    }
  }
  re_copy_xs(@_);
}


1;

__END__

=head1 NAME

Regexp::Copy - copy Regexp objects

=head1 SYNOPSIS

  use Regexp::Copy qw( re_copy );

  my $re1 = qr/Hello!/;
  my $re2 = qr/Goodbye!/;

  re_copy($re1, $re2);

  print "ok\n" if 'Goodbye!' =~ $re1;

=head1 DESCRIPTION

C<Regexp::Copy> allows you to copy the contents of one Regexp object to another.
A problem that I have found with the qr// operator is that the Regexp objects that
it creates are is impossible to dereference.  This causes problems if you want to change
the data in the regexp without losing the reference to it.  Its impossible.  Regexp::Copy
allows you to change the Regexp by copying one object created through qr// to another.

This module came about through discussions on the London.pm mailing list in regards to
attempts various people had made to serialize objects with qr// created Regexp objects in
them.  The Regex::Copy distribution also loads Regexp::Storable, which provides hooks to
allow the Storable persistence method to freeze and thaw Regexp objects created by qr//.

=head1 FUNCTIONS

=over 4

=item re_copy(FROM, TO)

The C<re_copy> function copies the regular expression magic contained within the
variable FROM to the variable named in TO.

=back

=head1 THANKS TO

Piers Cawley, who provided the magic Pixie::Info code, that forms the basis of Regexp::Copy.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 All Rights Reserved.

This module is released under the same license as Perl itself.

=cut
