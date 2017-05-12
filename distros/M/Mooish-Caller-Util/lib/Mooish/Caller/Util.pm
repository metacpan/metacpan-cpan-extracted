package Mooish::Caller::Util;

our $DATE = '2015-07-30'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use warnings;
use strict;

use Exporter qw(import);
our @EXPORT_OK = qw(get_constructor_caller
                    get_constructor_callers);

sub _get_constructor_caller_or_callers {
    no strict 'refs';

    my $routine = shift;

    my $start = $_[0] // 0;
    my $with_args = $_[1];

    my @res;

    my $objsys;
    my $is_build;
    my $wrappers_done;

    my $i = 0;
    my $j = 0;
    my $skips = 0;
    while (1) {
        $i++;
        my @caller;
        if ($with_args) {
            {
                package DB;
                @caller = caller($i);
                $caller[11] = [@DB::args] if @caller;
            }
        } else {
            @caller = caller($i);
        }
        last unless @caller;

        if ($i == 1) {
            my $subpkg;
            if ($caller[3] =~ /(.+)::BUILD(ARGS)?\z/) {
                $subpkg = $1;
                $is_build = !$2;
            } else {
                die "$routine(): Not called directly inside BUILD/BUILDARGS";
            }

            if ($is_build) {
                if ($caller[0] eq 'Method::Generate::BuildAll' ||
                        $caller[0] eq 'Method::Generate::Constructor') {
                    $objsys = 'Moo';
                    next;
                } elsif ($caller[0] eq 'Mo::build') {
                    $objsys = 'Mo';
                    next;
                } elsif ($caller[0] eq 'Class::MOP::Method') {
                    $objsys = 'Moose';
                    next;
                } elsif (grep {$_ eq "Mouse::Object"} @{"$subpkg\::ISA"}) {
                    $objsys = 'Mouse';
                    next;
                } else {
                    die "$routine(): Unknown object system ".
                        "(only Mo/Moo/Moose/Mouse supported for BUILD)";
                }
            } else { # BUILDARGS
                if ($caller[0] eq 'Moo::Object') {
                    $objsys = 'Moo';
                    next;
                } elsif ($caller[0] eq 'Moose::Object') {
                    $objsys = 'Moose';
                    next;
                } elsif (grep {$_ eq "Mouse::Object"} @{"$subpkg\::ISA"}) {
                    $objsys = 'Mouse';
                    next;
                } else {
                    die "$routine(): Unknown object system ".
                        "(only Moo/Moose/Mouse supported for BUILDARGS)";
                }
            }
        } else {
            unless ($wrappers_done) {
                if ($is_build) {
                    if ($objsys eq 'Mo') {
                        next if $caller[3] eq 'Mo::build::__ANON__';
                        $wrappers_done++;
                    } elsif ($objsys eq 'Moo') {
                        next if $caller[0] eq 'Moo::Object' ||
                            $caller[3] eq 'Moo::Object::new';
                        $wrappers_done++;
                    } elsif ($objsys eq 'Moose') {
                        next if $caller[0] eq 'Moose::Object' ||
                            $caller[0] eq 'Moose::Meta::Class' ||
                            $caller[3] eq 'Moose::Object::new';
                        $wrappers_done++;
                    } else { # Mouse
                        if ($] < 5.014) {
                            next if $skips++ < 1 && $caller[3] =~ /eval/;
                        }
                        $wrappers_done++;
                    }
                } else { # BUILDARGS
                    if ($objsys eq 'Moo') {
                        next if $caller[3] eq 'Moo::Object::new';
                        $wrappers_done++;
                    } elsif ($objsys eq 'Moose') {
                        next if $caller[3] eq 'Moose::Object::new';
                        $wrappers_done++;
                    } else { # Mouse
                        if ($] < 5.014) {
                            next if $skips++ < 1 && $caller[3] =~ /eval/;
                        }
                        $wrappers_done++;
                    }
                }
            }
        }

        $j++;
        push @res, \@caller;
        last if $routine eq 'get_constructor_caller' && $j > $start;
    }

    if ($routine eq 'get_constructor_caller') {
        return $res[$start];
    } else {
        splice(@res, 0, $start);
        return @res;
    }
}

sub get_constructor_caller {
    unshift @_, "get_constructor_caller";
    goto &_get_constructor_caller_or_callers;
}

sub get_constructor_callers {
    unshift @_, "get_constructor_callers";
    goto &_get_constructor_caller_or_callers;
}

1;
# ABSTRACT: Get constructor caller from inside Mo/Moo/Moose/Mouse's BUILD/BUILDARGS

__END__

=pod

=encoding UTF-8

=head1 NAME

Mooish::Caller::Util - Get constructor caller from inside Mo/Moo/Moose/Mouse's BUILD/BUILDARGS

=head1 VERSION

This document describes version 0.06 of Mooish::Caller::Util (from Perl distribution Mooish-Caller-Util), released on 2015-07-30.

=head1 SYNOPSIS

 package MyClass;
 use Moo; # or Mo 'build', or Moose, or Mouse
 use Mooish::Util::Caller qw(get_constructor_caller get_constructor_callers);

 sub BUILD { # or BUILDARGS
     $caller = get_constructor_caller();
     say $caller->[3]; # subroutine name
 }

 package main;
 sub f1 { MyClass->new }
 sub f2 { f1 }
 f2; # prints 'main::f1'

=head1 FUNCTIONS

=head2 get_constructor_caller([ $start=0 [, $with_args] ]) => ARRAYREF

Like C<[caller($start)]>, but skips Mo/Moo/Moose/Mouse wrappers. Result will be
like:

 #  0          1           2       3             4          5            6           7             8        9          10
 [$package1, $filename1, $line1, $subroutine1, $hasargs1, $wantarray1, $evaltext1, $is_require1, $hints1, $bitmask1, $hinthash1],

If C<$with_args> is true, will also return subroutine arguments in the 11th
element, produced by retrieving C<@DB::args>.

=head2 get_constructor_callers([ $start=0 [, $with_args] ]) => LIST

A convenience function to return the whole callers stack, akin to what is
produced by collecting result from C<get_constructor_caller($start+1)> up until
the last frame in caller stack. Result will be like:

 (
     # for frame 0
     #  0          1           2       3             4          5            6           7             8        9          10
     [$package1, $filename1, $line1, $subroutine1, $hasargs1, $wantarray1, $evaltext1, $is_require1, $hints1, $bitmask1, $hinthash1],

     # for next frame
     [$package2, $filename2, $line2, ...]

     ...
 )

If C<$with_args> is true, will also return subroutine arguments in the 11th
element for each frame, produced by retrieving C<@DB::args>.

=head1 SEE ALSO

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Mooish-Caller-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Mooish-Caller-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mooish-Caller-Util>

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
