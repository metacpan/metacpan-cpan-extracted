package Plack::Middleware::HTMLLint::Pluggable;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.03';

use parent qw/ Plack::Middleware::HTMLLint /;

use HTML::Lint::Pluggable;
use Plack::Util::Accessor qw/plugins/;

sub prepare_app {
    my $self = shift;
    $self->SUPER::prepare_app;
    unless ($self->plugins) {
        $self->plugins(+{});
    }
}

sub html_lint {
    my($self, $syntax, $content) = @_;

    my $lint = HTML::Lint::Pluggable->new;
    my $plugins = $self->plugins->{$syntax};
    $lint->load_plugins(@$plugins) if $plugins;

    $lint->parse($content);
    $lint->eof;

    return $lint->errors;
}

1;
__END__

=head1 NAME

Plack::Middleware::HTMLLint::Pluggable - check syntax with HTML::Lint::Pluggable for PSGI application's response HTML

=head1 VERSION

This document describes Plack::Middleware::HTMLLint::Pluggable version 0.03.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'HTMLLint::Pluggable', plugins => +{
            html5 => [qw/HTML5/],
        };
        sub {
            my $env = shift;
            # ...
            return [
                200,
                ['Content-Type' => 'text/plain'],
                ['<!DOCTYPE html><html><head>...']
            ];
        };
    };

=head1 DESCRIPTION

This module check syntax with HTML::Lint::Pluggable for PSGI application's response HTML.
to assist you to discover the HTML syntax errors during the development of Web applications.

You can control the plug-in to load, depending on the type of response. (like as SYNOPSYS)

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Middleware::HTMLLint> L<HTML::Lint> L<HTML::Lint::Pluggable>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
