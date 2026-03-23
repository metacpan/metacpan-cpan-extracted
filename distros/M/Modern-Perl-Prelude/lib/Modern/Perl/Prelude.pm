package Modern::Perl::Prelude;

use v5.30;
use strict;
use warnings;

# ABSTRACT: Project prelude for modern Perl style on Perl 5.30+
our $VERSION = '0.008';

use Import::Into ();
use strict   ();
use warnings ();
use feature  ();
use utf8     ();
use true     ();

use Feature::Compat::Try ();
use builtin::compat      ();

my @FEATURES = qw(
    say
    state
    fc
);

my @BUILTINS = qw(
    blessed
    refaddr
    reftype
    trim
    ceil
    floor
    true
    false
    weaken
    unweaken
    is_weak
);

my %KNOWN_FLAG = map { $_ => 1 } qw(
    -utf8
    -class
    -defer
    -corinna
    -always_true
);

my %KNOWN_HASH_KEY = map { $_ => 1 } qw(
    utf8
    class
    defer
    corinna
    always_true
);

sub import {
    my ($class, @args) = @_;
    my $target = caller;
    my $config = _parse_args(@args);

    _validate_config($config);

    strict->import::into($target);
    warnings->import::into($target);

    feature->import::into($target, @FEATURES);

    Feature::Compat::Try->import::into($target);

    builtin::compat->import::into($target, @BUILTINS);

    utf8->import::into($target) if $config->{utf8};

    _set_always_true(1) if $config->{always_true};

    _import_optional_module($target, 'Feature::Compat::Class', $config->{class})
        if $config->{class};

    _import_optional_module($target, 'Feature::Compat::Defer', $config->{defer})
        if $config->{defer};

    _import_optional_module($target, 'Object::Pad', $config->{corinna})
        if $config->{corinna};

    return;
}

sub unimport {
    my ($class, @args) = @_;
    my $target = caller;
    my $config = _parse_args(@args);

    _validate_config($config);

    strict->unimport::out_of($target);
    warnings->unimport::out_of($target);

    feature->unimport::out_of($target, @FEATURES);
    utf8->unimport::out_of($target);

    _set_always_true(0) if $config->{always_true};

    return;
}

sub _parse_args {
    my (@args) = @_;

    return {} unless @args;

    if (@args == 1 && ref($args[0]) eq 'HASH') {
        return _parse_hash_args($args[0]);
    }

    return _parse_flag_args(@args);
}

sub _parse_flag_args {
    my (@args) = @_;
    my %config;

    for my $arg (@args) {
        die __PACKAGE__ . qq{: hash-style arguments must be passed as a single hash reference\n}
            if ref $arg;

        die __PACKAGE__ . qq{: unknown import option "$arg"\n}
            unless $KNOWN_FLAG{$arg};

        (my $key = $arg) =~ s/^-//;
        $config{$key} = 1;
    }

    return \%config;
}

sub _parse_hash_args {
    my ($raw) = @_;
    my %config = %{$raw};

    for my $key (keys %config) {
        die __PACKAGE__ . qq{: unknown import key "$key"\n}
            unless $KNOWN_HASH_KEY{$key};
    }

    return \%config;
}

sub _validate_config {
    my ($config) = @_;

    die __PACKAGE__ . qq{: options "-class" and "-corinna" are mutually exclusive\n}
        if $config->{class} && $config->{corinna};

    return;
}

sub _set_always_true {
    my ($enabled) = @_;

    if ($enabled) {
        true->import();
    }
    else {
        true->unimport();
    }

    return;
}

