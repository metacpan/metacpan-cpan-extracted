package Perinci::Exporter;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.084'; # VERSION

# IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
# END IFUNBUILT

# what a generic name, this hash caches the wrapped functions, so that when
# importer asks to import a wrapped function with default wrapping options, we
# don't have to call wrap_sub again. customly wrapped functions are not cached
# though.
my %pkg_cache;

sub import {
    my $package = shift;
    my @caller  = caller(0);
    install_import(@_, into => $caller[0]);
}

sub install_import {
    my %instargs = @_;
    my @caller   = caller($instargs{caller_level} || 0);
    my $into     = $instargs{into} || $caller[0];
    return [400, "Please specify package to install import() to ".
                "(either via 'into' or 'caller_level')"]
        unless $into;
    my $import = sub {
        my $package = shift;

        my @caller = caller(0);
        do_export(
            {
                source           => $into,
                target           => $caller[0],
                default_exports  => $instargs{default_exports},
                extra_exports    => $instargs{extra_exports},
                default_wrap     => defined($instargs{default_wrap})     ? $instargs{default_wrap} : 0,
                default_on_clash => defined($instargs{default_on_clash}) ? $instargs{default_on_clash} : 'force',
            },
            @_,
        );
    };

    no strict 'refs';
    *{"$into\::import"} = $import;
}

