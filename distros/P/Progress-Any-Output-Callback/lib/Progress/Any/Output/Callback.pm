package Progress::Any::Output::Callback;

our $DATE = '2015-08-17'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    $args{callback} or die "Please specify 'callback'";

    bless \%args, $class;
}

sub update {
    $_[0]->{callback}->(@_);
}

1;
# ABSTRACT: Propagate progress update to a callback function

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::Callback - Propagate progress update to a callback function

=head1 VERSION

This document describes version 0.04 of Progress::Any::Output::Callback (from Perl distribution Progress-Any-Output-Callback), released on 2015-08-17.

=head1 SYNOPSIS

 use Progress::Any::Output;
 Progress::Any::Output->set(
     'Callback',
     callback=>sub {
         my ($self, %args) = @_;
         ...
     }
 );

=head1 DESCRIPTION

This output propagates progress update to your specified callback. Callback will
receive what the output's update() receives: C<< $self, %args >> where C<%args>
contains: C<indicator>, C<message>, C<level>, etc.

=for Pod::Coverage ^(update)$

=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("Callback", %args) >>.

Known arguments:

=over

=item * callback => CODE

Required.

=back

=head1 SEE ALSO

L<Progress::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any-Output-Callback>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any-Output-Callback>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any-Output-Callback>

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
