package Software::Release::Watch::ExtractInfo::Filename;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010;
use Log::ger;
use Moo::Role;

#my @archive_exts = qw(tar.gz tar.bz2 tar zip rar);
#my $archive_re   = join("|", map {quotemeta} @archive_exts);
#$archive_re = qr/\.$archive_re$/i;

# XXX some software use _ (or perhaps space) to separate name and
# version

sub extract_info {
    my ($sel, $fn) = @_;

    unless ($fn =~ /\A(.+)-([0-9].+)\z/) {
        log_warn("Can't parse filename: %s", $fn);
        return;
    }

    {name=>$1, v=>$2};
}

1;
# ABSTRACT: Parse releases from name like 'NAME-VERSION'

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Release::Watch::ExtractInfo::Filename - Parse releases from name like 'NAME-VERSION'

=head1 VERSION

This document describes version 0.05 of Software::Release::Watch::ExtractInfo::Filename (from Perl distribution Software-Release-Watch), released on 2017-07-10.

=for Pod::Coverage extract_info

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Release-Watch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Release-Watch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Release-Watch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
