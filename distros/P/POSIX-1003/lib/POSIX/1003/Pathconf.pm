# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Pathconf;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

use Carp 'croak';

my @constants;
my @functions = qw/pathconf fpathconf pathconf_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%pathconf' ]
  );

my  $pathconf;
our %pathconf;

BEGIN {
    # initialize the :constants export tag
    $pathconf = pathconf_table;
    push @constants, keys %$pathconf;
    tie %pathconf, 'POSIX::1003::ReadOnlyTable', $pathconf;
}

sub pathconf($$);


sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_PC_/ or return;
    my $val = pathconf __FILE__, $name;
    defined $val ? $val : 'undef';
}


sub fpathconf($$)
{   my ($fd, $key) = @_;
    $key =~ /^_PC_/
        or croak "pass the constant name as string";
    my $id = $pathconf{$key} // return;
    my $v  = POSIX::fpathconf($fd, $id);
    defined $v && $v eq '0 but true' ? 0 : $v;
}

sub pathconf($$)
{   my ($fn, $key) = @_;
    $key =~ /^_PC_/
        or croak "pass the constant name as string";
    my $id = $pathconf{$key} // return;
    my $v = POSIX::pathconf($fn, $id);
    defined $v ? $v+0 : undef;  # remove 'but true' from '0'
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $pathconf->{$name} // return sub($) {undef};
    sub($) { my $f = shift;
               $f =~ m/\D/
             ? POSIX::pathconf($f, $id)
             : POSIX::fpathconf($f, $id)
           };
}


sub pathconf_names() { keys %$pathconf }

