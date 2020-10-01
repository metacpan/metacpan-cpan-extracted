## no critic: ControlStructures::ProhibitUnreachableCode

package ScriptX::Exit;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-01'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000004'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

use parent 'ScriptX_Base';
require ScriptX;

sub meta {
    return {
        summary => 'exit() early',
        conf => {
            before => {
                summary => 'Exit before the first handler of this event',
                schema => ['str*'],
            },
            after => {
                summary => 'Exit after the last handler of this event',
                schema => ['str*'],
            },
            exit_code => {
                summary => 'Exit code',
                schema => ['uint*'],
                default => 0,
            },
        },
        conf_rels => {
            req_one => [qw/before after/],
        },
    };
}

sub new {
    my ($class, %args) = (shift, @_);
    $args{before} || $args{after} or die "Please specify before or after";
    $args{exit_code} ||= 0;
    $class->SUPER::new(%args);
}

sub activate {
    my $self = shift;

    if ($self->{before}) {
        ScriptX::add_handler(
            $self->{before},
            'Exit',
            0,
            sub {
                exit($self->{exit_code});
                [200, "OK"]; # should be unreached
            },
        );
    }
    if ($self->{after}) {
        ScriptX::add_handler(
            $self->{after},
            'Exit',
            100,
            sub {
                exit($self->{exit_code});
                [200, "OK"]; # should be unreached
            },
        );
    }
}

1;
# ABSTRACT: exit() early

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Exit - exit() early

=head1 VERSION

This document describes version 0.000004 of ScriptX::Exit (from Perl distribution ScriptX), released on 2020-10-01.

=head1 SYNOPSIS

 use ScriptX Exit => {after => 'get_args']};

=head1 DESCRIPTION

=head1 SCRIPTX PLUGIN CONFIGURATION

=head2 after

Str. Optional. Exit after the last handler of this event.

=head2 before

Str. Optional. Exit before the first handler of this event.

=head2 exit_code

Uint. Optional. Exit code.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
