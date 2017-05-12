package Sed;

# -------------------------------------------------------------------
#
# $Id: Sed.pm,v 1.11 2002/01/23 13:16:17 dlc Exp $
#
# -------------------------------------------------------------------
#   Sed - A sed(1)-like stream editor
#
#   Copyright (C) 2001 darren chamberlain <darren@cpan.org>
#
#   This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# 
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this software. If not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION @EXPORT);

require Exporter;
use base qw(Exporter);
@EXPORT  = qw(sed);
$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/;

sub sed (&$) {
    my $sub = shift;
    local $_ = shift;
    &$sub;
    return $_;
}


1;
__END__

=head1 NAME

Sed - A sed(1)-like stream editor

=head1 SYNOPSIS

  my $a = "Hello, world";
  my $b = sed { s/l/0/g } $a;
  print "'$a' => '$b'";

  'Hello, world' => 'He00o, wor0d'

  # Comparison of map and sed:
  my $a = "Hello, world";
  my $b = map { s/l/0/g } $a;
  print "('$a', '$b')\n";

  # prints: ('He00o, wor0d', '1')

  my $a = "Hello, world";
  my $b = sed { s/l/0/g } $a;
  print "('$a', '$b')\n";

  # prints: ('Hello, world', 'He00o, wor0d')

  my $phone_num = "213-555-1212";
  my $clean_num = sed { tr/0-9//cd } $phone_num;
  print $clean_num;

  # prints: 2135551212


=head1 DESCRIPTION

Sed implements a stream editor (sed), like the standard Unix utility
of the same name.  sed is called with a regular expression (see below)
in curly braces as its first argument and a scalar as its second
argument.  A local copy of the scalar is made and the subroutine is
applied to it (the original scalar is not modified).

The regular expression can be of the s/// or tr/// forms, and must be
enclosed within { }.  For example:

    $b = sed { s/\[%\s*\(.*)?\s*%\]/$defined{$1}/g } $a;

    $d = sed { tr/a-zA-Z0-9//cd } $c;

    # From Tom Christiansen's striphtml:
    $f = sed {
            s{ <
                (?:
                    [^>'"] *
                        |
                    ".*?"
                        |
                    '.*?'
                ) +
            >
            }{}gsx;
        } $e;

=head1 EXAMPLES

  # This is the use for which I originally conceived Sed:
  package Foo;
  use Sed;
  use vars '$AUTOLOAD';

  sub AUTOLOAD {
      my $self = shift;
      my $autoload = sed { s/.*::// } $AUTOLOAD;
      return $self->{$autoload};
  }

=head1 AUTHOR

darren chamberlain <darren@cpan.org>
