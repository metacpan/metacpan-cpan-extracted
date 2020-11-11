# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.
package POSIX::1003;
use vars '$VERSION';
$VERSION = '1.02';


use warnings;
use strict;

use Carp qw/croak/;
use POSIX::1003::Module ();   # preload

my %own_functions = map +($_ => 1), qw/
    posix_1003_modules
    posix_1003_names
    show_posix_names
   /;

our (%EXPORT_TAGS, %IMPORT_FROM, %SUBSET);


my %tags =
  ( confstr =>     'POSIX::1003::Confstr'
  , cs =>          'POSIX::1003::Confstr'
  , errno =>       'POSIX::1003::Errno'
  , errors =>      'POSIX::1003::Errno'
  , events =>      'POSIX::1003::Events'
  , ev =>          'POSIX::1003::Events'
  , fcntl =>       'POSIX::1003::Fcntl'
  , fdio =>        'POSIX::1003::FdIO'
  , fd =>          'POSIX::1003::FdIO'
  , filesystem =>  'POSIX::1003::FS'
  , fs =>          'POSIX::1003::FS'
  , glob =>        'POSIX::1003::FS'
  , limit =>       'POSIX::1003::Limit'
  , limits =>      'POSIX::1003::Limit'
  , locale =>      'POSIX::1003::Locale'
  , math =>        'POSIX::1003::Math'
  , os =>          'POSIX::1003::OS'
  , opsys =>       'POSIX::1003::OS'
  , pathconf =>    'POSIX::1003::Pathconf'
  , pc =>          'POSIX::1003::Pathconf'
  , processes =>   'POSIX::1003::Proc'
  , proc =>        'POSIX::1003::Proc'
  , properties =>  'POSIX::1003::Properties'
  , property =>    'POSIX::1003::Properties'
  , props =>       'POSIX::1003::Properties'
  , posix =>       'POSIX::1003::Properties'
  , sc =>          'POSIX::1003::Sysconf'
  , sigaction =>   'POSIX::SigAction'
  , signals =>     [qw/POSIX::1003::Signals POSIX::SigSet POSIX::SigAction/]
  , sigset =>      'POSIX::SigSet'
  , socket =>      'POSIX::1003::Socket'
  , sysconf =>     'POSIX::1003::Sysconf'
  , termio =>      'POSIX::1003::Termios'
  , termios =>     'POSIX::1003::Termios'
  , time =>        'POSIX::1003::Time'
  , user =>        'POSIX::1003::User'
  );

my %mod_tag;
while(my ($tag, $pkg) = each %tags)
{   $pkg = $pkg->[0] if ref $pkg eq 'ARRAY';
    $mod_tag{$pkg} = $tag
        if !$mod_tag{$pkg}
        || length $mod_tag{$pkg} < length $tag;
}

{   eval "require POSIX::1003::Symbols";
    die $@ if $@;
}

while(my ($pkg, $tag) = each %mod_tag)  # unique modules
{   $IMPORT_FROM{$_} = $tag for @{$EXPORT_TAGS{$tag}};
}

sub _tag2mods($)
{   my $tag = shift;
    my $r   = $tags{$tag} or croak "unknown tag '$tag'";
    ref $r eq 'ARRAY' ? @$r : $r;
}

sub _mod2tag($) { $mod_tag{$_[0]} }
sub _tags()     { keys %tags}

sub import(@)
{   my $class = shift;
    my (%mods, %modset, %from);

    my $level = @_ && $_[0] =~ /^\+(\d+)$/ ? shift : 0;
    return if @_==1 && $_[0] eq ':none';
    @_ = ':all' if !@_;

    no strict   'refs';
    no warnings 'once';
    my $to    = (caller $level)[0];

    foreach (@_)
    {   if($_ eq ':all')
        {   $mods{$_}++ for values %mod_tag;
            *{$to.'::'.$_} = \&$_ for keys %own_functions;
        }
        elsif(m/^\:(.*)/)
        {   if(exists $tags{$1})
            {   # module by longest alias
                $mods{$_}++ for map $mod_tag{$_}, _tag2mods $1;
            }
            elsif(my $subset = $SUBSET{$1})
            {   push @{$modset{$subset}}, $1;
            }
            else { croak "unknown tag '$_'" };
        }
        elsif($own_functions{$_})
        {   *{$to.'::'.$_} = \&$_;
        }
        else
        {   my $mod = $IMPORT_FROM{$_} or croak "unknown symbol '$_'";
            push @{$from{$mod}}, $_;
        }
    }

    # no need for separate symbols when we need all
    delete $from{$_} for keys %mods;

#print "from $_ all\n"          for keys %mods;
#print "from $_ @{$from{$_}}\n" for keys %from;

    my $up = '+' . ($level+1);
    foreach my $tag (keys %mods)     # whole tags
    {   delete $modset{$tag};
        delete $from{$tag};
        foreach my $pkg (_tag2mods($tag))
        {   eval "require $pkg"; die $@ if $@;
            $pkg->import($up, ':all');
        }
    }
    foreach my $tag (keys %modset)
    {   foreach my $pkg (_tag2mods($tag))
        {   eval "require $pkg"; die $@ if $@;
            my @subsets = @{$modset{$tag}};
            my $et = \%{"$pkg\::EXPORT_TAGS"};
            $pkg->import($up, @{$et->{$_}})
               for @subsets;
        }
    }
    foreach my $tag (keys %from)     # separate symbols
    {   foreach my $pkg (_tag2mods($tag))
        {   eval "require $pkg"; die $@ if $@;
            $pkg->import($up, @{$from{$tag}});
        }
   }
}


sub posix_1003_modules()
{   my %mods;
    foreach my $mods (values %tags)
    {   $mods{$_}++ for ref $mods eq 'ARRAY' ? @$mods : $mods;
    }
    keys %mods;
}


sub posix_1003_names(@)
{   my %names;
    my @modules;
    if(@_)
    {   my %mods;
        foreach my $sel (@_)
        {   $mods{$_}++ for $sel =~ m/^:(\w+)/ ? _tag2mods($1) : $sel;
        }
        @modules = keys %mods;
    }
    else
    {   @modules = posix_1003_modules;
    }

    foreach my $pkg (@modules)
    {   eval "require $pkg";
        $@ && next;  # die?
        $pkg->can('import') or next;
        $pkg->import(':none');   # create %EXPORT_OK

        no strict 'refs';
        my $exports = \%{"${pkg}::EXPORT_OK"};
        $names{$_} = $pkg for keys %$exports;
    }

    wantarray ? keys %names : \%names;
}


sub show_posix_names(@)
{   my $pkg_of = posix_1003_names @_;
    my %order  = map {(my $n = lc $_) =~ s/[^A-Za-z0-9]//g; ($n => $_)}
        keys %$pkg_of;  # Swartzian transform

    no strict 'refs';
    foreach (sort keys %order)
    {   my $name = $order{$_};
        my $pkg  = $pkg_of->{$name};
        $pkg->import($name);
        my $val  = $pkg->exampleValue($name);
        (my $abbrev = $pkg) =~ s/^POSIX\:\:1003\:\:/::/;
        my $mod  = $mod_tag{$pkg};
        if(defined $val)
        {   printf "%-12s :%-10s %-30s %s\n", $abbrev, $mod, $name, $val;
        }
        else
        {   printf "%-12s :%-10s %s\n", $abbrev, $mod, $name;
        }
    }
    print "*** ".(keys %$pkg_of)." symbols in total\n";
}

#------------

1;
