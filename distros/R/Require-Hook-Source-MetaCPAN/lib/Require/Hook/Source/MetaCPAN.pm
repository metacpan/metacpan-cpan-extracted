package Require::Hook::Source::MetaCPAN;

use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-15'; # DATE
our $DIST = 'Require-Hook-Source-MetaCPAN'; # DIST
our $VERSION = '0.003'; # VERSION

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
        return undef; ## no critic: TestingAndDebugging::ProhibitExplicitReturnUndef
    };

    $resp->{content} =~ m!href="(.+?\?raw=1)"! or do {
        die "Can't load $filename: Can't find source URL in $url" if $self->{die};
        return undef; ## no critic: TestingAndDebugging::ProhibitExplicitReturnUndef
    };

    $url = URI::URL->new($1, $url)->abs . "";
    log_trace "[RH:Source::MetaCPAN] Retrieving module source for $filename from $url ...";
    $resp = HTTP::Tiny->new->get($url);
    $resp->{success} or do {
        die "Can't load $filename: Can't retrieve $url: $resp->{status} - $resp->{reason}" if $self->{die};
        return undef; ## no critic: TestingAndDebugging::ProhibitExplicitReturnUndef
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

This document describes version 0.003 of Require::Hook::Source::MetaCPAN (from Perl distribution Require-Hook-Source-MetaCPAN), released on 2022-11-15.

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

=head1 SEE ALSO

Other C<Require::Hook::*> modules.

L<Require::HookChain::source::metacpan> is a L<Require::HookChain> version and
it uses us.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook-Source-MetaCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
