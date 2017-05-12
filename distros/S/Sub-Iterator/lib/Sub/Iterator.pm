package Sub::Iterator;

our $DATE = '2015-01-17'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_array_iterator
                       gen_fh_iterator
               );

sub gen_array_iterator {
    my $array = shift;
    my $i = 0;
    return sub {
        if ($i >= @$array) { undef } else { $array->[$i++] }
    };
}

sub gen_fh_iterator {
    my $fh = shift;
    return sub {
        if (eof($fh)) { undef } else { ~~<$fh> }
    };
}

1;
# ABSTRACT: Generate iterator coderefs

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Iterator - Generate iterator coderefs

=head1 VERSION

This document describes version 0.01 of Sub::Iterator (from Perl distribution Sub-Iterator), released on 2015-01-17.

=head1 SYNOPSIS

 use Sub::Iterator qw(gen_array_iterator gen_fh_iterator);

 my $sub = gen_array_iterator([1, 2, 3]);
 $sub->(); # -> 1
 $sub->(); # -> 2
 $sub->(); # -> 3
 $sub->(); # -> undef

=head1 FUNCTIONS

=head2 gen_array_iterator(\@ary) -> code

=head2 gen_fh_iterator($fh) -> code

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sub-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sub-Iterator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Iterator>

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
