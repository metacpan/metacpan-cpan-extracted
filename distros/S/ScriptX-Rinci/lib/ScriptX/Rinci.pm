package ScriptX::Rinci;

use strict 'subs', 'vars';
use parent 'ScriptX::Base';
require ScriptX;

sub meta {
    +{
        summary => 'Run Rinci function',
    };
}

sub new {
    my ($class, %args) = (shift, @_);
    $args{func} or die "Please specify func";
    $args{func} =~ /\A\w+(::\w+)+\z/ or die "Invalid syntax for func, please use PACKAGE::FUNCNAME";
    $class->SUPER::new(%args);
}

sub on_run {
    my ($self, $stash) = @_;

    my $func = $self->{func};
    my ($pkg, $uqfunc) = $func =~ /(.+)::(.+)/;
    $pkg ||= "main";
    $uqfunc ||= $func;

    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
    require $pkg_pm;

    my $meta = ${"$pkg\::SPEC"}{$uqfunc}
        or die "There is no Rinci metadata for $func";

    # we should just supply a handler for get_args and not define it
    ScriptX::run_event(
        name => 'get_args',
        on_success => sub {
            require Perinci::Sub::GetArgs::Argv;

            my $stash = shift;

            $stash->{args} //= {};

            my $res = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
                args => $stash->{args},
                argv => \@ARGV,
                meta => $meta,
            );
            die "Cannot get arguments: $res->[0] - $res->[1]" unless $res->[0] == 200;
            [200];
        },
    );

    # XXX check args_as
    my $res = &{$func}(%{ $stash->{args} });

    $res = [200, "OK", $res] if $meta->{result_naked};

    require Perinci::Result::Format::Lite;

    print Perinci::Result::Format::Lite::format($res, 'text');

    $res;
}

1;
# ABSTRACT: Run Rinci function

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Rinci - Run Rinci function

=head1 VERSION

This document describes version 0.000 of ScriptX::Rinci (from Perl distribution ScriptX-Rinci), released on 2020-09-03.

=head1 SYNOPSIS

 use ScriptX 'Rinci' => {
     func => 'PACKAGENAME::FUNCNAME',
 };

=head1 DESCRIPTION

B<EARLY, EXPERIMENTAL RELEASE. MOST THINGS ARE NOT IMPLEMENTED YET.>

The goal of this plugin (and other related plugins) is to replace
L<Perinci::CmdLine> (this includes L<Perinci::CmdLine::Classic> and
L<Perinci::CmdLine::Lite>) with a more modular and flexible framework.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX-Rinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
