package Progress::Any::Output;

use 5.010001;
use strict;
use warnings;

require Progress::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-18'; # DATE
our $DIST = 'Progress-Any'; # DIST
our $VERSION = '0.220'; # VERSION

sub import {
    my $self = shift;
    __PACKAGE__->set(@_) if @_;
}

sub _set_or_add {
    my $class = shift;
    my $which = shift;

    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = {%{shift()}}; # shallow copy
    } else {
        $opts = {};
    }

    # allow adding options via -name => val syntax, for ease in using via -M in
    # one-liners.
    while (1) {
        last unless @_ && $_[0] =~ /\A-(.+)/;
        $opts->{$1} = $_[1];
        splice @_, 0, 2;
    }

    my $output = shift or die "Please specify output name";
    $output =~ /\A(?:\w+(::\w+)*)?\z/ or die "Invalid output syntax '$output'";

    my $task = $opts->{task} // "";

    my $outputo;
    unless (ref $outputo) {
        (my $outputpm = "$output.pm") =~ s!::!/!g;
        require "Progress/Any/Output/$outputpm"; ## no critic: Modules::RequireBarewordIncludes
        $outputo = "Progress::Any::Output::$output"->new(@_);
    }

    if ($which eq 'set') {
        $Progress::Any::outputs{$task} = [$outputo];
    } else {
        $Progress::Any::outputs{$task} //= [];
        push @{ $Progress::Any::outputs{$task} }, $outputo;
    }

    $outputo;
}

sub set {
    my $class = shift;
    $class->_set_or_add('set', @_);
}

sub add {
    my $class = shift;
    $class->_set_or_add('add', @_);
}

1;
# ABSTRACT: Assign output to progress indicators

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output - Assign output to progress indicators

=head1 VERSION

This document describes version 0.220 of Progress::Any::Output (from Perl distribution Progress-Any), released on 2022-10-18.

=head1 SYNOPSIS

In your application:

 use Progress::Any::Output;
 Progress::Any::Output->set('TermProgressBarColor');

or:

 use Progress::Any::Output 'TermProgressBarColor';

To give parameters to output:

 use Progress::Any::Output;
 Progress::Any::Output->set('TermProgressBarColor', width=>50, ...);

or:

 use Progress::Any::Output 'TermProgressBarColor', width=>50, ...;

To assign output to a certain (sub)task:

 use Progress::Any::Output -task => "main.download", 'TermMessage';

or:

 use Progress::Any::Output;
 Progress::Any::Output->set({task=>'main.download'}, 'TermMessage');

To add additional output, use C<add()> instead of C<set()>.

=head1 DESCRIPTION

See L<Progress::Any> for overview.

=head1 METHODS

=head2 Progress::Any::Output->set([ \%opts ], $output[, @args]) => obj

Set (or replace) output. Will load and instantiate
C<Progress::Any::Output::$output>. To only set output for a certain (sub)task,
set C<%opts> to C<< { task => $task } >>. C<@args> will be passed to output
module's constructor.

Return the instantiated object.

If C<$output> is an object (a reference, really), it will be used as-is.

=head2 Progress::Any::Output->add([ \%opts ], $output[, @args])

Like set(), but will add output instead of replace existing one(s).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any>.

=head1 SEE ALSO

L<Progress::Any>

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

This software is copyright (c) 2022, 2020, 2018, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
