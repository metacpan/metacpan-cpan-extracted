# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Socket;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my (@sock, @sol, @so, @af, @pf, @constants);
my @functions    = qw/socket_names/;
our @IN_CORE     = qw//;   # to be added

our %EXPORT_TAGS =
  ( sock      => \@sock
  , so        => \@so
  , sol       => \@sol
  , af        => \@af
  , pf        => \@pf
  , constants => \@constants
  , functions => \@functions
  , tables    => [ qw/%sockets/ ]
  );

my ($socket, %socket);
BEGIN {
    $socket    = socket_table;
    @constants = sort keys %$socket;
    tie %socket, 'POSIX::1003::ReadOnlyTable', $socket;

    @sock      = grep /^SOCK/, @constants;
    @so        = grep /^SO_/,  @constants;
    @sol       = grep /^SOL_/, @constants;
    @af        = grep /^AF_/,  @constants;
    @pf        = grep /^PF_/,  @constants;
}


sub exampleValue($)
{   my ($class, $name) = @_;
    $socket{$name} // 'undef';
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $nr = $socket->{$name} // return sub() {undef};
    sub() {$nr};
}

#-------------

# get/setsockopt in XS

#------------

sub socket_names() { keys %$socket }

#------------

1;
