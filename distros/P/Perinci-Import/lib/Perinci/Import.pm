package Perinci::Import;

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

our $VERSION = '0.03'; # VERSION

sub import {
    my $pkg = shift;
    my $mod = shift or die "Please specify module to import";

    my $modpm = $mod; $modpm =~ s!::!/!g; $modpm .= ".pm";
    require $modpm;

    my @caller  = caller(0);
    my $target = $caller[0];

    my %exports;
    my $metas = do { no warnings; no strict 'refs'; \%{"$mod\::SPEC"} };
    use experimental 'smartmatch';

    $metas //= {};
    for my $k (keys %$metas) {
        # for now we limit ourselves to subs
        next unless $k =~ /\A\w+\z/;
        $exports{$k} = {
            tags => [@{ $metas->{$k}{tags} // []}],
        };
    }

    for my $k (keys %exports) {
        push @{$exports{$k}{tags}}, 'all';
    }

    my @imps; # requested symbols or tags to export, each element is:
    while (1) {
        last unless @_;
        my $i = shift;
        my $el = {};
        if (@_ && ref($_[0]) eq 'HASH') {
            my $io = shift;
            $el->{$_} = $io->{$_} for keys %$io;
        };
        $el->{-sym} = $i;
        push @imps, $el;
    }

    if (!@imps) {
        push @imps, {-sym=>':default'};
    }

    for my $imp (@imps) {
        my @syms; # symbols from imported module
        if ($imp->{-sym} =~ s/^://) {
            @syms = grep {$imp->{-sym} ~~ $exports{$_}{tags}} keys %exports;
        } else {
            @syms = ($imp->{-sym});
        }

        for my $sym (sort @syms) {

            if (!$exports{$sym}) {
                die "$sym is not exported by $mod";
            }

            # export to what target symbol?
            my $tsym;
            if ($imp->{-as}) {
                $tsym = $imp->{-as};
            } else {
                $tsym = $sym;
                if (my $prefix = $imp->{-prefix}) {
                    $tsym = "$prefix$tsym";
                }
                if (my $suffix = $imp->{-suffix}) {
                    $tsym = "$tsym$suffix";
                }
            }

            # should we wrap?
            my $sub = \&{"$mod\::$sym"};
            my $do_wrap = $imp->{-wrap} // (grep {/\A\w/} keys %$imp);
            if ($do_wrap) {
                my %wrap_args = (
                    sub_name  => "$mod\::$sym",
                    meta      => $metas->{$sym},
                    meta_name => "$mod\::SPEC{$sym}",
                    convert   => { map {$_=>$imp->{$_}}
                                       grep {/\A\w/} keys %$imp },
                );
                require Perinci::Sub::Wrapper;
                my $res = Perinci::Sub::Wrapper::wrap_sub(%wrap_args);
                die "Can't wrap $sym: $res->[0] - $res->[1]"
                    unless $res->[0] == 200;
                $sub = $res->[2]{sub};
            }
            { no strict 'refs'; *{"$target\::$tsym"} = $sub }

        } # for @syms

    } # for @imps
}

1;
# ABSTRACT: Import functions from another module

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Import - Import functions from another module

=head1 VERSION

This document describes version 0.03 of Perinci::Import (from Perl distribution Perinci-Import), released on 2015-09-03.

=head1 SYNOPSIS

 # import some functions
 use Perinci::Import 'Some::Module', 'func1', 'func2';

 # import wrapped function
 use Perinci::Import 'Some::Function', func1 => {retry => 3};

 # import all (public) functions
 use Perinci::Import 'Some::Module', ':all';

=head1 DESCRIPTION

This module is the counterpart of L<Perinci::Exporter> (with slightly
incompatible semantic in syntax). It lets you import functions from another
modules. Imported modules need not define an exporter; the list of importable
functions, their tags, etc are consulted from L<Rinci> metadata (located in
C<%SPEC> package variable). Other features include: wrapping functions,
importing to another name, etc.

C<Perinci::Import> is now preferred over C<Perinci::Exporter> as this frees
module authors from specifying an exporter explicitly. Personally, I also
use the venerable L<Exporter> on some modules.

=head1 IMPORTING

The basic syntax is:

 use Perinci::Import <MODULE::NAME> [FUNC | FUNC => \%OPTS, ...]

B<Default exports>. If you specify no arguments:

 use Perinci::Import 'Some::Module';

this will import all functions having the C<default> tag. For example:

 package Some::Module;
 our %SPEC;
 $SPEC{func1} = { v=>1.1, tags=>[qw/default a/] };
 sub   func1    { ... }
 $SPEC{func2} = { v=>1.1, tags=>[qw/default a b/] };
 sub   func2    { ... }
 $SPEC{func3} = { v=>1.1, tags=>[qw/b c/] };
 sub   func3    { ... }
 1;

C<Some::Module> will by default export C<f1> and C<f2>.

B<Importing individual functions>. You can import individual functions:

 use Perinci::Import 'Some::Module', qw(f1 f2);

Each function can have import options, specified in a hashref:

 # this imports f1 and f2 (as bar)
 use Perinci::Import 'Some::Module', f1 => {args_as=>'array'}, f2=>{-as=>'bar'};

Each import key, unless those prefixed by dash (C<->) will be passed to the
C<convert> argument of L<Perinci::Sub::Wrapper>'s C<wrap_sub()>. Function will
be wrapped if one of more such arguments are specified (or C<< -wrap => 1 >> is
given. In the above example, C<f1> is wrapped because C<args_as> is specified.
C<f2> is not wrapped.

B<Importing groups of functions by tags>. You can import groups of functions
using tags. Tags are collected from function metadata, and written with a C<:>
prefix (to differentiate them from function names). Each tag can also have
import options:

 use YourModule 'f3', ':a' => {-prefix => 'a_'}; # imports f3, a_f1, a_f2

Some tags are defined automatically: C<:default>, C<:all>.

B<Importing to a different name>. As can be seen from previous examples, the
C<-as> and C<-prefix> (and also C<-suffix>) import options can be used to import
subroutines using into a different name.

=head1 FAQ

=head1 SEE ALSO

L<Perinci>, L<Perinci::Exporter>

L<Sub::Exporter>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Import>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Import>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Import>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
