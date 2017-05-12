use strictures 2;

package Moove;

# ABSTRACT: functions and methods with parameter lists and type constraints

use Type::Tiny 1.000006 ();
use Type::Registry ();
use Type::Utils qw(class_type);

use Function::Parameters 1.0703 qw(:lax);
use Import::Into 1.002004 ();
use Syntax::Feature::Try 1.003 ();
use Data::OptList 0.109 ();

use Carp qw(croak confess);

our @EXPORT;

our $VERSION = '0.006'; # VERSION

my %OPTIONS;

use constant PKGRE => qr{^\w+(::\w+)+$};

sub import {
    my $caller = scalar caller;
    my $class = shift;
    my $opts = Data::OptList::mkopt_hash(\@_);

    my $registry = Type::Registry->for_class($caller);

    my $options = $OPTIONS{$caller} ||= {};

    if (my $types = delete $opts->{types}) {
        if (ref $types eq 'ARRAY') {
            $registry->add_types(@$types);
        } elsif (ref $types eq 'SCALAR') {
            $registry->add_types($$types);
        } else {
            croak "unknown value for argument 'types': $types";
        }
    }
    if (my $classes = delete $opts->{classes}) {
        foreach my $class (@$classes) {
            my $type = class_type($class);
            $registry->add_type($type);
        }
    }
    if (my $types = delete $opts->{type}) {
        foreach my $type (@$types) {
            $registry->add_type($type);
        }
    }

    unless (exists $opts->{-nostdtypes}) {
        $registry->add_types(-Standard);
    }

    if (exists $opts->{-autoclass}) {
        $options->{autoclass} = 1;
    }

    Function::Parameters->import::into($caller, {
        method => {
            defaults => 'method',
            runtime => 0,
            strict => 1,
            reify_type => \&_reify_type,
        },
        func => {
            defaults => 'function',
            runtime => 0,
            strict => 1,
            reify_type => \&_reify_type,
        }
    });

    if (exists $opts->{-trycatch}) {
        Syntax::Feature::Try::register_exception_matcher(sub {
            my ($exception, $typedef) = @_;
            if ($options->{autoclass} and $typedef =~ PKGRE) {
                if ($typedef->can('caught')) {
                    return $typedef->caught($exception) || undef;
                } else {
                    return class_type($typedef)->check($exception) || undef;
                }
            } else {
                return $registry->lookup($typedef)->check($exception) || undef;
            }
        });

        require syntax;
        syntax->import_into($caller, 'try');
    }
}

sub _reify_type {
    my ($typedef, $package) = @_;
    my ($caller, $file, $line) = caller;
    $package //= $caller;
    my $options = $OPTIONS{$package} || {};
    my $type;
    eval {
        if ($options->{autoclass} and $typedef =~ PKGRE) {
            $type = class_type($typedef);
        } else {
            my $registry = Type::Registry->for_class($package);
            $type = $registry->lookup($typedef);
        }
    };
    if (my $e = $@) {
        $e =~ s{\s+ at \s+ \S+ \s+ line \s+ \S+ \s*$}{}xs;
        warn "$e at $file line $line\n";
        exit 255;
    } else {
        return $type;
    }
}

1;

__END__

=pod

=head1 NAME

Moove - functions and methods with parameter lists and type constraints

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Moove;

    func foo (Int $number, Str $text)
    {
        ...
    }


    use Moove classes => [qw[ Some::Class ]];

    method bar (Some::Class $obj)
    {
        ...
    }


    use Moove -trycatch;

    func foobar () {
        try {
            die "meh";
        } catch {
            return "caught meh.";
        }
    }


    use Moove -autoclass;

    method bar (Some::Class $obj)
    {
        ...
    }

=head1 DESCRIPTION

This module inherits L<Function::Parameters> with some defaults and type constraints with L<Type::Tiny>.

Some reasons to use Moove:

=over 4

=item * No L<Moose> dependency

=item * No L<Devel::Declare> dependency

=item * A nearly replacement for L<Method::Signatures>

But with some differences...

=back

This is also a very early release.

=head1 IMPORT OPTIONS

The I<import> method supports these keywords:

=over 4

=item * types

As an ArrayRef, calls C<<< Types::Registry->for_class($caller)->add_types(@$types) >>>.

As a ScalarRef, calls C<<< Types::Registry->for_class($caller)->add_types($$types) >>>.

=item * classes

For each class in this ArrayRef, calls C<<< Types::Registry->for_class($caller)->add_types(Type::Utils::class_type($class)) >>>.

=item * -nostdtypes

Do not import L<Types::Standard>.

=item * -trycatch

Import L<Syntax::Feature::Try> with type constraints.

=item * -autoclass

Enable auto-generation of class contraints (L<Type::Tiny::Class>) if the constraint looks like a package name (C</^\w+(::\w+)+$/>). This always takes precedence over the general type registry.

This also works with I<-trycatch>.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libmoove-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
