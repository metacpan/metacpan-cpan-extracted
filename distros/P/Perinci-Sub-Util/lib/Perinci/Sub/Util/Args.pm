package Perinci::Sub::Util::Args;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-02'; # DATE
our $DIST = 'Perinci-Sub-Util'; # DIST
our $VERSION = '0.471'; # VERSION

our @EXPORT_OK = qw(
                       args_by_tag
                       argnames_by_tag
                       func_args_by_tag
                       func_argnames_by_tag
                       call_with_its_args
);

sub args_by_tag {
    my ($meta, $args, $tag) = @_;

    my @res;
    my $args_prop = $meta->{args} or return ();
    my $neg = $tag =~ s/\A!//;
    for my $argname (keys %$args_prop) {
        my $argspec = $args_prop->{$argname};
        if ($neg) {
            next unless !$argspec->{tags} ||
                !(grep {$_ eq $tag} @{$argspec->{tags}});
        } else {
            next unless $argspec->{tags} &&
                grep {$_ eq $tag} @{$argspec->{tags}};
        }
        push @res, $argname, $args->{$argname}
            if exists $args->{$argname};
    }
    @res;
}

sub argnames_by_tag {
    my ($meta, $tag) = @_;

    my @res;
    my $args_prop = $meta->{args} or return ();
    my $neg; $neg = 1 if $tag =~ s/\A!//;
    for my $argname (keys %$args_prop) {
        my $argspec = $args_prop->{$argname};
        if ($neg) {
            next unless !$argspec->{tags} ||
                !(grep {$_ eq $tag} @{$argspec->{tags}});
        } else {
            next unless $argspec->{tags} &&
                grep {$_ eq $tag} @{$argspec->{tags}};
        }
        push @res, $argname;
    }
    sort @res;
}

sub _find_meta {
    my $caller = shift;
    my $func_name = shift;

    if ($func_name =~ /(.+)::(.+)/) {
        return ${"$1::SPEC"}{$2};
    } else {
        return ${"$caller->[0]::SPEC"}{$func_name};
    }
}

sub func_args_by_tag {
    my ($func_name, $args, $tag) = @_;
    my $meta = _find_meta([caller(1)], $func_name)
        or die "Can't find Rinci function metadata for $func_name";
    args_by_tag($meta, $args, $tag);
}

sub func_argnames_by_tag {
    my ($func_name, $tag) = @_;
    my $meta = _find_meta([caller(1)], $func_name)
        or die "Can't find Rinci function metadata for $func_name";
    argnames_by_tag($meta, $tag);
}

sub call_with_its_args {
    my ($func_name, $args) = @_;

    my ($meta, $func);
    if ($func_name =~ /(.+)::(.+)/) {
        defined &{$func_name}
            or die "Function $func_name not defined";
        $func = \&{$func_name};
        $meta = ${"$1::SPEC"}{$2};
    } else {
        my @caller = caller(1);
        my $fullname = "$caller[0]::$func_name";
        defined &{$fullname}
            or die "Function $fullname not defined";
        $func = \&{$fullname};
        $meta = ${"$caller[0]::SPEC"}{$func_name};
    }
    $meta or die "Can't find Rinci function metadata for $func_name";

    my @args;
    if ($meta->{args}) {
        for my $argname (keys %{ $meta->{args} }) {
            push @args, $argname, $args->{$argname}
                if exists $args->{$argname};
        }
    }
    $func->(@args);
}

1;
# ABSTRACT: Utility routines related to Rinci arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::Args - Utility routines related to Rinci arguments

=head1 VERSION

This document describes version 0.471 of Perinci::Sub::Util::Args (from Perl distribution Perinci-Sub-Util), released on 2023-07-02.

=head1 SYNOPSIS

 package MyPackage;

 use Perinci::Sub::Util::Args qw(
     args_by_tag
     argnames_by_tag
     func_args_by_tag
     func_argnames_by_tag
     call_with_its_args
 );

 our %SPEC;

 my %func1_args;

 $SPEC{myfunc1} = {
     v => 1.1,
     summary => 'My function one',
     args => {
         %func1_args = (
             foo => {tags=>['t1', 't2']},
             bar => {tags=>['t2', 't3']},
             baz => {},
         ),
     },
 };
 sub myfunc1 {
     my %args = @_;
 }

 $SPEC{myfunc2} = {
     v => 1.1,
     summary => 'My function two',
     args => {
         %func1_args,
         qux => {tags=>['t3']},
     },
 };
 sub myfunc2 {
     my %args = @_;
     my $res = call_with_its_args('myfunc1', \%args);
 }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 args_by_tag

Usage:

 my %args = args_by_tag($meta, \%args0, $tag);

Will select only keypairs from C<%args0> arguments which have tag C<$tag>.
Examples:

 my %args = args_by_tag($SPEC{myfunc1}, {foo=>1, bar=>2, baz=>3, qux=>4}, 't2'); # (foo=>1, bar=>2)

=head2 argnames_by_tag

Usage:

 my @arg_names = argnames_by_tag($meta, $tag);

Will select only argument names which have tag C<$tag>.

=head2 func_args_by_tag

Usage:

 my %args = func_args_by_tag($func_name, \%args0, $tag);

Like L</args_by_tag> except that instead of supplying Rinci function metadata,
you supply a function name. Rinci metadata will be searched in C<%SPEC>
variable.

=head2 func_argnames_by_tag

Usage:

 my @argnames = func_argnames_by_tag($func_name, $tag);

Like L</argnames_by_tag> except that instead of supplying Rinci function
metadata, you supply a function name. Rinci metadata will be searched in
C<%SPEC> variable.

=head2 call_with_its_args

Usage:

 my $res = call_with_its_args($func_name, \%args);

Call function with arguments taken from C<%args>. Only arguments which the
function declares it accepts will be passed.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
