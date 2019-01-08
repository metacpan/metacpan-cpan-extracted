package Module::Patch;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.275'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Monkey::Patch::Action qw();
use Package::Stash;
use Package::Util::Lite qw(package_exists);

our @EXPORT_OK = qw(patch_package);

sub is_loaded {
    my $mod = shift;

    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    exists($INC{$mod_pm}) && $INC{$mod_pm};
}

my%loaded_by_us;

sub import {
    my $self = shift;

    my $caller = caller;

    if ($self eq __PACKAGE__) {
        # we are not subclassed, provide exports
        for my $exp (@_) {
            die "$exp is not exported by ".__PACKAGE__
                unless grep { $_ eq $exp } @EXPORT_OK;
            *{"$caller\::$exp"} = \&{$_};
        }
    } else {
        # we are subclassed, patch caller with patch_data()
        my %opts = @_;

        my $load;
        if (exists $opts{-load_target}) {
            $load = $opts{-load_target};
            delete $opts{-load_target};
        }
        $load //= 1;
        my $force;
        if (exists $opts{-force}) {
            $force = $opts{-force};
            delete $opts{-force};
        }
        $force //= 0;
        my $warn;
        if (exists $opts{-warn_target_loaded}) {
            $warn = $opts{-warn_target_loaded};
            delete $opts{-warn_target_loaded};
        }
        $warn //= 1;

        # patch already applied, ignore
        return if ${"$self\::handles"};

        unless (${"$self\::patch_data_cached"}) {
            ${"$self\::patch_data_cached"} = $self->patch_data;
        }

        my $pdata = ${"$self\::patch_data_cached"} or
            die "BUG: $self: No patch data supplied";
        my $v = $pdata->{v} // 1;
        my $curv = 3;
        if ($v == 1 || $v == 2) {
            my $mpv;
            if ($v == 1) {
                $mpv = "0.06 or earlier";
            } elsif ($v == 2) {
                $mpv = "0.07-0.09";
            }
            die "$self ".( ${"$self\::VERSION" } // "?" ).
                " requires Module::Patch $mpv (patch_data format v=$v),".
                " this is Module::Patch ".($Module::Patch::VERSION // '?').
                " (v=$curv), please install an older version of ".
                "Module::Patch or upgrade $self";
        } elsif ($v == 3) {
            # ok, current version
        } else {
            die "BUG: $self: Unknown patch_data format version ($v), ".
                "only v=$curv supported by this version of Module::Patch";
        }

        my $target = $self;
        $target =~ s/(?<=\w)::[Pp]atch::\w+$//
            or die "BUG: $self: Bad patch module name '$target', it should ".
                "end with '::Patch::YourCategory'";

        if (is_loaded($target)) {
            if (!$loaded_by_us{$target}) {
                if ($load && $warn) {
                    warn "$target is loaded before ".__PACKAGE__.", this is ".
                        "not recommended since $target might export subs ".
                        "before " . __PACKAGE__." gets the chance to patch " .
                        "them";
                }
            }
        } else {
            if ($load) {
                eval "package $caller; use $target";
                die if $@;
                $loaded_by_us{$target}++;
            } else {
                if ($warn) {
                    warn "$target does not exist and we are told not to load ".
                        "it, skipped patching";
                }
                return;
            }
        }

        # read patch module's configs
        no warnings 'once';
        my $pcdata = $pdata->{config} // {};
        my $config = \%{"$self\::config"};
        while (my ($k, $v) = each %$pcdata) {
            die "Invalid configuration defined by $self\::patch_data(): ".
                "$k: must start with dash" unless $k =~ /\A-/;
            $config->{$k} = $v->{default};
            if (exists $opts{$k}) {
                $config->{$k} = $opts{$k};
                delete $opts{$k};
            }
        }

        if (keys %opts) {
            die "$self: Unknown option(s): ".join(", ", keys %opts);
        }

        if ($pdata->{after_read_config}) {
            $pdata->{after_read_config}->();
        }

        if ($pdata->{before_patch}) {
            $pdata->{before_patch}->();
        }

        log_trace "Module::Patch: patching $target with $self ...";
        ${"$self\::handles"} = patch_package(
            $target, $pdata->{patches},
            {force=>$force, patch_module=>ref($self) || $self});

        if ($pdata->{after_patch}) {
            $pdata->{after_patch}->();
        }

    }
}

sub unimport {
    my $self = shift;

    if ($self eq __PACKAGE__) {
        # we are not subclassed, do nothing
    } else {
        my $pdata = ${"$self\::patch_data_cached"} or
            die "BUG: $self: No patch data supplied";

        if ($pdata->{before_unpatch}) {
            $pdata->{before_unpatch}->();
        }

        my $handles = ${"$self\::handles"};
        log_trace "Module::Patch: Unpatching $self ...";
        undef ${"$self\::handles"};
        # do we need to undef ${"$self\::config"}?, i'm thinking not really

        if ($pdata->{after_unpatch}) {
            $pdata->{after_unpatch}->();
        }

    }
}

sub patch_data {
    die "BUG: patch_data() should be provided by subclass";
}

sub patch_package {
    my ($package0, $patches_spec, $opts) = @_;
    $opts //= {};

    my $handles = {};
    for my $target (ref($package0) eq 'ARRAY' ? @$package0 : ($package0)) {
        die "FATAL: Target module '$target' not loaded"
            unless package_exists($target);
        my $target_version = ${"$target\::VERSION"};
        my $target_subs;

        my $i = 0;
      PATCH:
        for my $pspec (@$patches_spec) {
            my $act = $pspec->{action};
            my $errp = ($opts->{patch_module} ? "$opts->{patch_module}: ":"").
                "patch[$i]"; # error prefix
            $act or die "BUG: $errp: no action supplied";
            $act =~ /\A(wrap|add|replace|add_or_replace|delete)\z/ or die
                "BUG: $errp: action '$pspec->{action}' unknown";
            if ($act eq 'delete') {
                $pspec->{code} and die "BUG: $errp: for action 'delete', ".
                    "code must not be supplied";
            } else {
                $pspec->{code} or die "BUG: $errp: code not supplied";
            }

            my $sub_names = ref($pspec->{sub_name}) eq 'ARRAY' ?
                [@{ $pspec->{sub_name} }] : [$pspec->{sub_name}];
            for (@$sub_names) {
                $_ = qr/.*/    if $_ eq ':all';
                $_ = qr/^_/    if $_ eq ':private';
                $_ = qr/^[^_]/ if $_ eq ':public';
                die "BUG: $errp: unknown tag in sub_name $_" if /^:/;
            }

            my @s;
            for my $sub_name (@$sub_names) {
                if (ref($sub_name) eq 'Regexp') {
                    unless ($target_subs) {
                        $target_subs = [Package::Stash->new($target)->list_all_symbols("CODE")];
                    }
                    for (@$target_subs) {
                        push @s, $_ if $_ !~~ @s && $_ =~ $sub_name;
                    }
                } else {
                    push @s, $sub_name;
                }
            }

            unless (!defined($pspec->{mod_version}) ||
                        $pspec->{mod_version} eq ':all') {
                defined($target_version) && length($target_version)
                    or die "FATAL: Target package '$target' does not have ".
                    "\$VERSION";
                my $mod_versions = $pspec->{mod_version};
                $mod_versions = ref($mod_versions) eq 'ARRAY' ?
                    [@$mod_versions] : [$mod_versions];
                for (@$mod_versions) {
                    $_ = qr/.*/    if $_ eq ':all';
                    die "BUG: $errp: unknown tag in mod_version $_"
                        if /^:/;
                }

                unless (grep {
                    ref($_) eq 'Regexp' ? $target_version =~ $_ : $target_version eq $_
                } @$mod_versions) {
                    warn "$errp: Target module version $target_version ".
                        "does not match [".join(", ", @$mod_versions)."], ".
                        ($opts->{force} ?
                         "patching anyway (force)":"skipped"). ".";
                    next PATCH unless $opts->{force};
                }
            }

            for my $s (@s) {
                #log_trace("Patching %s ...", $s);
                $handles->{"$target\::$s"} =
                    Monkey::Patch::Action::patch_package(
                        $target, $s, $act, $pspec->{code});
            }

            $i++;
        } # for $pspec
    } # for $target
    $handles;
}

1;
# ABSTRACT: Patch package with a set of patches

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Patch - Patch package with a set of patches

=head1 VERSION

This document describes version 0.275 of Module::Patch (from Perl distribution Module-Patch), released on 2019-01-06.

=head1 SYNOPSIS

In this example, we're patching L<HTTP::Tiny> to add automatic retrying.
L<Module::Patch> can be used in two ways: either directly or via creating your
own patch module based on Module::Patch.

=head2 Using Module::Patch directly

 use Module::Patch qw(patch_package);
 use Log::ger;
 my $handle = patch_package('HTTP::Tiny', [
     {
         action      => 'wrap',
         mod_version => qr/^0\.*/,
         sub_name    => 'request',
         code        => sub {
             my $ctx = shift;
             my $orig = $ctx->{orig};

             my ($self, $method, $url) = @_;

             my $retries = 0;
             my $res;
             while (1) {
                 $res = $orig->(@_);
                 return $res if $res->{status} !~ /\A[5]/; # only retry 5xx responses
                 last if $retries >= $config{-retries};
                 $retries++;
                 log_trace "Failed requesting $url ($res->{status} - $res->{reason}), retrying" .
                     ($config{-delay} ? " in $config{-delay} second(s)" : "") .
                     " ($retries of $config{-retries}) ...";
                 sleep $config{-delay};
             }
             $res;
         };
     },
 ]);

 # do stuffs with HTTP::Tiny
 my $res = HTTP::Tiny->new->request(...);
 ...

 # unpatch, restore original subroutines/methods
 undef $handle;

=head2 Creating patch module by subclassing Module::Patch

In your patch module F<lib/HTTP/Tiny/Patch/Retry.pm>:

 package HTTP::Tiny::Patch::Retry;

 use parent qw(Module::Patch);
 use Log::ger;

 our %config;

 sub patch_data {
     return {
         v => 3,
         config => {
             -delay => {
                 summary => 'Number of seconds to wait between retries',
                 schema  => 'nonnegint*',
                 default => 2,
             },
             -retries => {
                 summary => 'Maximum number of retries to perform consecutively on a request (0=disable retry)',
                 schema  => 'nonnegint*',
                 default => 3,
             },
         },
         patches => [
             {
                 action      => 'wrap',
                 mod_version => qr/^0\.*/,
                 sub_name    => 'request',
                 code        => sub {
                     my $ctx = shift;
                     my $orig = $ctx->{orig};

                     my ($self, $method, $url) = @_;

                     my $retries = 0;
                     my $res;
                     while (1) {
                         $res = $orig->(@_);
                         return $res if $res->{status} !~ /\A[5]/; # only retry 5xx responses
                         last if $retries >= $config{-retries};
                         $retries++;
                         log_trace "Failed requesting $url ($res->{status} - $res->{reason}), retrying" .
                             ($config{-delay} ? " in $config{-delay} second(s)" : "") .
                             " ($retries of $config{-retries}) ...";
                         sleep $config{-delay};
                     }
                     $res;
                 };
             },
         ],
     };
 }
 1;

Using your patch module in Perl:

 use HTTP::Tiny::Patch::Retry
     -retries => 4,  # optional, default is 3 as per configuration
     -delay   => 5,  # optional, default is 2 as per configuration
 ;

 # do stuffs with HTTP::Tiny
 my $res = HTTP::Tiny->new->request(...);

 # unpatch, restore original subroutines/methods in target module (HTTP::Tiny)
 HTTP::Tiny::Patch::Retry->unimport;

To patch locally:

 use HTTP::Tiny::Patch::Retry ();

 sub get_data {
     HTTP::Tiny::Patch::Retry->import;
     my $res = HTTP::TIny->new->request(...);
     HTTP::Tiny::Patch::Retry->unimport;
     $res;
 }

Using your patch module on the command-line:

 % perl -MHTTP::Tiny::Patch::Retry -E'my $res = HTTP::Tiny->new->request(...); ...'

=head1 DESCRIPTION

Module::Patch is basically a convenient way to define and bundle a set of
patches. Actual patching is done by L<Monkey::Patch::Action>, which provides
lexically scoped patching.

There are two ways to use this module:

=over 4

=item * subclass it

This is used for convenient bundling of patches. You create a I<patch module> (a
module that monkey-patches other module by adding/replacing/wrapping/deleting
subroutines of target module) by subclassing Module::Patch and providing the
patches specification in patch_data() method.

Patch module should be named I<Some::Module>::Patch::I<YourCategory>.
I<YourCategory> should be a keyword or phrase (verb + obj) that describes what
the patch does. For example, L<HTTP::Daemon::Patch::IPv6>,
L<LWP::UserAgent::Patch::LogResponse>.

Patch module should be use()'d, or require()'d + import()'ed instead of just
require()'d, because the patching is done in import().

=item * require/import it directly

Module::Patch provides B<patch_package> which is the actual routine to do the
patching.

=back

=for Pod::Coverage ^(unimport|patch_data|is_loaded)$

=head1 PATCH DATA SPECIFICATION

Patch data must be stored in C<patch_data()> subroutine. It must be a L<DefHash>
(i.e. a regular Perl hash) with the following known properties:

=over

=item * v => int

Must be 3 (current version).

=item * patches => array

Will be passed to C<patch_package()>.

=item * config => hash

A hash of name and config specifications. Config specification is another
DefHash and can contain the following properties: C<schema> (a L<Sah> schema),
C<default> (default value).

=item * after_read_config => coderef

A hook to run after patch module is imported and configuration has been read.

=item * before_patch => coderef

=item * after_patch => coderef

=item * before_unpatch => coderef

=item * after_unpatch => coderef

=back

=head1 FUNCTIONS

=head2 import

If imported directly, will export @exports as arguments and export requested
symbols.

If imported from subclass, will take %opts as arguments and run patch_package()
on caller package. %opts include:

=over 4

=item * -load_target => BOOL (default 1)

Load target modules. Set to 0 if package is already defined in other files and
cannot be require()-ed.

=item * -warn_target_loaded => BOOL (default 1)

If set to false, do not warn if target modules are loaded before the patch
module. By default, it warns to prevent users making the mistake of importing
subroutines from target modules before they are patched.

=item * -force => BOOL

Will be passed to patch_package's \%opts.

=back

=head2 patch_package

Usage:

 my $handle = patch_package($package, $patches_spec, \%opts);

Patch target package C<$package> with a set of patches.

C<$patches_spec> is an arrayref containing a series of patches specifications.
Each patch specification is a hashref containing these keys: C<action> (string,
required; either 'wrap', 'add', 'replace', 'add_or_replace', 'delete'),
C<mod_version> (string/regex or array of string/regex, can be ':all' to mean all
versions; optional; defaults to ':all'). C<sub_name> (string/regex or array of
string/regex, subroutine(s) to patch, can be ':all' to mean all subroutine,
':public' to mean all public subroutines [those not prefixed by C<_>],
':private' to mean all private), C<code> (coderef, not required if C<action> is
'delete').

Die if there is conflict with other patch modules, for example if target module
has been patched 'delete' and another patch wants to 'wrap' it.

Known options:

=over 4

=item * force => BOOL (default 0)

Force patching even if target module version does not match. The default is to
warn and skip patching.

=back

=head1 FAQ

=head2 Why patch? Why not subclass the target module?

Sometimes the target module is not easily subclassable or at all. But even if
the target module is subclassable, all client code must explicitly use the
subclass. Patching allows us to modify behavior of a target module without
changing any client code that use that module.

=head2 Why create a patch module? Why not submit patches to the module's author?

Not all patches are potentials for inclusion into the upstream (target module).
But even if a patch is, creating and releasing a patch module can get you
something working sooner (while you wait for the original author to respond to
your patch, if ever).

=head2 This module does not work! The target module does not get patched!

It probably does. Some of the common mistakes are:

=over

=item * Not storing the handle

You do this:

 patch_package(...);

instead of this:

 my $handle = patch_package(...);

Since the handle is used to revert the patch, if you do not store C<$handle>,
you are basically patching and immediately reverting the patch.

=item * Importing before patching

If C<Target::Module> exports symbols, and you patch one of the default exports,
the users need to patch before importing. Otherwise he/she will get the
unpatched version. For example, this won't work:

 use Target::Module; # by default export foo
 use Target::Module::Patch::Foo; # patches foo

 foo(); # user gets the unpatched version

While this does:

 use Target::Module::Patch::Foo; # patches foo
 use Target::Module; # by default export foo

 foo(); # user gets the patched version

Since 0.16, Module::Patch already warns this (unless C<-load_target> or
C<-warn_target_loaded> is set to false).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Patch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Patch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Patch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Monkey::Patch::Action>

L<Pod::Weaver::Plugin::ModulePatch>

Some examples of patch modules that use Module::Patch by subclassing it:
L<Net::HTTP::Methods::Patch::LogRequest>,
L<LWP::UserAgent::Patch::HTTPSHardTimeout>, L<HTTP::Tiny::Patch::Cache>,
L<HTTP::Tiny::Patch::Retry>.

Some examples of modules that use Module::Patch directly:
L<Log::ger::For::Class>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
