package Software::Catalog::SW::bulwark::qt;

our $DATE = '2019-10-26'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use PerlX::Maybe;

use Role::Tiny::With;
with 'Versioning::Scheme::Dotted';
with 'Software::Catalog::Role::Software';

use Software::Catalog::Util qw(extract_from_url);

sub homepage_url { "https://bulwarkcrypto.com/" }

sub latest_version {
    my ($self, %args) = @_;

    extract_from_url(
        url => "https://github.com/bulwark-crypto/Bulwark/releases",
        re  => qr!/bulwark-crypto/Bulwark/releases/download/\d+(?:\.\d+)+/bulwark-(\d+(?:\.\d+)+)-linux64\.!,
    );
}

sub available_versions {
    my ($self, %args) = @_;

    my $res = extract_from_url(
        url => "https://github.com/bulwark-crypto/Bulwark/releases",
        re  => qr!/bulwark-crypto/Bulwark/tree/([^"/]+)!,
        all => 1,
    );
    return $res unless $res->[0] == 200;
    # sort versions from earliest
    $res->[2] = [ sort { $self->cmp_version($a, $b) } @{$res->[2]}];
    $res;
}

sub release_note {
    require Mojo::DOM;

    my ($self, %args) = @_;
    my $format = $args{format} // 'text';

    # 2.1.1 tree means version 2.1.1.0
    my $version = $args{version} // do {
        my $res = $self->latest_version(%args);
        return $res unless $res->[0] == 200;
        $res->[2];
    };
    $version =~ s/\.0\z// if $version =~ /\A\d+\.\d+\.\d+\.0\z/;

    my $url = "https://github.com/bulwark-crypto/Bulwark/releases/tag/$version";
    my $res = extract_from_url(
      url => $url,
      code => sub {
          my %cargs = @_;
          my $dom = Mojo::DOM->new($cargs{content});
          my $html = $dom->at(".markdown-body")->content;

          if ($html) {
              if ($format eq 'html') {
                  return [200, "OK", $html];
              } else {
                  require HTML::FormatText::Any;
                  return [200, "OK",
                          HTML::FormatText::Any::html2text(html => $html)->[2]];
              }
          } else {
              return [543, "Cannot scrape release note text from $url"];
          }
      },
  );
}

sub canon2native_arch_map {
    return +{
        'linux-x86' => 'linux32',
        'linux-x86_64' => 'linux64',
        'win32' => 'win32',
        'win64' => 'win64',
    },
}

# version
# arch
sub download_url {
    my ($self, %args) = @_;

    my $version = $args{version};
    if (!$version) {
        my $verres = $self->latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $version = $verres->[2];
    }

    my $v0;
    if ($version =~ /\A(\d+\.\d+\.\d+)\.\d+\z/) {
        $v0 = $1;
    } else {
        die "Can't recognize version format $version (not x.y.z.a)";
    }

    my $ext;
    if ($args{arch} =~ /linux/) {
        $ext = ".tar.gz";
    } else {
        $ext = ".zip";
    }

    my $filename = join(
        "",
        "bulwark-$version-", $self->_canon2native_arch($args{arch}), $ext);

    [200, "OK",
     join(
         "",
         "https://github.com/bulwark-crypto/Bulwark/releases/download/$v0/$filename",
     ), {
         'func.filename' => $filename,
     }];
}

sub archive_info {
    my ($self, %args) = @_;

    my $v = $args{version} // latest_version()->[2];

    [200, "OK", {
        programs => [
            {name=>"bulwark-cli", path=>"/"},
            {name=>"bulwark-qt", path=>"/"},
            {name=>"bulwarkd", path=>"/"},
        ],
        unwrap => $self->cmp_version($v, '2.0.0.0') == -1 ? 1:0,
    }];
}

1;
# ABSTRACT: Bulwark desktop GUI client

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::SW::bulwark::qt - Bulwark desktop GUI client

=head1 VERSION

This document describes version 0.007 of Software::Catalog::SW::bulwark::qt (from Perl distribution Software-Catalog-SW-bulwark-qt), released on 2019-10-26.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog-SW-bulwark-qt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog-SW-bulwark-qt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog-SW-bulwark-qt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
