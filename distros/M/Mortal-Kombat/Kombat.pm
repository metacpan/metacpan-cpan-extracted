package Mortal::Kombat;

use strict;
use vars qw( $VERSION @ISA @EXPORT );

require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( fatality );
$VERSION = '1.00';


sub fatality (@) { die @_ }


package victory;

sub flawless { exit }


1;

__END__

=head1 NAME

Mortal::Kombat - Mortal Kombat program termination

=head1 SYNOPSIS

  use Mortal::Kombat;
  # ...
  # exit successfully
  flawless victory;

  use Mortal::Kombat;
  $screwedup and fatality "Scorpion has whomped you,";

=head1 DESCRIPTION

This is a gimmick module.  It merely gives you three functions, flawless(),
victory(), and fatality(), each of which can be used without parentheses for
a nice english look.

The suggested uses are:

  flawless victory;  # same as 'exit 0'

and

  fatality "some error message";  # same as die "some error message";

That's it.  If you've got any suggestions, you can email me.  Don't be
ashamed.

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut
