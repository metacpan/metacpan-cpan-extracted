package PERLANCAR::Exporter::Lite;

our $DATE = '2016-03-13'; # DATE
our $VERSION = '0.02'; # VERSION

# Be lean.
#use strict;
#use warnings;

sub import {
    my $pkg0 = shift;
    if (@_ && $_[0] eq 'import') {
        my $exporter = caller;
        *{"$exporter\::import"} = sub {
            my $pkg = shift;
            my $caller = caller;
            my @exp = @_ ? @_ : @{"$exporter\::EXPORT"};
            for my $exp (@exp) {
                unless (grep {$_ eq $exp} (@{"$exporter\::EXPORT"},
                                           @{"$exporter\::EXPORT_OK"})) {
                    die "$exp is not exported by $exporter";
                }
                if ($exp =~ /\A\$(.+)/) {
                    *{"$caller\::$1"} = \${"$exporter\::$1"};
                } elsif ($exp =~ /\A\@(.+)/) {
                    *{"$caller\::$1"} = \@{"$exporter\::$1"};
                } elsif ($exp =~ /\A\%(.+)/) {
                    *{"$caller\::$1"} = \%{"$exporter\::$1"};
                } elsif ($exp =~ /\A\*(\w+)\z/) {
                    *{"$caller\::$1"} = *{"$exporter\::$1"};
                } elsif ($exp =~ /\A&?(\w+)\z/) {
                    *{"$caller\::$1"} = \&{"$exporter\::$1"};
                } else {
                    die "Invalid export '$exp'";
                }
            }
        };
    }
}

1;
# ABSTRACT: A stripped down Exporter

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Exporter::Lite - A stripped down Exporter

=head1 VERSION

This document describes version 0.02 of PERLANCAR::Exporter::Lite (from Perl distribution PERLANCAR-Exporter-Lite), released on 2016-03-13.

=head1 SYNOPSIS

In F<lib/YourModule.pm>:

 package YourModule;
 use PERLANCAR::Exporter::Lite qw(import);
 our @EXPORT = qw(...);
 our @EXPORT_OK = qw(...);

=head1 DESCRIPTION

This is a stripped down exporter module, to achieve the smallest startup
overhead (see L<Bencher::Scenario::Exporters::Startup> for benchmark). This is
what I think L<Exporter::Lite> should be.

This module offers only some features of L<Exporter>: default exports via
C<@EXPORT> and optional exports via C<@EXPORT_OK>. You can only use this
exporter by importing its C<import> and not by subclassing. There is no support
for export tags, C<export_to_level>, etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Exporter-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Exporter-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Exporter-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Exporter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