sub do_export {
    my $expopts;
    if ($_[0] && ref($_[0]) eq 'HASH') {
        $expopts = shift;
    } else {
        die "First argument to do_export() must be export options";
    }
    my $source = $expopts->{source};
    my $target = $expopts->{target};


    # collect what symbols are available for exporting, along with their tags,
    # etc.

    no strict 'refs';

    my %exports;
    my $metas = \%{"$source\::SPEC"};
    $metas ||= {};
    for my $k (keys %$metas) {
        # for now we limit ourselves to subs
        next unless $k =~ /\A\w+\z/;
        my @tags = @{ $metas->{$k}{tags} || [] };
        next if grep {$_ eq 'export:never'} @tags;
        $exports{$k} = {
            tags => \@tags,
        };
    }

    for my $k (@{$expopts->{default_exports} || []},
               @{"$source\::EXPORT"}) {
        if ($exports{$k}) {
            push @{$exports{$k}{tags}}, 'export:default';
        } else {
            $exports{$k} = {
                tags => [qw/export:default/],
            };
        }
    }

    for my $k (@{$expopts->{extra_exports} || []},
               @{"$source\::EXPORT_OK"}) {
        if ($exports{$k}) {
        } else {
            $exports{$k} = {
                tags => [],
            };
        }
    }

    for my $k (keys %exports) {
        push @{$exports{$k}{tags}}, 'all';
    }

    # parse import() arguments

    my %impopts; #
    my @imps; # requested symbols or tags to export, each element is:
    while (1) {
        last unless @_;
        my $i = shift;
        if ($i =~ s!^-!!) {
            die "Import option -$i requires argument" unless @_;
            $impopts{$i} = shift;
            next;
        } else {
            my $el = {};
            if (@_ && ref($_[0]) eq 'HASH') {
                my $io = shift;
                $el->{$_} = $io->{$_} for keys %$io;
            };
            $el->{sym} = $i;
            push @imps, $el;
        }
    }

    if (!@imps) {
        push @imps, {sym=>':default'};
    }

    # find out existing symbols on the target package, so we can die on clash,
    # if that behavior's what the importer wants

    my %existing = _list_package_contents($target);

    # recap information
    my $recap = {wrapped=>[]};

    # import!

    $pkg_cache{$source} ||= {};

    for my $imp (@imps) {
        my @ssyms; # symbols from source package
        if ($imp->{sym} =~ s!^:!!) {
            @ssyms = grep { grep {
                "export:$imp->{sym}" eq $_ || $imp->{sym} eq $_
            } @{ $exports{$_}{tags} } }
                keys %exports;
        } else {
            @ssyms = ($imp->{sym});
        }

        for my $ssym (sort @ssyms) {

            if (!$exports{$ssym}) {
                die "$ssym is not exported by $source";
            }

            # export to what target symbol?
            my $tsym;
            if ($imp->{as}) {
                $tsym = $imp->{as};
            } else {
                $tsym = $ssym;
                if (my $prefix = defined($imp->{prefix}) ? $imp->{prefix} : $impopts{prefix}) {
                    $tsym = "$prefix$tsym";
                }
                if (my $suffix = defined($imp->{suffix}) ? $imp->{suffix} : $impopts{suffix}) {
                    $tsym = "$tsym$suffix";
                }
            }

            # clash?
            if ($existing{$tsym}) {
                if ((defined($impopts{on_clash}) ? $impopts{on_clash} : $expopts->{default_on_clash})
                        eq 'bail') {
                    die "Refusing to export ".
                        ($tsym eq $ssym ? $ssym : "$ssym (as $tsym)").
                            " to an existing symbol in package $target";
                }
            }

            my $wrap;
          SET_WRAP_OPTS: {
                my $default_wrap = ref $expopts->{default_wrap} eq 'HASH' ?
                    {%{ $expopts->{default_wrap} }} : $expopts->{default_wrap};
                my $default_wrap_opts = $default_wrap;
                $default_wrap_opts = {} if ref $default_wrap_opts ne 'HASH';
                $default_wrap = {} if $default_wrap && ref $default_wrap ne 'HASH';

                $wrap = ref $imp->{wrap} eq 'HASH' ?
                    {%{ $imp->{wrap} }} : $imp->{wrap};
                $wrap = {} if $wrap && ref $wrap ne 'HASH';
                if (defined $imp->{convert}) {
                    die "Error when exporting $ssym: 'convert' option needs wrap=1 but wrap is disabled"
                        if defined $wrap && !$wrap;
                    $wrap = $default_wrap_opts unless ref $wrap eq 'HASH';

                    $wrap->{convert} = $imp->{convert};
                }
                for (qw/args_as result_naked curry timeout/) {
                    if (defined $imp->{$_}) {
                        die "Error when exporting $ssym: '$_' option needs wrap=1 but wrap is disabled"
                            if defined $wrap && !$wrap;
                        $wrap = $default_wrap_opts unless ref $wrap eq 'HASH';

                        $wrap->{convert} ||= {};
                        $wrap->{convert}{$_} = $imp->{$_};
                    }
                }

                $wrap = $default_wrap unless defined $wrap;
                #use DD; dd {ssym=>$ssym, wrap=>$wrap};
            } # SET_WRAP_OPTS

            my $sub = \&{"$source\::$ssym"};
          DO_WRAP: {
                last unless $wrap;

                my $cache;
                if (keys(%$wrap) == 0) {
                    # using default wrap options, we store the cached version of
                    # these
                    $cache = $pkg_cache{$source}{$ssym}{sub};
                }
                if ($cache) {
                    $sub = $cache;
                    push @{ $recap->{wrapped} }, $ssym;
                } else {
                    $sub = \&{"$source\::$ssym"};
                    my $meta = $metas->{$ssym};
                    if (!$meta) {
                        #warn "Exporting $ssym to $target\::$tsym unwrapped ".
                        #    "because $ssym does not have metadata";
                    } else {
                        require Perinci::Sub::Wrapper;
                        my $res = Perinci::Sub::Wrapper::wrap_sub(
                            %$wrap,
                            sub_name => "$source\::$ssym",
                            meta     => $meta,
                        );
                        die "Can't wrap $ssym for $target: ".
                            "$res->[0] - $res->[1]" unless $res->[0] == 200;
                        $sub = $res->[2]{sub};
                        $pkg_cache{$source}{$ssym}{sub} = $sub
                            if keys(%$wrap) == 0;
                        push @{ $recap->{wrapped} }, $ssym;
                    }
                }
            } # DO_WRAP

            # finally, do the actual exporting!
            #say "Exporting $ssym -> $target\::$tsym"; #DEBUG#
            *{"$target\::$tsym"} = $sub;

            $existing{$tsym}++;

        } # for @ssyms

    } # for @imps

    $recap;
}

