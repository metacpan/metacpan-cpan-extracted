package Nephia::Plugin::Basic;
use strict;
use warnings;
use parent 'Nephia::Plugin';

sub exports {
    qw/req param redirect/;
}

sub req {
    my ($self, $context) = @_;
    return sub () {$context->{req}};
}

sub param {
    my ($self, $context) = @_;
    return sub (;$) {$_[0] ? $context->{req}->param($_[0]) : $context->{req}->parameters};
}

sub redirect {
    my ($self, $context) = @_;
    return sub ($) {[303, [Location => $_[0]], []]};
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Basic - A Nephia plugin that provides basic DSL

=head1 DESCRIPTION

This plugin provides req and param DSL for Nephia.

=head1 DSL

=head2 req

    app {
        my $req = req; # returns Nephia::Request object
        ...
    };

Returns Nephia::Request object.

=head2 param

    app {
        my $id     = param('id'); # returns query-parameter that named 'id'
        my $params = param;       # returns query-parameters as hashref
    };

Returns query-parameter.

=head2 redirect 

    app {
        redirect '/to/some_path';
    };

Returns response object with Location header.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<Nephia::Plugin>

=cut

