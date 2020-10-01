package ScriptX::ModifyPlugin;

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

sub meta {
    return {
        summary => 'Modify the loading (activation) of another plugin',
        conf => {
            plugin => {
                summary => 'Plugin name to be modified',
                schema => 'str*',
                req => 1,
            },
            delete_args => {
                summary => 'List of arguments to delete',
                schema => ['array*', of=>'str*'],
            },
            add_or_modify_args => {
                summary => 'List of arguments to add or modify',
                schema => ['hash*'],
            },
            add_args => {
                summary => 'List of arguments to add (if they were not specified)',
                schema => ['hash*'],
            },
            modify_args => {
                summary => 'List of arguments to modify (if they were specified)',
                schema => ['hash*'],
            },
        },
    };
}

sub before_activate_plugin {
    my ($self, $stash) = @_;

    return [204, "Decline"] unless $stash->{plugin_name} eq $self->{plugin};
    my $args = $stash->{plugin_args};
    if ($self->{add_or_modify_args}) {
        for (keys %{ $self->{add_or_modify_args} }) {
            $args->{$_} = $self->{add_or_modify_args}{$_};
        }
    }
    if ($self->{add_args}) {
        for (keys %{ $self->{add_args} }) {
            $args->{$_} = $self->{add_args}{$_} unless exists $args->{$_};
        }
    }
    if ($self->{modify_args}) {
        for (keys %{ $self->{modify_args} }) {
            $args->{$_} = $self->{modify_args}{$_} if exists $args->{$_};
        }
    }
    if ($self->{delete_args}) {
        for (@{ $self->{delete_args} }) {
            delete $args->{$_};
        }
    }
    [200, "OK"];
}

1;
# ABSTRACT: Modify the loading (activation) of another plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::ModifyPlugin - Modify the loading (activation) of another plugin

=head1 VERSION

This document describes version 0.000004 of ScriptX::ModifyPlugin (from Perl distribution ScriptX), released on 2020-10-01.

=head1 SYNOPSIS

 use ScriptX ModifyPlugin => {
     plugin => 'Getopt::Long',
     add_or_modify_args => {
         abort_on_failure => 0,
     },
 };

=head1 DESCRIPTION

This plugin can modify the loading of other plugins, e.g. the arguments passed
to plugin constructor.

=head1 SCRIPTX PLUGIN CONFIGURATION

=head2 add_args

Hash. Optional. List of arguments to add (if they were not specified).

=head2 add_or_modify_args

Hash. Optional. List of arguments to add or modify.

=head2 delete_args

Array. Optional. List of arguments to delete.

=head2 modify_args

Hash. Optional. List of arguments to modify (if they were specified).

=head2 plugin

Str. Required. Plugin name to be modified.

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
