package Pod::Weaver::Plugin::Run;

our $DATE = '2016-10-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);

has include_module => (
    is => 'rw',
);
has include_module_pattern => (
    is => 'rw',
);
has include_file => (
    is => 'rw',
);
has include_file_pattern => (
    is => 'rw',
);
has exclude_module => (
    is => 'rw',
);
has exclude_module_pattern => (
    is => 'rw',
);
has exclude_file => (
    is => 'rw',
);
has exclude_file_pattern => (
    is => 'rw',
);
has code => (
    is => 'rw',
);

sub mvp_multivalue_args { qw(
                                include_module
                                include_file
                                include_file_pattern
                                exclude_module
                                exclude_module_pattern
                                exclude_file
                                exclude_file_pattern
                                exclude_module
                                exclude_module_pattern
                                code
                        ) }

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

  SELECT_FILE:
    {
        my ($package, $ext);
        if ($filename =~ m!^lib/(.+)\.(pod|pm)$!) {
            $package = $1;
            $ext = $2;
            $package =~ s!/!::!g;
        } else {
            $self->log(["skipped file %s (not a Perl module)", $filename]);
            return;
        }

        if (my $im = $self->{include_module}) {
            my $included;
            for my $m (ref($im) eq 'ARRAY' ? @$im : $im) {
                if ($package eq $m) {
                    $included++;
                    last;
                }
            }
            unless ($included) {
                $self->log(["skipped file %s (module %s not in include_module)",
                            $filename, $package]);
                return;
            }
        }
        if (my $imp = $self->{include_module_pattern}) {
            my $included;
            for my $p (ref($imp) eq 'ARRAY' ? @$imp : $imp) {
                if ($package =~ /$p/) {
                    $included++;
                    last;
                }
            }
            unless ($included) {
                $self->log(["skipped file %s (module %s doesn't match any include_module_pattern)",
                            $filename, $package]);
                return;
            }
        }
        if (my $em = $self->{exclude_module}) {
            my $excluded;
            for my $m (ref($em) eq 'ARRAY' ? @$em : $em) {
                if ($package eq $m) {
                    $excluded++;
                    last;
                }
            }
            if ($excluded) {
                $self->log(["skipped file %s (module %s in exclude_module)",
                            $filename, $package]);
                return;
            }
        }
        if (my $emp = $self->{exclude_module_pattern}) {
            my $excluded;
            for my $p (ref($emp) eq 'ARRAY' ? @$emp : $emp) {
                if ($package =~ /$p/) {
                    $excluded++;
                    last;
                }
            }
            if ($excluded) {
                $self->log(["skipped file %s (module %s matches exclude_module_pattern)",
                            $filename, $package]);
                return;
            }
        }
        if (my $if = $self->{include_file}) {
            my $included;
            for my $f (ref($if) eq 'ARRAY' ? @$if : $if) {
                if ($filename eq $f) {
                    $included++;
                    last;
                }
            }
            unless ($included) {
                $self->log(["skipped file %s (not in include_file)",
                            $filename]);
                return;
            }
        }
        if (my $ifp = $self->{include_file_pattern}) {
            my $included;
            for my $p (ref($ifp) eq 'ARRAY' ? @$ifp : $ifp) {
                if ($filename =~ /$p/) {
                    $included++;
                    last;
                }
            }
            unless ($included) {
                $self->log(["skipped file %s (doesn't match any include_file_pattern)",
                            $filename]);
                return;
            }
        }
        if (my $ef = $self->{exclude_file}) {
            my $excluded;
            for my $f (ref($ef) eq 'ARRAY' ? @$ef : $ef) {
                if ($filename eq $f) {
                    $excluded++;
                    last;
                }
            }
            if ($excluded) {
                $self->log(["skipped file %s (in exclude_file)",
                            $filename]);
                return;
            }
        }
        if (my $efp = $self->{exclude_file_pattern}) {
            my $excluded;
            for my $p (ref($efp) eq 'ARRAY' ? @$efp : $efp) {
                if ($filename =~ /$p/) {
                    $excluded++;
                    last;
                }
            }
            if ($excluded) {
                $self->log(["skipped file %s (matches exclude_file_pattern)",
                            $filename]);
                return;
            }
        }
    } # SELECT_FILE

    local @INC = ("lib", @INC);

    # XXX should compile code once, but why keeps compiling code?
    if (!$self->{_compiled_code}) {
        my $code = $self->code;
        die "Please specify code" unless $code;
        $code = join("\n", @$code) if ref($code) eq 'ARRAY';
        $self->log(["compiling code ..."]);
        $code = "sub { $code }" unless $code =~ /\A\s*sub\s*\{/s;
        $self->log(["code is: %s", $code]);
        $self->{_compiled_code} = eval $code;
        die "Can't compile code '$code': $@" if $@;
    }

    $self->log(["running code on file %s", $filename]);
    $self->{_compiled_code}->($self, $document, $input);
}

1;
# ABSTRACT: Write Pod::Weaver::Plugin directly in weaver.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Run - Write Pod::Weaver::Plugin directly in weaver.ini

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::Run (from Perl distribution Pod-Weaver-Plugin-Run), released on 2016-10-14.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Run]
 ;;; each of these options can be specified multiple times
 ;include_module = Foo
 ;include_module_pattern = ^Bar.+$
 ;exclude_module = Baz
 ;exclude_module_pattern = ^Qux
 ;include_file = lib/Quux.pm
 ;include_file_pattern = Corge\d+
 ;exclude_file = lib/Grault.pm
 ;exclude_file_pattern = Garply\d+

 code = sub { my ($self, $document, $input) = @_; ... }
 ;code = ...

=head1 DESCRIPTION

This plugin will compile the code specified in F<weaver.ini> and execute it. It
effectively lets you write C<weave_section()> directly in F<weaver.ini>.

=for Pod::Coverage ^(weave_section|mvp_multivalue_args)$

=head1 CONFIGURATION

=head2 include_module => str+

=head2 include_module_pattern => str+

=head2 exclude_module => str+

=head2 exclude_module_pattern => str+

=head2 include_file => str+

=head2 include_file_pattern => str+

=head2 exclude_file => str+

=head2 exclude_file_pattern => str+

=head2 code => str+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Run>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Run>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Run>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::Eval>, an older incarnation of this module.

L<Dist::Zilla::Plugin::Hook> lets you do something similar for L<Dist::Zilla>:
it lets you write dzil plugins directly in F<dist.ini>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
