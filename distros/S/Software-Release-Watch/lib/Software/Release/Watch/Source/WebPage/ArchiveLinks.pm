package Software::Release::Watch::Source::WebPage::ArchiveLinks;

use 5.010;
use Moo::Role;
use experimental 'smartmatch';

our $VERSION = '0.04'; # VERSION

#with 'Software::Release::Watch::Versioning';
with 'Software::Release::Watch::Source::WebPage';
with 'Software::Release::Watch::ExtractInfo::Filename';

requires 'filter_filename';

# XXX requires an info extractor from file name

my @archive_exts = qw(tar.gz tar.bz2 tar zip rar);
my $archive_re   = join("|", map {quotemeta} @archive_exts);
$archive_re = qr/\.($archive_re)\z/i;

sub parse_html {
    my ($self, $html) = @_;

    my $mech = $self->watcher->mech;

    # XXX what if we want to parse $html and not the one mech gets from url?

    my %releases; # key = v

    for my $link ($mech->links) {
        my $url = $link->url;
        my $fn  = $url;
        next unless $fn =~ s/$archive_re//o;
        $fn =~ s!.+/!!;
        next unless $self->filter_filename($fn);

        my $p = $self->extract_info($fn);
        next unless $p;
        $releases{$p->{v}} //= { urls => [] };
        push @{ $releases{$p->{v}}{urls} }, $url
            unless $url ~~ $releases{$p->{v}}{urls};
    }

    \%releases;
    #[map {{ version=>$_, $releases{$_} }}
    #     sort {$self->cmp_version($a, $b)} keys %releases];
}

1;
# ABSTRACT: Get releases from archive links in web page

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Release::Watch::Source::WebPage::ArchiveLinks - Get releases from archive links in web page

=head1 VERSION

This document describes version 0.04 of Software::Release::Watch::Source::WebPage::ArchiveLinks (from Perl distribution Software-Release-Watch), released on 2015-09-04.

=for Pod::Coverage parse_html

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

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
