use strict;
use warnings;

package Sub::WrapPackages;

our $VERSION;
our %ORIGINAL_SUBS; # coderefs of what we're wrapping, keyed
                    #   by package::sub
our @MAGICINCS;     # list of magic INC subs, used by lib.pm hack
our %INHERITED;     # coderefs of inherited methods (before proxies
                    #   installed), keys by package::sub
our %WRAPPED_BY_WRAPPER; # coderefs of original subs, keyed by
                         #   stringified coderef of wrapper
our %WRAPPER_BY_WRAPPED; # coderefs of wrapper subs, keyed by
                         #   stringified coderef of original sub
use Sub::Prototype ();
use Devel::Caller::IgnoreNamespaces;
Devel::Caller::IgnoreNamespaces::register(__PACKAGE__);

use Data::Dumper;
$Data::Dumper::Deparse = 1;

$VERSION = '2.02';

use lib ();
{
    no strict 'refs';
    no warnings 'redefine';
    
    my $originallibimport = \&{'lib::import'};
    my $newimport = sub {
        $originallibimport->(@_);
        my %magicincs = map { $_, 1 } @Sub::WrapPackages::MAGICINCS;
        @INC = (
            (grep { exists($magicincs{$_}); } @INC),
            (grep { !exists($magicincs{$_}); } @INC)
        );
    };
    
    *{'lib::import'} = $newimport;
}


=head1 NAME

Sub::WrapPackages - add pre- and post-execution wrappers around all the
subroutines in packages or around individual subs

