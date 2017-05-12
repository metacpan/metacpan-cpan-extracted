package Reply::Plugin::DataDmp;

our $DATE = '2014-12-01'; # DATE
our $VERSION = '0.01'; # VERSION

use strict;
use warnings;

use base 'Reply::Plugin';

use Data::Dmp 'dmp';
use overload ();

sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    return $self;
}

sub mangle_result {
    my $self = shift;
    my (@result) = @_;
    return @result ? dmp(@result) : ();
}

1;
# ABSTRACT: Format results using Data::Dmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::DataDmp - Format results using Data::Dmp

=head1 VERSION

This document describes version 0.01 of Reply::Plugin::DataDmp (from Perl distribution Reply-Plugin-DataDmp), released on 2014-12-01.

=head1 SYNOPSIS

 ; .replyrc
 [DataDmp]

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Reply-Plugin-DataDmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Reply-Plugin-DataDmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Reply-Plugin-DataDmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