# borrowed from Package::MoreUtil. this is actually not a proper implementation,
# but since we want to avoid extra footprint by loading Package::Stash, we'll
# get by for now.
sub _list_package_contents {
    my $pkg = shift;

    return () unless !length($pkg) || _package_exists($pkg);
    my $symtbl = \%{$pkg . "::"};

    my %res;
    while (my ($k, $v) = each %$symtbl) {
        next if $k =~ /::$/; # subpackage
        my $n;
        if ("$v" !~ /^\*/) {
            # constant
            $res{$k} = $v;
            next;
        }
        if (defined *$v{CODE}) {
            $res{$k} = *$v{CODE}; # subroutine
            $n++;
        }
        if (defined *$v{HASH}) {
            $res{"\%$k"} = \%{*$v}; # hash
            $n++;
        }
        if (defined *$v{ARRAY}) {
            $res{"\@$k"} = \@{*$v}; # array
            $n++;
        }
        if (defined(*$v{SCALAR}) # XXX always defined?
                && defined(${*$v})) { # currently we filter undef values
            $res{"\$$k"} = \${*$v}; # scalar
            $n++;
        }

        if (!$n) {
            $res{"\*$k"} = $v; # glob
        }
    }

    %res;
}

# also borrowed from Package::MoreUtil
sub _package_exists {
    my $pkg = shift;

    # opt
    #return unless $pkg =~ /\A\w+(::\w+)*\z/;

    if ($pkg =~ s!::(\w+)\z!!) {
        return !!${$pkg . "::"}{$1 . "::"};
    } else {
        return !!$::{$pkg . "::"};
    }
}

1;
# ABSTRACT: An exporter that groks Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Exporter - An exporter that groks Rinci metadata

=head1 VERSION

This document describes version 0.084 of Perinci::Exporter (from Perl distribution Perinci-Exporter), released on 2019-09-11.

=head1 SYNOPSIS

Exporting:

 package YourModule;

 # most of the time, you only need to do this
 use Perinci::Exporter;

 our %SPEC;

 # f1 will not be exported by default, but user can import them explicitly using
 # 'use YourModule qw(f1)'
 $SPEC{f1} = { v=>1.1 };
 sub f1 { ... }

 # f2 will be exported by default because it has the export:default tag
 $SPEC{f2} = {
     v=>1.1,
     args=>{a1=>{schema=>"float*",req=>1, pos=>0}, a2=>{schema=>'float*', req=>1, pos=>1}},
     tags=>[qw/a export:default/],
 };
 sub f2 {
     my %args = @_;
 }

 # f3 will never be exported, and user cannot import them via 'use YourModule
 # qw(f3)' nor via 'use YourModule qw(:a)'
 $SPEC{f3} = { v=>1.1, tags=>[qw/a export:never/] };
 sub f3 { ... }

 1;

