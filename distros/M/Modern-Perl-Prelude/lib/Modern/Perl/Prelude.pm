package Modern::Perl::Prelude;

use v5.30;
use strict;
use warnings;

# ABSTRACT: Project prelude for modern Perl style on Perl 5.30+
our $VERSION = '0.005';

use Import::Into ();
use strict   ();
use warnings ();
use feature  ();
use utf8     ();

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

my %KNOWN_ARG = map { $_ => 1 } qw(
    -utf8
    -class
    -defer
);

sub import {
    my ($class, @args) = @_;
    my %arg    = _parse_args(@args);
    my $target = caller;

    strict->import::into($target);
    warnings->import::into($target);

    feature->import::into($target, @FEATURES);
    Feature::Compat::Try->import::into($target);
    builtin::compat->import::into($target, @BUILTINS);

    utf8->import::into($target) if $arg{'-utf8'};

    _import_optional_compat($target, 'Feature::Compat::Class')
        if $arg{'-class'};

    _import_optional_compat($target, 'Feature::Compat::Defer')
        if $arg{'-defer'};

    return;
}

sub unimport {
    my ($class, @args) = @_;
    _parse_args(@args);

    my $target = caller;

    strict->unimport::out_of($target);
    warnings->unimport::out_of($target);

    feature->unimport::out_of($target, @FEATURES);
    utf8->unimport::out_of($target);

    return;
}

sub _parse_args {
    my @args = @_;
    my %arg;

    for my $arg (@args) {
        die __PACKAGE__ . qq{: unknown import option "$arg"\n}
            unless $KNOWN_ARG{$arg};

        $arg{$arg} = 1;
    }

    return %arg;
}

sub _import_optional_compat {
    my ($target, $module) = @_;

    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;

    $module->import::into($target);

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

Optional UTF-8 source mode:

    use Modern::Perl::Prelude '-utf8';

Optional class syntax:

    use Modern::Perl::Prelude '-class';

Optional defer syntax:

    use Modern::Perl::Prelude '-defer';

Any combination is allowed:

    use Modern::Perl::Prelude qw(
        -utf8
        -class
        -defer
    );

Disable native pragmata/features lexically again:

    no Modern::Perl::Prelude;

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

=head1 IMPORT OPTIONS

=head2 -utf8

Also enables source-level UTF-8, like:

    use utf8;

=head2 -class

Loads and imports C<Feature::Compat::Class> into the caller scope.

=head2 -defer

Loads and imports C<Feature::Compat::Defer> into the caller scope.

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

=head1 OPTIONAL IMPORTS

When requested explicitly, this module can also make the following available:

=over 4

=item * C<-class> enables C<class>, C<method>, C<field>, C<ADJUST>

=item * C<-defer> enables C<defer>

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
C<Feature::Compat::Class>, C<Feature::Compat::Defer>, and
C<builtin::compat> are treated as import-only for cross-version use on
Perl 5.30+ and are not guaranteed to be symmetrically undone by
C<no Modern::Perl::Prelude>.

=head1 DESIGN NOTES

This is a lexical prelude module. It is implemented via C<Import::Into> so
that pragmata and lexical functions affect the caller's scope, not the scope
of this wrapper module itself.

Optional compatibility layers are loaded lazily, only when explicitly
requested by import options.

=head1 AUTHOR

Sergey Kovalev E<lt>skov@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
