package Module::CheckVersion::cpan;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010;
use strict;
use warnings;

use HTTP::Tiny;
use JSON::MaybeXS;

sub check_latest_version {
    my ($mod, $installed_version, $chkres) = @_;

    my $res = HTTP::Tiny->new->get("http://fastapi.metacpan.org/v1/module/$mod?fields=name,version");
    return [$res->{status}, "API request failed: $res->{reason}"] unless $res->{success};
    eval { $res = JSON::MaybeXS::decode_json($res->{content}) };
    return [500, "Can't decode JSON API response: $@"] if $@;
    return [500, "Error from API response: $res->{message}"] if $res->{message};
    my $latest_version = $res->{version};

    $chkres->{installed_version} = $installed_version;
    $chkres->{latest_version} = $latest_version;
    if (defined $installed_version) {
        my $cmp = eval {
            version->parse($installed_version) <=>
                version->parse($latest_version);
        };
        if ($@) {
            $chkres->{compare_version_err} = @_;
            $chkres->{is_latest_version} = undef;
        } else {
            $chkres->{is_latest_version} = $cmp >= 0 ? 1:0;
        }
    } else {
        $chkres->{is_latest_version} = 0;
    }
    [200];
}

1;
# ABSTRACT: Handler for cpan

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CheckVersion::cpan - Handler for cpan

=head1 VERSION

This document describes version 0.08 of Module::CheckVersion::cpan (from Perl distribution Module-CheckVersion), released on 2017-06-09.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CheckVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CheckVersion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CheckVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