sub _import_optional_module {
    my ($target, $module, $opts) = @_;

    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;

    if (ref($opts) eq 'HASH') {
        $module->import::into($target, %{$opts});
    }
    else {
        $module->import::into($target);
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Modern::Perl::Prelude - Project prelude for modern Perl style on Perl 5.30+

=head1 SYNOPSIS

    use Modern::Perl::Prelude;

    state $counter = 0;
    my $s = trim("  hello  ");

    try {
        die "boom\n";
    }
    catch ($e) {
        warn $e;
    }

Flag-style optional imports:

    use Modern::Perl::Prelude '-utf8';
    use Modern::Perl::Prelude qw/-class -defer/;
    use Modern::Perl::Prelude qw(-corinna -always_true);

Hash-style optional imports:

    use Modern::Perl::Prelude {
        utf8        => 1,
        defer       => 1,
        always_true => 1,
    };

Disable native pragmata/features lexically again:

    no Modern::Perl::Prelude;
    no Modern::Perl::Prelude '-utf8';
    no Modern::Perl::Prelude { utf8 => 1 };
    no Modern::Perl::Prelude '-always_true';

=head1 DESCRIPTION

This module bundles a small, opinionated set of pragmata, features, and
compatibility layers for writing Perl in a Perl 5.40+-style while staying
runnable on Perl 5.30+.

It enables:

=over 4

=item * strict

=item * warnings

=item * feature C<say>, C<state>, C<fc>

=item * C<Feature::Compat::Try>

=item * selected functions from C<builtin::compat>

=back

Additional compatibility layers may be requested explicitly via import
options.

=head1 DEFAULT IMPORTS

This module always makes the following available in the caller's lexical
scope:

    say
    state
    fc
    try / catch
    blessed
    refaddr
    reftype
    trim
    ceil
    floor
    true
    false
    weaken
    unweaken
    is_weak

=head1 IMPORT OPTIONS

=head2 Flag-style

Supported flags:

    -utf8
    -class
    -defer
    -corinna
    -always_true

Examples:

    use Modern::Perl::Prelude '-utf8';

    use Modern::Perl::Prelude qw(
        -class
        -defer
    );

    use Modern::Perl::Prelude qw(
        -class
        -utf8
        -always_true
    );

=head2 Hash-style

Hash-style arguments must be passed as a single hash reference:

    use Modern::Perl::Prelude {
        utf8        => 1,
        defer       => 1,
        always_true => 1,
    };

Supported hash keys:

=over 4

=item * C<utf8>

=item * C<class>

=item * C<defer>

=item * C<corinna>

=item * C<always_true>

=back

For compatibility-layer options (C<class>, C<defer>, C<corinna>), a true
scalar enables the feature. A hash reference also enables it and is passed
through to the underlying module's C<import>.

For C<always_true>, use a boolean value.

=head2 -utf8 / utf8

Also enables source-level UTF-8, like:

    use utf8;

=head2 -class / class

Loads and imports C<Feature::Compat::Class> into the caller scope.

This is the forward-compatible class syntax option.

=head2 -defer / defer

Loads and imports C<Feature::Compat::Defer> into the caller scope.

=head2 -corinna / corinna

Loads and imports C<Object::Pad> into the caller scope.

This is intended for projects that explicitly want Object::Pad / Corinna-like
class syntax.

C<-class> and C<-corinna> are mutually exclusive.

=head2 -always_true / always_true

Enables automatic true return for the currently-compiling file via C<true>,
so modules can omit a trailing:

    1;

This behavior is file-scoped rather than lexically-scoped.

=head1 OPTIONAL IMPORTS

When requested explicitly, this module can also make the following available:

=over 4

=item * C<-class> / C<class> enables C<class>, C<method>, C<field>, C<ADJUST> via C<Feature::Compat::Class>

=item * C<-defer> / C<defer> enables C<defer>

=item * C<-corinna> / C<corinna> enables class syntax via C<Object::Pad>

=item * C<-always_true> / C<always_true> enables automatic true return for the current file

=back

=head1 UNIMPORT

C<no Modern::Perl::Prelude> reliably disables native pragmata/features
managed by this module:

    strict
    warnings
    say
    state
    fc
    utf8

Compatibility layers such as C<Feature::Compat::Try>,
C<Feature::Compat::Class>, C<Feature::Compat::Defer>, C<Object::Pad>, and
C<builtin::compat> are treated as import-only for cross-version use on
Perl 5.30+ and are not guaranteed to be symmetrically undone by
C<no Modern::Perl::Prelude>.

C<always_true> is an exception: C<no Modern::Perl::Prelude '-always_true'> or

    no Modern::Perl::Prelude { always_true => 1 };

disables the automatic true-return behavior for the current file.

=head1 DESIGN NOTES

This is a lexical prelude module. It is implemented via C<Import::Into> so
that pragmata and lexical functions affect the caller's scope, not the scope
of this wrapper module itself.

Optional compatibility layers are loaded lazily, only when explicitly
requested.

The C<always_true> option is implemented via C<true> and is file-scoped.

=head1 AUTHOR

Sergey Kovalev E<lt>skov@cpan.orgE<gt>,

=head1 CO-AUTHOR

Kirill Dmitriev E<lt>zaika.k1007@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
