## no critic ()

package PERLANCAR::YAML::Any;

our $DATE = '2019-02-28'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT = qw(Dump Load);
our @EXPORT_OK = qw(DumpFile LoadFile);

our @IMPLEMENTATIONS = (
    'YAML::XS',
    'YAML::Syck',
    'YAML::Old',
    'YAML',
    'YAML::Tiny',
);

sub _do {
    my $sub = shift;

    for my $impl (@IMPLEMENTATIONS) {
        (my $impl_pm = "$impl.pm") =~ s!::!/!g;
        eval { require $impl_pm; 1 };
        next if $@;
        my $res; eval { $res = &{"$impl\::$sub"}(@_) };
        if ($@) {
            log_trace "$impl\::$sub died: $@, trying other implementation ...";
            last;
        }
        return $res;
    }
    die "No YAML implementation can be used for $sub()";
}

sub Load     { _do('Load', @_) }
sub LoadFile { _do('LoadFile', @_) }
sub Dump     { _do('Dump', @_) }
sub DumpFile { _do('DumpFile', @_) }

1;
# ABSTRACT: Pick a YAML implementation and use it

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::YAML::Any - Pick a YAML implementation and use it

=head1 VERSION

This document describes version 0.001 of PERLANCAR::YAML::Any (from Perl distribution PERLANCAR-YAML-Any), released on 2019-02-28.

=head1 SYNOPSIS

 use PERLANCAR::YAML::Any;
 my $data = Load("yaml ...");

=head1 DESCRIPTION

This is like L<YAML::Any> (or L<YAML>) except that it tries the next
implementation when an implementation dies.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-YAML-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-YAML-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-YAML-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<YAML::Any>, L<YAML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
