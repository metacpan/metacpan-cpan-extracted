package Progress::Any::Output;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-15'; # DATE
our $DIST = 'Progress-Any'; # DIST
our $VERSION = '0.219'; # VERSION

use 5.010001;
use strict;
use warnings;

require Progress::Any;

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
        my $outputpm = $output; $outputpm =~ s!::!/!g; $outputpm .= ".pm";
        require "Progress/Any/Output/$outputpm";
        no strict 'refs';
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

This document describes version 0.219 of Progress::Any::Output (from Perl distribution Progress-Any), released on 2020-08-15.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Progress::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
