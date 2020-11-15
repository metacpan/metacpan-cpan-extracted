package Require::Hook::Source::MetaCPAN;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-13'; # DATE
our $DIST = 'Require-Hook-Source-MetaCPAN'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

# preload to avoid deep recursion in our INC
use HTTP::Tiny;
use IO::Socket::SSL;
use URI::URL;
# to trigger lazy loading
{ my $url = URI::URL->new("/foo", "https://example.com")->abs }

sub new {
    my ($class, %args) = @_;
    $args{die} = 1 unless defined $args{die};
    bless \%args, $class;
}

sub Require::Hook::Source::MetaCPAN::INC {
    my ($self, $filename) = @_;

    (my $pkg = $filename) =~ s/\.pm$//; $pkg =~ s!/!::!g;

    my $url = "https://metacpan.org/pod/$pkg";
    my $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef;
    };

    $resp->{content} =~ m!href="(.+?\?raw=1)"! or do {
        die "Can't load $filename: Can't find source URL in $url" if $self->{die};
        return undef;
    };

    $url = URI::URL->new($1, $url)->abs . "";
    log_trace "[RH:Source::MetaCPAN] Retrieving module source for $filename from $url ...";
    $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef;
    };

    \($resp->{content});
}

1;
# ABSTRACT: Load module source code from MetaCPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Hook::Source::MetaCPAN - Load module source code from MetaCPAN

=head1 VERSION

This document describes version 0.002 of Require::Hook::Source::MetaCPAN (from Perl distribution Require-Hook-Source-MetaCPAN), released on 2020-11-13.

=head1 SYNOPSIS

 {
     local @INC = (@INC, Require::Hook::Source::MetaCPAN->new);
     require Foo::Bar; # will be searched from MetaCPAN
     # ...
 }

=head1 DESCRIPTION

Warning: this is most probably not suitable for use in production or real-world
code.

=for Pod::Coverage .+

=head1 METHODS

=head2 new([ %args ]) => obj

Constructor. Known arguments:

=over

=item * die

Bool. Default is true.

If set to 1 (the default) will die if module source code can't be fetched (e.g.
the module does not exist on CPAN, or there is network error). If set to 0, will
simply decline so C<require()> will try the next entry in C<@INC>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Hook-Source-MetaCPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Hook-Source-MetaCPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook-Source-MetaCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Require::Hook::*> modules.

L<Require::HookChain::source::metacpan> uses us.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
