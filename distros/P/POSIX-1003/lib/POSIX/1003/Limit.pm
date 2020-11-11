# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Limit;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use Carp    'croak';

my (@ulimit, @rlimit, @constants, @functions);
our %EXPORT_TAGS =
  ( ulimit    => \@ulimit
  , rlimit    => \@rlimit
  , constants => \@constants
  , functions => \@functions
  , tables    => [ qw/%ulimit %rlimit/ ]
  );

my  ($ulimit, $rlimit);
our (%ulimit, %rlimit);
my  ($rlim_saved_max, $rlim_saved_cur, $rlim_infinity);

BEGIN {
    my @ufuncs = qw/ulimit ulimit_names/;
    my @rfuncs = qw/getrlimit setrlimit rlimit_names/;
    my @rconst = qw/RLIM_SAVED_MAX RLIM_SAVED_CUR RLIM_INFINITY/;

    $ulimit    = ulimit_table;
    @ulimit    = (keys %$ulimit, @ufuncs, '%ulimit');
    tie %ulimit, 'POSIX::1003::ReadOnlyTable', $ulimit;

    $rlimit    = rlimit_table;
    @rlimit    = (keys %$rlimit, @rfuncs, @rconst, '%rlimit');
    tie %rlimit, 'POSIX::1003::ReadOnlyTable', $rlimit;

    push @constants, keys %$ulimit, keys %$rlimit;
    push @functions, @ufuncs, @rfuncs;

    $rlim_saved_max = delete $rlimit->{RLIM_SAVED_MAX};
    $rlim_saved_cur = delete $rlimit->{RLIM_SAVED_CUR};
    $rlim_infinity  = delete $rlimit->{RLIM_INFINITY};
}

sub RLIM_SAVED_MAX { $rlim_saved_max }
sub RLIM_SAVED_CUR { $rlim_saved_cur }
sub RLIM_INFINITY  { $rlim_infinity  }

sub getrlimit($);
sub setrlimit($$;$);
sub ulimit($;$);


sub exampleValue($)
{   my ($class, $name) = @_;
    if($name =~ m/^RLIMIT_/)
    {   my ($soft, $hard, $success) = getrlimit $name;
        for($soft,$hard)
        {   $_ //= 'undef';
            s/18446744073709551615/2**64-1/g;
            s/9223372036854775807/2**63-1/g;
        }
        return "$rlimit->{$name}, $soft, $hard";
    }
    elsif($name =~ m/^RLIM_/)
    {   return $rlimit->{$name} // 'undef';
    }
    elsif($name =~ m/^UL_GET|^GET_/)
    {   my $val = ulimit $name;
        return defined $val ? $val : 'undef';
    }
    elsif($name =~ m/^UL_SET|^SET_/)
    {   return '(setter)';
    }
    else
    {   $class->SUPER::exampleValue($name);
    }
}


sub ulimit($;$)
{   my $key = shift // return;
    if(@_)
    {   $key =~ /^UL_SET|^SET_/
            or croak "pass the constant name as string ($key)";
        my $id  = $ulimit->{$key} // return;
        return _ulimit($id, shift);
    }
    else
    {   $key =~ /^UL_GET|^GET_/
            or croak "pass the constant name as string ($key)";
        my $id  = $ulimit->{$key} // return;
        _ulimit($id, 0);
    }
}

sub _create_constant($)
{   my ($class, $name) = @_;
    if($name =~ m/^RLIMIT_/)
    {   my $id = $rlimit->{$name} // return sub() {undef};
        return sub(;$$) { @_ ? _setrlimit($id, $_[0], $_[1]) : (_getrlimit($id))[0] };
    }
    else
    {   my $id = $ulimit->{$name} // return sub() {undef};
        return $name =~ m/^UL_GET|^GET_/
           ? sub() {_ulimit($id, 0)} : sub($) {_ulimit($id, shift)};
    }
}


sub getrlimit($)
{   my $key = shift // return;
    $key =~ /^RLIMIT_/
        or croak "pass the constant name as string ($key)";
 
    my $id  = $rlimit->{$key};
    defined $id ? _getrlimit($id) : ();
}


sub setrlimit($$;$)
{   my ($key, $cur, $max) = @_;
    $key =~ /^RLIMIT_/
        or croak "pass the constant name as string ($key)";
 
    my $id  = $rlimit->{$key};
    $max //= RLIM_INFINITY;
    defined $id ? _setrlimit($id, $cur, $max) : ();
}


sub ulimit_names() { keys %$ulimit }


sub rlimit_names() { keys %$rlimit }



1;
