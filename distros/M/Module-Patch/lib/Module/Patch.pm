package Module::Patch;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.25'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::ger;

use Monkey::Patch::Action qw();
use Package::MoreUtil qw(list_package_contents package_exists);

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

        my $pdata = $self->patch_data or
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

        if (is_loaded($target) && !$loaded_by_us{$target}) {
            if ($load && $warn) {
                warn "$target is loaded before ".__PACKAGE__.", this is not ".
                    "recommended since $target might export subs before ".
                    __PACKAGE__." gets the chance to patch them";
            }
        } else {
            if ($load) {
                eval "package $caller; use $target";
                die if $@;
                $loaded_by_us{$target}++;
            } else {
                die "FATAL: $self: $target is not loaded, please ".
                    "'use $target' before patching";
            }
        }

        # read patch module's configs
        my $pcdata = $pdata->{config} // {};
        my $config = \%{"$self\::config"};
        while (my ($k, $v) = each %$pcdata) {
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

        ${"$self\::handles"} = patch_package(
            $target, $pdata->{patches},
            {force=>$force, patch_module=>ref($self) || $self});

        if ($pdata->{after_patch}) {
            $pdata->{after_patch}->();
        }

    }
}

sub unimport {
    no strict 'refs';

    my $self = shift;

    if ($self eq __PACKAGE__) {
        # we are not subclassed, do nothing
    } else {
        my $pdata = $self->patch_data or
            die "BUG: $self: No patch data supplied";

        if ($pdata->{before_unpatch}) {
            $pdata->{before_unpatch}->();
        }

        my $handles = ${"$self\::handles"};
        #log_trace("Unpatching %s ...", [keys %$handles]);
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
    no strict 'refs';

    my ($package0, $patches_spec, $opts) = @_;
    $opts //= {};

    my $handles = {};
    for my $target (ref($package0) eq 'ARRAY' ? @$package0 : ($package0)) {
        die "FATAL: Target module '$target' not loaded"
            unless package_exists($target);
        my $target_version = ${"$target\::VERSION"};
        my @target_subs;
        my %tp = list_package_contents($target);
        for (keys %tp) {
            if (ref($tp{$_}) eq 'CODE' && !/^\*/) {
                push @target_subs, $_;
            }
        }

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
                    for (@target_subs) {
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

This document describes version 0.25 of Module::Patch (from Perl distribution Module-Patch), released on 2017-07-10.

=head1 SYNOPSIS

To use Module::Patch directly:

 # patching DBI modules so that calls are logged

 use Module::Patch qw(patch_package);
 use Log::ger;
 my $handle = patch_package(['DBI', 'DBI::st', 'DBI::db'], [
     {action=>'wrap', mod_version=>':all', sub_name=>':public', code=>sub {
         my $ctx = shift;

         log_trace("Entering %s(%s) ...", $ctx->{orig_name}, \@_);
         my $res;
         if (wantarray) { $res=[$ctx->{orig}->(@_)] } else { $res=$ctx->{orig}->(@_) }
         log_trace("Returned from %s", $ctx->{orig_name});
         if (wantarray) { return @$res } else { return $res }
     }},
 ]);

 # restore original
 undef $handle;

To create a patch module by subclassing Module::Patch:

 # in your patch module

 package Some::Module::Patch::YourCategory;
 use parent qw(Module::Patch);

 sub patch_data {
     return {
         v => 3,
         patches => [...], # $patches_spec
         config => { # per-patch-module config
             a => {
                 default => 1,
             },
             b => {},
             c => {
                 default => 3,
             },
         },
     };
 }
 1;

 # using your patch module

 use Some::Module::Patch::YourCategory
     -force => 1, # optional, force patch even if target version does not match
     -config => {a=>10, b=>20}, # optional, set config value
 ;

 # accessing per-patch-module config data

 print $Some::Module::Patch::YourCategory::config->{a}; # 10
 print $Some::Module::Patch::YourCategory::config->{c}; # 3, default value

 # unpatch, restore original subroutines
 no Some::Module::Patch::YourCategory;

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

=head2 import()

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

=head2 patch_package($package, $patches_spec, \%opts) => HANDLE

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
L<LWP::UserAgent::Patch::HTTPSHardTimeout>.

Some examples of modules that use Module::Patch directly:
L<Log::Any::For::Class>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
