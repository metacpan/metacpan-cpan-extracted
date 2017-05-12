package Regexp::Common::RegexpPattern;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Regexp::Common 'pattern';
use Regexp::Pattern 're';

pattern
    name   => ['RegexpPattern', '-pat', '-args'],
    create => sub {
        my $obj = shift;
        my $args = $obj->{flags}{-args} // [];
        $args = [split /,/, $args] unless ref $args;
        my $re = re($obj->{flags}{-pat}, @$args);
    },
;

1;
# ABSTRACT: Regexps from Regexp::Pattern::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Common::RegexpPattern - Regexps from Regexp::Pattern::* modules

=head1 VERSION

This document describes version 0.001 of Regexp::Common::RegexpPattern (from Perl distribution Regexp-Common-RegexpPattern), released on 2016-09-14.

=head1 SYNOPSIS

 use Regexp::Pattern 'RegexpPattern';

 say "Input does not look like YouTube video ID"
     unless $input =~ $RE{RegexpPattern}{-pat => "YouTube::video_id"};

=head1 DESCRIPTION

This is a bridge module between L<Regexp::Common> and L<Regexp::Pattern>. It
allows you to use Regexp::Pattern regexps from Regexp::Common.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Common-RegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Common-RegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Common-RegexpPattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::RegexpCommon>, the counterpart.

L<Regexp::Common>

L<Regexp::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
