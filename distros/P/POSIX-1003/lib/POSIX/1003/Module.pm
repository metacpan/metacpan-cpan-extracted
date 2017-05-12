# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;
use warnings;

package POSIX::1003::Module;
use vars '$VERSION';
$VERSION = '0.98';


# The VERSION of the distribution is sourced from this file, because
# this module also loads the XS extension.
our $VERSION = '0.98';
use Carp 'croak';

{ use XSLoader;
  no warnings 'redefine';
  XSLoader::load 'POSIX';
  XSLoader::load 'POSIX::1003', $VERSION;
}

# also used in release-test
our $in_constant_table = qr/
   ^_CS_    # confstr
 | ^DN_     # fcntl
 | ^E(?!CHONL|XIT_) # errno   ECHONL in Termios, EXIT_ in Proc
 | ^FCNTL   # fcntl
 | ^F_      # fcntl
 | ^FD_     # fcntl
 | ^GET_    # rlimit
 | ^LOCK_   # fcntl
 | ^O_      # fdio
 | ^_PC_    # pathconf
 | ^POLL    # poll
 | ^_POSIX  # property
 | ^RLIM    # rlimit
 | ^SA_     # sigaction
 | ^S_      # stat
 | ^_SC_    # sysconf
 | ^SEEK_   # fdio
 | ^SET_    # rlimit aix
 | ^SIG[^_] # signals
 | ^UL_     # ulimit
 | ^WSAE    # errno (windows sockets)
 | _OK$     # access
 /x;


sub import(@)
{   my $class = shift;
    return if $class eq __PACKAGE__;

    no strict 'refs';
    no warnings 'once';

    my $tags = \%{"${class}::EXPORT_TAGS"} or die;

    # A hash-lookup is faster than an array lookup, so %EXPORT_OK
    %{"${class}::EXPORT_OK"} = ();
    my $ok   = \%{"${class}::EXPORT_OK"};
    unless(keys %$ok)
    {   @{$ok}{@{$tags->{$_}}} = () for keys %$tags;
    }

    my $level = @_ && $_[0] =~ m/^\+(\d+)$/ ? shift : 0;
    return if @_==1 && $_[0] eq ':none';
    @_ = ':all' if !@_;

    my %take;
    foreach (@_)
    {   if( $_ eq ':all')
        {   @take{keys %$ok} = ();
        }
        elsif( m/^:(.*)/ )
        {   my $tag = $tags->{$1} or croak "$class does not export $_";
            @take{@$tag} = ();
        }
        else
        {   $_ =~ $in_constant_table or exists $ok->{$_}
               or croak "$class does not export $_";
            undef $take{$_};
        }
    }

    my $in_core = \@{$class.'::IN_CORE'} || [];

    my $pkg = (caller $level)[0];
    foreach my $f (sort keys %take)
    {   my $export;
        if(exists ${$class.'::'}{$f} && ($export = *{"${class}::$f"}{CODE}))
        {   # reuse the already created function; might also be a function
            # which is actually implemented in the $class namespace.
        }
        elsif($f =~ $in_constant_table)
        {   *{$class.'::'.$f} = $export = $class->_create_constant($f);
        }
        elsif( $f !~ m/[^A-Z0-9_]/ )  # faster than: $f =~ m!^[A-Z0-9_]+$!
        {   # other all-caps names are always from POSIX.xs
            if(exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE})
            {   # POSIX.xs croaks on undefined constants, we will return undef
                my $const = eval "POSIX::$f()";
                *{$class.'::'.$f} = $export
                  = defined $const ? sub() {$const} : sub() {undef};
            }
            else
            {   # ignore the missing value
#               warn "missing constant in POSIX.pm $f" && next;
                *{$class.'::'.$f} = $export = sub() {undef};
            }
        }
        elsif(exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE})
        {   # normal functions implemented in POSIX.xs
            *{"${class}::$f"} = $export = *{"POSIX::$f"}{CODE};
        }
        elsif($f =~ s/^%//)
        {   $export = \%{"${class}::$f"};
        }
        elsif($in_core && grep $f eq $_, @$in_core)
        {   # function is in core, simply ignore the export
            next;
        }
        else
        {   croak "unable to load $f from $class";
        }

        no warnings 'once';
        *{"${pkg}::$f"} = $export;
    }
}


sub exampleValue($)
{   my ($pkg, $name) = @_;
    no strict 'refs';

    my $tags      = \%{"$pkg\::EXPORT_TAGS"} or die;
    my $constants = $tags->{constants} || [];
    grep $_ eq $name, @$constants
        or return undef;

    my $val = &{"$pkg\::$name"};
    defined $val ? $val : 'undef';
}

package POSIX::1003::ReadOnlyTable;
use vars '$VERSION';
$VERSION = '0.98';

sub TIEHASH($) { bless $_[1], $_[0] }
sub FETCH($)   { $_[0]->{$_[1]} }
sub EXISTS($)  { exists $_[0]->{$_[1]} }
sub FIRSTKEY() { scalar %{$_[0]}; scalar each %{$_[0]} }
sub NEXTKEY()  { scalar each %{$_[0]} }

1;
