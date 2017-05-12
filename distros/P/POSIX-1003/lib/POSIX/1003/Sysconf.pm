# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Sysconf;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

use Carp    'croak';

my @constants;
my @functions = qw/sysconf sysconf_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%sysconf' ]
  );

my  $sysconf;
our %sysconf;

BEGIN {
    # initialize the :constants export tag
    $sysconf = sysconf_table;
    push @constants, keys %$sysconf;
    tie %sysconf, 'POSIX::1003::ReadOnlyTable', $sysconf;
}

sub sysconf($);


sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_SC_/ or return;
    my $val = sysconf $name;
    defined $val ? $val : 'undef';
}


sub sysconf($)
{   my $key = shift // return;
    $key =~ /^_SC_/
        or croak "pass the constant name as string";
 
    my $id  = $sysconf->{$key}    // return;
    my $val = POSIX::sysconf($id) // return;
    $val+0;        # remove " but true" from "0"
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $sysconf->{$name} // return sub() {undef};
    sub() {POSIX::sysconf($id)};
}


sub sysconf_names() { keys %$sysconf }


1;
