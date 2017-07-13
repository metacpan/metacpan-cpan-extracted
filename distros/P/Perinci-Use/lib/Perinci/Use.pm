package Perinci::Use;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use Perinci::Access;
use Perinci::Sub::Util qw(err);

our %SPEC;

$SPEC{use_riap_package} = {
    v => 1.1,
    summary => 'Use a Riap package as if it was a local Perl module',
    result => {
        schema => 'undef',
    },
    description => <<'_',

"Use" a remote code package over Riap protocol as if it was a local Perl module.
Actually, what is being done is query the remote URL for available functions,
and for each remote function, create a proxy function. The proxy function will
then call the remote function.

Currently only functions are imported. Variables and other entities are ignored.

_
    args => {
        url => {
            summary => 'Location of Riap package entity',
            description => <<'_',

Example: '/Foo/Bar/' (local Perl module), 'http://example.com/api/Module/'.

_
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        into => {
            summary     => 'Perl package name to put proxy functions into',
            description => <<'_',

Example: 'Foo::Bar', 'Example::Module'.

_
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        include => {
            summary     => 'Do not load all children, only load specified ones',
            schema => ['array*' => of=>'str*'],
        },
    },
};
sub use_riap_package {
    my %args   = @_;
    log_trace("-> use_riap_package(%s)", \%args);
    my $url    = $args{url}  or return [400, "Please specify url"];
    my $into   = $args{into} or return [400, "Please specify into"];
    return [500, "Invalid module name `$into`"]
        unless $into =~ /\A\w+(::\w+)*\z/;
    my $inc    = $args{include} // [];

    my $pa = Perinci::Access->new;

    # try child_metas first
    my $res = $pa->request(child_metas => $url);
    return err(500, "Can't request action 'child_metas' on URL $url", $res)
        unless $res->[0] == 200 || $res->[0] == 501;

    my @e;
    if ($res->[0] == 200) {
        my $metas = $res->[2];
        for my $u (keys %$metas) {
            my $meta = $metas->{$u};
            next unless $meta->{args};
            my $sub = $u; $sub =~ s!.+/!!;
            push @e, [$sub, $u, $meta];
        }
    } else {
        # try 'list' + later 'meta' for each child
        $res = $pa->request(list => $url, {detail=>1});
        return err(500, "Can't request action 'list' on URL $url", $res)
            unless $res->[0] == 200;
        for my $r (@{$res->[2]}) {
            next unless $r->{type} eq 'function';
            my $sub = $r->{uri}; $sub =~ s!.+/!!;
            push @e, [$sub, $r->{uri}];
        }
    }

    # check all specified entries 'include' must exist
    for my $s (@$inc) {
        return [400, "'$s' does not exist under $url"]
            unless grep {$s eq $_->[0]} @e;
    }

    # create proxy functions
    for my $e (@e) {
        next if @$inc && !($e->[0] ~~ @$inc);

        # get metadata if not yet retrieved
        unless ($e->[2]) {
            $res = $pa->request(meta => $e->[1]);
            return err(500, "Can't request action 'meta' on URL $e->[1]", $res)
                unless $res->[0] == 200;
            $e->[2] = $res->[2];
        }

        # mark metadata
        $e->[2]{_note} = "Imported by ".__PACKAGE__." on ".scalar(localtime);

        # create proxy
        no strict 'refs';
        no warnings;
        *{"$into\::$e->[0]"} = sub {
            my %args = @_;
            $pa->request(call => $e->[1], {args=>\%args});
        };
        ${"$into\::SPEC"}{$e->[0]} = $e->[2];
    }

    log_trace("<- use_riap_package()");
    [200, "OK"];
}

sub import {
    my ($module, $url, @args) = @_;
    my $into = caller;

    die "import: Please specify URL as first argument" unless $url;

    my $into_pm = $into; $into_pm =~ s!::!/!g; $into_pm .= ".pm";
    return if $INC{$into_pm};

    my $res = use_riap_package(url=>$url, into=>$into, include=>\@args);
    die "import: Can't use_riap_package $url: $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    $INC{$into_pm} = $url;

    1;
}

1;
# ABSTRACT: Use a Riap package as if it was a local Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Use - Use a Riap package as if it was a local Perl module

=head1 VERSION

This document describes version 0.07 of Perinci::Use (from Perl distribution Perinci-Use), released on 2017-07-10.

=head1 SYNOPSIS

 # import pyth()
 use Perinci::Use "http://example.com/My/Math", 'pyth';
 print pyth(3, 4); # 5

 # import all
 use Perinci::Use "http://example.com/My/Math";

=head1 DESCRIPTION

This module provides use_riap_package(), usually used as shown in Synopsis, a la
Perl's use().

=head1 FUNCTIONS


=head2 use_riap_package

Usage:

 use_riap_package(%args) -> [status, msg, result, meta]

Use a Riap package as if it was a local Perl module.

"Use" a remote code package over Riap protocol as if it was a local Perl module.
Actually, what is being done is query the remote URL for available functions,
and for each remote function, create a proxy function. The proxy function will
then call the remote function.

Currently only functions are imported. Variables and other entities are ignored.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<include> => I<array[str]>

Do not load all children, only load specified ones.

=item * B<into>* => I<str>

Perl package name to put proxy functions into.

Example: 'Foo::Bar', 'Example::Module'.

=item * B<url>* => I<str>

Location of Riap package entity.

Example: '/Foo/Bar/' (local Perl module), 'http://example.com/api/Module/'.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (undef)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Use>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Use>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Use>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