Importing:

 # does not import anything
 use YourModule ();

 # imports all functions tagged with 'export:default' (f2)
 use YourModule;

 # explicitly import functions by name (f1, f2)
 use YourModule qw(f1 f2);

 # explicitly import functions by tag (f2)
 use YourModule qw(:a);

 # add per-import options: rename/add prefix/add suffix. both statements below
 # will cause f2 to be exported as foo_f2_bar. while f1 is simply exported as
 # f1.
 use YourModule f2   => { as => 'foo_f2_bar' }, f1 => {};
 use YourModule ':a' => { prefix => 'foo_', suffix => '_bar' }, f1=>{};

 # per-import option: timeout to limit execution of each invocation to 3
 # seconds. requires Perinci::Sub::Wrapper and Perinci::Sub::Property::timeout.
 use YourModule f2 => { timeout=>3 };

 # per-import option: change calling convention from named argument to
 # positional. requires wrapping (Perinci::Sub::Wrapper).
 use YourModule f2 => { args_as=>'array' };
 # now instead of calling f2 with f2(a1=>3, a2=>4), you do f2(3, 4)

 # per-import option: retry on failure. requires wrapping
 # (Perinci::Sub::Wrapper) and Perinci::Sub::Property::retry. See
 # Perinci::Sub::Property::retry for more details.
 use YourModule f2 => { retry=>3 };

 # XXX other per-import options

 # import option: set prefix/suffix for all imports. the statement below will
 # import foo_f1_bar and foo_f2_bar.
 use YourModule 'f1', 'f2', -prefix=>'foo', -suffix=>'bar';

 # import option: define behavior when an import clashes with existing symbol.
 # the default is 'force' which, like Exporter, will force importing anyway
 # without warning, overriding existing symbol. another option is to 'bail'
 # (die).
 use YourModule 'f1', 'f2', -on_clash=>'die';

=head1 DESCRIPTION

Perinci::Exporter is an exporter which can utilize information from L<Rinci>
metadata. If your package has Rinci metadata, consider using this exporter for
convenience and flexibility.

Features of this module:

=over 4

=item * List exportable routines from Rinci metadata

All functions which have metadata are assumed to be exportable, so you do not
have to list them again via C<@EXPORT> or C<@EXPORT_OK>.

=item * Read tags from Rinci metadata

The exporter can read tags from your function metadata. You do not have to
define export tags again.

=item * Export to different name

See the 'as', 'prefix', 'suffix' import options of the install_import()
function.

=item * Export wrapped function

This allows importer to get additional/modified behavior. See
L<Perinci::Sub::Wrapper> for more about wrapping.

=item * Export differently wrapped function to different importers

See some examples in L</"FAQ">.

=item * Warn/bail on clash with existing function

For testing or safety precaution.

=item * Read @EXPORT and @EXPORT_OK

Perinci::Exporter reads these two package variables, so it is quite compatible
with L<Exporter> and L<Exporter::Lite>. In fact, it is basically the same as
Exporter::Lite if you do not have any metadata for your functions.

=back

=head1 EXPORTING

Most of the time, to set up exporter, you only need to just use() it in your
module:

 package YourModule;
 use Perinci::Exporter;

Perinci::Exporter will install an import() routine for your package. If you need
to pass some exporting options:

 use Perinci::Exporter default_exports=>[qw/foo bar/], ...;

See install_import() for more details.

=head1 IMPORTING

B<Default exports>. Your module users can import functions in a variety of ways.
The simplest form is:

 use YourModule;

which by default will export all functions marked with C<export:default> tags.
For example:

 package YourModule;
 use Perinci::Exporter;
 our %SPEC;
 $SPEC{f1} = { v=>1.1, tags=>[qw/export:default a/] };
 sub   f1    { ... }
 $SPEC{f2} = { v=>1.1, tags=>[qw/export:default a b/] };
 sub   f2    { ... }
 $SPEC{f3} = { v=>1.1, tags=>[qw/b c/] };
 sub   f3    { ... }
 $SPEC{f4} = { v=>1.1, tags=>[qw/a b c export:never/] };
 sub   f4    { ... }
 1;

YourModule will by default export C<f1> and C<f2>. If there are no functions
tagged with C<export:default>, there will be no default exports. You can also
supply the list of default functions via the C<default_exports> argument:

 use Perinci::Exporter default_exports => [qw/f1 f2/];

or via the C<@EXPORT> package variable, like in Exporter.

B<Importing individual functions>. Your module users can import individual
functions:

 use YourModule qw(f1 f2);

Each function can have import options, specified in a hashref:

 use YourModule f1 => {wrap=>0}, f2=>{as=>'bar', args_as=>'array'};
 # imports f1, bar