=head1 SYNOPSIS

    use Sub::WrapPackages
        packages => [qw(Foo Bar Baz::*)],   # wrap all subs in Foo and Bar
                                            #   and any Baz::* packages
        subs     => [qw(Barf::a, Barf::b)], # wrap these two subs as well
        wrap_inherited => 1,                # and wrap any methods
                                            #   inherited by Foo, Bar, or
                                            #   Baz::*
        except   => qr/::w[oi]bble$/,       # but don't wrap any sub called
                                            #   wibble or wobble
        pre      => sub {
            print "called $_[0] with params ".
              join(', ', @_[1..$#_])."\n";
        },
        post     => sub {
            print "$_[0] returned $_[1]\n";
        };

=head1 COMPATIBILITY

While this module does broadly the same job as the 1.x versions did,
the interface may have changed incompatibly.  Sorry.  Hopefully it'll
be more maintainable and slightly less crazily magical.  Also, caller()
should now work properly, ignoring wrappings.

=head1 DESCRIPTION

This module installs pre- and post- execution subroutines for the
subroutines or packages you specify.  The pre-execution subroutine
is passed the
wrapped subroutine's name and all its arguments.  The post-execution
subroutine is passed the wrapped sub's name and its results.

The return values from the pre- and post- subs are ignored, and they
are called in the same context (void, scalar or list) as the calling
code asked for.

Normal usage is to pass a bunch of parameters when the module is used.
However, you can also call Sub::WrapPackages::wrapsubs with the same
parameters.

=head1 PARAMETERS

Either pass parameters on loading the module, as above, or pass them
to ...

=head2 the wrapsubs subroutine

=over 4

=item the subs arrayref

In the synopsis above, you will see two named parameters, C<subs> and
C<packages>.  Any subroutine mentioned in C<subs> will be wrapped.
Any subroutines mentioned in 'subs' must already exist - ie their modules
must be loaded - at the time you try to wrap them.

=item the packages arrayref

Any package mentioned here will have all its subroutines wrapped,
including any that it imports at load-time.  Packages can be loaded
in any order - they don't have to already be loaded for Sub::WrapPackages
to work its magic.

You can specify wildcard packages.  Anything ending in ::* is assumed
to be such.  For example, if you specify Orchard::Tree::*, then that
matches Orchard::Tree, Orchard::Tree::Pear, Orchard::Apple::KingstonBlack
etc, but not - of course - Pine::Tree or My::Orchard::Tree.

Note, however, that if a module exports a subroutine at load-time using
C<import> then that sub will be wrapped in the exporting module but not in
the importing module.  This is because import() runs before we get a chance
to fiddle with things.  Sorry.

Deferred wrapping of subs in packages that aren't yet loaded works
via a subroutine inserted in @INC.  This means that if you mess around
with @INC, eg by inserting a directoy at the beginning of the path, the
magic might not get a chance to run.  If you C<use lib> to mess with
@INC though, it should work, as I've over-ridden lib's import() method.
That said, code this funky has no right to work.  Use with caution!

=item wrap_inherited

In conjunction with the C<packages> arrayref, this wraps all calls to
inherited methods made through those packages.  If you call those
methods directly in the superclass then they are not affected - unless
they're wrapped in the superclass of course.

=item pre and post

References to the subroutines you want to use as wrappers.

=item except

A regex, any subroutine whose fully-qualified name (ie including the package
name) matches this will not be wrapped.

=item debug

This exists, but probably isn't of much use unless you want to hack on
Sub::WrapPackage's guts.

=back

=head1 BUGS

AUTOLOAD and DESTROY are not treated as being special.  I'm not sure
whether they should be or not.

If you use wrap_inherited but classes change their inheritance tree at
run-time, then very bad things will happen. VERY BAD THINGS.  So don't
do that.  You shouldn't be doing that anyway.  Mind you, you shouldn't
be doing the things that this module does either.  BAD PROGRAMMER, NO
BIKKIT!

Bug reports should be made on Github or by email.

=head1 FEEDBACK

I like to know who's using my code.  All comments, including constructive
criticism, are welcome.  Please email me.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Sub-WrapPackages.git>

=head1 COPYRIGHT and LICENCE

Copyright 2003-2009 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 THANKS TO

Thanks to Tom Hukins for sending in a test case for the situation when
a class and a subclass are both defined in the same file, and for
prompting me to support inherited methods;

to Dagfinn Ilmari Mannsaker for help with the craziness for
fiddling with modules that haven't yet been loaded;

to Lee Johnson for reporting a bug caused by perl 5.10's
constant.pm being Far Too Clever, and providing a patch and test;

to Adam Trickett who thought this was a jolly good idea;

to Ed
Summers, whose code for figgering out what functions a package contains
I borrowed out of L<Acme::Voodoo>;

and to Yanick Champoux for numerous readability improvements.

=cut

sub import {
    shift;
    wrapsubs(@_);
}

sub _subs_in_packages {
    my @targets = map { $_.'::' } @_;

    my @subs;
    foreach my $package (@targets) {
        no strict;
        while(my($k, $v) = each(%{$package})) {
            push @subs, $package.$k if(ref($v) ne 'SCALAR' && defined(&{$v}));
        }
    }
    return @subs;
}

sub _make_magic_inc {
    my %params = @_;
    my $wildcard_packages = [map { (my $p = $_) =~ s/::.$//; $p; } grep { /::\*$/ } @{$params{packages}}];
    my $nonwildcard_packages = [grep { $_ !~ /::\*$/ } @{$params{packages}}];

    push @MAGICINCS, sub {
        my($me, $file) = @_;
        (my $module = $file) =~ s{/}{::}g;
        $module =~ s/\.pm//;
        return undef unless(
            (grep { $module =~ /^$_(::|$)/ } @{$wildcard_packages}) ||
            (grep { $module eq $_ } @{$nonwildcard_packages})
        );
        local @INC = grep { $_ ne $me } @INC;
        local $/;
        my @files = grep { -e $_ } map { join('/', $_, $file) } @INC;
        open(my $fh, $files[0]) || die("Can't locate $file in \@INC\n");
        my $text = <$fh>;
        close($fh);

        if(!%Sub::WrapPackages::params) {
          print STDERR "Setting \%Sub::WrapPackages::params\n", Dumper(\%params)
            if($params{debug});
          %Sub::WrapPackages::params = %params;
        }

        $text =~ /(.*?)(__DATA__.*|__END__.*|$)/s;
        my($code, $trailer) = ($1, $2);
        $text = $code.qq[
            ;
            Sub::WrapPackages::wrapsubs(
                %Sub::WrapPackages::params,
                packages => [qw($module)]
            );
            1;
        ]."\n$trailer";
        open($fh, '<', \$text);
        $fh;
    };
    unshift @INC, $MAGICINCS[-1];
}

sub _getparents {
    my $package = shift;
    my @parents = eval '@'.$package.'::ISA';
    return @parents, (map { _getparents($_) } @parents);
}

sub wrapsubs {
    my %params = @_;

    if(exists($params{packages}) && ref($params{packages}) =~ /^ARRAY/) {
        my $wildcard_packages = [map { (my $foo = $_) =~ s/::.$//; $foo; } grep { /::\*$/ } @{$params{packages}}];
        my $nonwildcard_packages = [grep { $_ !~ /::\*$/ } @{$params{packages}}];

        # defer wrapping stuff that's not yet loaded
        _make_magic_inc(%params);

        # wrap wildcards that are loaded
        if(@{$wildcard_packages}) {
            foreach my $loaded (map { (my $f = $_) =~ s!/!::!g; $f =~ s/\.pm$//; $f } keys %INC) {
                my $pattern = '^('.join('|', @{$wildcard_packages}).')(::|$)';
                if($loaded =~ /$pattern/) {
                  print STDERR "found loaded wildcard $loaded - matches $pattern\n" if($params{debug});
                  wrapsubs(%params, packages => [$loaded]);
                }
            }
        }

        # wrap non-wildcards that are loaded
        if($params{wrap_inherited}) {
            foreach my $package (@{$nonwildcard_packages}) {
                my @parents = _getparents($package);

                # get inherited (but not over-ridden!) subs
                my %subs_in_package = map {
                    (split '::' )[-1] => 1
                } _subs_in_packages($package);

                my @subs_to_define = grep {
                    !exists($subs_in_package{$_})
                } map { 
                    (split '::' )[-1]
                } _subs_in_packages(@parents);

                # define proxy method that just does a goto to get
                # to the right place.  We then later wrap the proxy
                foreach my $sub (@subs_to_define) {
                    next if(exists($INHERITED{$package."::$sub"}));
                    $INHERITED{$package."::$sub"} = $package->can($sub);
                    # if the inherited method is already wrapped,
                    #   point this proxy at the original method
                    #   so we don't wrap a wrapper
                    if(exists($WRAPPED_BY_WRAPPER{$INHERITED{$package."::$sub"}})) {
                        $INHERITED{$package."::$sub"} =
                            $WRAPPED_BY_WRAPPER{$INHERITED{$package."::$sub"}};
                    }
                    eval qq{
                        sub ${package}::$sub {
                            goto &{\$Sub::WrapPackages::INHERITED{"${package}::$sub"}};
                        }
                    };
                    die($@) if($@);
                    print STDERR "created stub ${package}::$sub for inherited method\n" if($params{debug});
                }
            }
        }
        push @{$params{subs}}, _subs_in_packages(@{$params{packages}});
    } elsif(exists($params{packages})) {
        die("Bad param 'packages'");
    }

    return undef if(!$params{pre} && !$params{post});
    $params{pre} ||= sub {};
    $params{post} ||= sub {};

    foreach my $sub (@{$params{subs}}) {
        next if(
          (exists($params{except}) && $sub =~ $params{except}) ||
          exists($ORIGINAL_SUBS{$sub})
        );

        $ORIGINAL_SUBS{$sub} = \&{$sub};
        my $imposter = sub {
            local *__ANON__ = $sub;
            my(@r, $r) = ();
            my $wa = wantarray();
            if(!defined($wa)) {
                $params{pre}->($sub, @_);
                $ORIGINAL_SUBS{$sub}->(@_);
                $params{post}->($sub);
            } elsif($wa) {
                my @f = $params{pre}->($sub, @_);
                @r = $ORIGINAL_SUBS{$sub}->(@_);
                @f = $params{post}->($sub, @r);
            } else {
                my $f = $params{pre}->($sub, @_);
                $r = $ORIGINAL_SUBS{$sub}->(@_);
                $f = $params{post}->($sub, $r);
            }
            return wantarray() ? @r : $r;
        };
        Sub::Prototype::set_prototype($imposter, prototype($ORIGINAL_SUBS{$sub}))
            if(prototype($ORIGINAL_SUBS{$sub}));

        {
            no strict 'refs';
            no warnings 'redefine';
            $WRAPPED_BY_WRAPPER{$imposter} = $ORIGINAL_SUBS{$sub};
            $WRAPPER_BY_WRAPPED{$ORIGINAL_SUBS{$sub}} = $imposter;

            *{$sub} = $imposter;
            print STDERR "wrapped $sub\n" if($params{debug});
        };
    }
}

1;
