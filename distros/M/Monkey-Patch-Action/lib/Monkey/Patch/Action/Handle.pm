package Monkey::Patch::Action::Handle;

our $DATE = '2018-04-02'; # DATE
our $VERSION = '0.061'; # VERSION

use 5.010;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use Sub::Delete;

my %stacks;

sub __find_previous {
    my ($stack, $code) = @_;
    state $empty = sub {};

    for my $i (1..$#$stack) {
        if ($stack->[$i][1] == $code) {
            return $stack->[$i-1][2] // $stack->[$i-1][1];
        }
    }
    $empty;
}

sub new {
    my ($class, %args) = @_;

    my $type = $args{-type};
    delete $args{-type};

    my $code = $args{code};

    my $name = "$args{package}::$args{subname}";
    my $stack;
    if (!$stacks{$name}) {
        $stacks{$name} = [];
        push @{$stacks{$name}}, [sub => \&$name] if defined(&$name);
    }
    $stack = $stacks{$name};

    my $self = bless \%args, $class;

    no strict 'refs';
    no warnings 'redefine';
    if ($type eq 'sub') {
        push @$stack, [$type => $code];
        *$name = $code;
    } elsif ($type eq 'delete') {
        $code = sub {};
        $args{code} = $code;
        push @$stack, [$type, $code];
        delete_sub $name;
    } elsif ($type eq 'wrap') {
        weaken($self);
        my $wrapper = sub {
            my $ctx = {
                package => $self->{package},
                subname => $self->{subname},
                extra   => $self->{extra},
                orig    => __find_previous($stack, $self->{code}),
            };
            unshift @_, $ctx;
            goto &{$self->{code}};
        };
        push @$stack, [$type => $code => $wrapper];
        *$name = $wrapper;
    }

    $self;
}

sub DESTROY {
    my $self = shift;

    my $name  = "$self->{package}::$self->{subname}";
    my $stack = $stacks{$name};
    my $code  = $self->{code};

    for my $i (0..$#$stack) {
        if($stack->[$i][1] == $code) {
            if ($stack->[$i+1]) {
                # check conflict
                if ($stack->[$i+1][0] eq 'wrap' &&
                        ($i == 0 || $stack->[$i-1][0] eq 'delete')) {
                    my $p = $self->{patcher};
                    warn "Warning: unapplying patch to $name ".
                        "(applied in $p->[1]:$p->[2]) before a wrapping patch";
                }
            }

            no strict 'refs';
            if ($i == @$stack-1) {
                if ($i) {
                    no warnings 'redefine';
                    if ($stack->[$i-1][0] eq 'delete') {
                        delete_sub $name;
                    } else {
                        *$name = $stack->[$i-1][2] // $stack->[$i-1][1];
                    }
                } else {
                    delete_sub $name;
                }
            }
            splice @$stack, $i, 1;
            last;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Monkey::Patch::Action::Handle

=head1 VERSION

This document describes version 0.061 of Monkey::Patch::Action::Handle (from Perl distribution Monkey-Patch-Action), released on 2018-04-02.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Monkey-Patch-Action>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Monkey-Patch-Action>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Monkey-Patch-Action>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