B<Importing groups of functions by tags>. Your module users can import groups of
individual functions using tags. Tags are collected from function metadata, and
written with a C<:> prefix to differentiate them from function names. Each tag
can also have import options:

 use YourModule 'f3', ':a' => {prefix => 'a_'}; # imports f3, a_f1, a_f2

Some tags are defined automatically: C<:default> (all functions that have the
C<export:default> tag), C<:all> (all functions).

B<Importing to a different name>. As can be seen from previous examples, the
'as' and 'prefix' (and also 'suffix') import options can be used to import
subroutines using into a different name.

B<Bailing on name clashes>. By default, importing will override existing names
in the target package. To warn about this, users can set '-on_clash' to 'bail':

 use YourModule 'f1', f2=>{as=>'f1'}, -on_clash=>'bail'; # dies, imports clash

 use YourModule 'f1', -on_clash=>'bail'; # dies, f1 already exists
 sub f1 { ... }

B<Customizing wrapping options>. Users can specify custom wrapping options when
importing functions. The wrapping will then be done just for them (as opposed to
wrapped functions which are wrapped using default options, which will be shared
among all importers not requesting custom wrapping). See some examples in
L</"FAQ">.

See do_export() for more details.

=head1 FUNCTIONS

=head2 install_import(%args)

The routine which installs the import() routine to caller package.

Arguments:

=over 4

=item * into => STR (default: caller package)

Explicitly set target package to install the import() routine to.

=item * caller_level => INT (default: 0)

If C<into> is not set, caller package will be used. The default is to use
caller(0), but the caller level can be set using this argument.

=item * default_exports => ARRAY

Default symbols to export.

You can also set default exports by setting C<@EXPORT>.

=item * extra_exports => ARRAY

Other symbols to export (other than the ones having metadata and those specified
with C<default_exports> and C<@EXPORT>).

You can also set default exports by setting C<@EXPORT_OK>.

=item * default_wrap => BOOL (default: 1)

Whether wrap subroutines by default.

=item * default_on_clash => STR (default: 'force')

What to do when clash of symbols happen.

=back

=head2 do_export($expopts, @args)

The routine which implements the exporting. Will be called from the import()
routine. $expopts is a hashref containing exporter options, constructed by
install_import(). C<@args> is the same as arguments passed during import: a
sequence of function name or tag name (prefixed with C<:>), function/tag name
and export option (hashref), or option (prefixed with C<->).

Example:

 do_export('f1', ':tag1', f2 => {import option...}, -option => ...);

Import options:

=over 4

=item * as => STR

Export a function to a new name. Will die if new name is invalid. Inapplicable
for tags.

Example:

 use YourModule func => {as => 'f'};

=item * prefix => STR

Export function/tag with a prefix. Will die on invalid prefix.

Example:

 use YourModule ':default' => {prefix => 'your_'};

This means, C<foo>, C<bar>, etc. will be exported as C<your_foo>, C<your_bar>,
etc.

=item * suffix => STR

Export function/tag with a prefix. Will die on invalid suffix.

Example:

 use YourModule ':default' => {suffix => '_s'};

This means, C<foo>, C<bar>, etc. will be exported as C<foo_s>, C<bar_s>, etc.

=item * wrap => 0 | 1 | HASH

The default (when value of this option is unset>) is to export the
original/unwrapped functions, unless wrapping is necessary. Other options like
C<timeout>, C<retry>, C<convert>, C<args_as> require wrapping so they
automatically turn on wrapping.

You can explicitly turn wrapping on unconditionally by setting the value of this
option to 1 (enable wrapping with default wrapping options) or a hashref that
will be passed to L<Perinci::Sub::Wrapper>'s C<wrap_sub()> to customize
wrapping.

You can also explicitly disable wrapping by setting the value of this option to
0. If you also specify other options that require wrapping (for example,
C<retry>) an exception will be raised.

Examples:

 use YourModule foo => {};                     # export unwrapped, original function
 use YourModule foo => {timeout=>30};          # export wrapped functions
 use YourModule foo => {wrap=>1};              # export wrapped functions
 use YourModule foo => {wrap=>0, timeout=>30}; # dies! 'timeout' option requires wrapping

Note that when set to 0, the exported function might already be wrapped anyway,
e.g. when your module uses embedded wrapping (see
L<Dist::Zilla::Plugin::Rinci::Wrap>) or wrap its subroutines manually.

Also note that wrapping will not be done if subroutine does not have metadata.

=item * convert => HASH

This is a shortcut for specifying:

 wrap => { convert => HASH }

=item * args_as => STR

This is a shortcut for specifying:

 wrap => { convert => { args_as => STR } }

=item * result_naked => BOOL

This is a shortcut for specifying:

 wrap => { convert => { result_naked => BOOL } }

=item * curry => STR

This is a shortcut for specifying:

 wrap => { convert => { curry => STR } }

=back

Options:

=over 4

=item * -on_clash => 'force' | 'bail' (default: from install_import()'s default_on_clash)

If importer tries to import 'foo' when it already exists, the default is to
force importing, without any warnings, like Exporter. Alternatively, you can
also bail (dies), which can be more reliable/safe.

=item * -prefix => STR

Like C<prefix> import option, but to apply to all exports.

=item * -suffix => STR

Like C<suffix> import option, but to apply to all exports.

=back

=head1 FAQ

=head2 Why use this module as my exporter?

If you are fine with Exporter, Exporter::Lite, or L<Sub::Exporter>, then you
probably won't need this module.

This module is particularly useful if you use Rinci metadata, in which case
you'll get some nice features. Some examples of the things you can do with this
exporter:

=over 4

=item * Change calling style from argument to positional

 use YourModule func => {args_as=>'array'};

Then instead of:

 func(a => 1, b => 2);

your function is called with positional arguments:

 func(1, 2);

Note: this requires that the function's argument spec puts the C<pos>
information. For example:

 $SPEC{func} = {
     v => 1.1,
     args => {
         a => { pos=>0 },
         b => { pos=>1 },
     }
 };

=item * Set timeout

 use YourModule ':all' => {wrap=>{convert=>{timeout=>10}}};

This means all exported functions will be limited to 10s of execution time.

Note: L<Perinci::Sub::property::timeout> (an optional dependency) is needed for
this.

=item * Set retry

 use YourModule ':default' => {wrap=>{convert=>{retry=>3}}};

This means all exported functions can autoretry up to 3 times.

Note: L<Perinci::Sub::property::retry> (an optional dependency) is needed for
this.

=item * Currying

Sub::Exporter supports this. Perinci::Exporter does too:

 use YourModule f => {as=>'f_a10', wrap=>{convert=>{curry=>{a=>10}}}};

This means:

 f_a10();             # equivalent to f(a=>10)
 f_a10(b=>20, c=>30); # equivalent to f(a=>10, b=>20, c=>30)
 f_a10(a=>5);         # error, a is already set

Note: L<Perinci::Sub::property::curry> (an optional dependency) is needed for
this.

=back

=head2 What happens to functions that do not have metadata?

They can still be exported if you list them in C<@EXPORT> or C<@EXPORT_OK>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Exporter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Exporter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Exporter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

L<Perinci::Sub::Wrapper>

If you want something simpler but also groks Rinci metadata, there's
L<Exporter::Rinci>. It's just like good old Exporter.pm, but wraps it so
C<@EXPORT>, C<@EXPORT_OK>, C<%EXPORT_TAGS> are filled from information from
Rinci metadata, if they are empty. You don't get wrapping, renaming, etc. If
Perinci::Exporter is like Sub::Exporter + Rinci, then Exporter::Rinci is like
Exporter.pm + Rinci.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
