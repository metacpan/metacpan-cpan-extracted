package MozRepl::Util;

use strict;
use warnings;

use Data::JavaScript::Anon;
use File::Spec;
use UNIVERSAL::require;
use URI;

=head1 NAME

MozRepl::Util - MozRepl utilities.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 METHODS

=head2 canonical_plugin_name($plugin)

To canonical plugin name

=cut

sub canonical_plugin_name {
    my ($class, $plugin) = @_;

    my ($abs, $canonical_plugin) = ($plugin =~ /^(\+)([^\+]+)/);

    if (!$abs && !$canonical_plugin) {
        $canonical_plugin = "MozRepl::Plugin::" . $plugin;
    }

    return $canonical_plugin;
}

=head2 plugin_to_method($plugin, $search)

To method name from plugin's class name.

=over 4

=item $plugin

Plugin's class name.

=item $search

L<MozRepl/new($args)>'s search argument.

=back

=cut

sub plugin_to_method {
    my ($class, $plugin, $search) = @_;

    if ($plugin->can("method_name") && $plugin->method_name) {
        return $plugin->method_name;
    }

    my $suffix = (grep { $plugin =~ /^$_/x } @{$search})[0];

    my $plugin_name = $plugin;
    $plugin_name =~ s/^${suffix}:://;

    my $method = join("_", map { lc($_) } split(/::/, $plugin_name));

    unless ($suffix eq 'MozRepl::Plugin') {
        $method = join("_", map { lc($_) } split(/::/, $suffix)) . "_$method";
    }

    return $method;
}

=head2 javascript_value($value)

To JavaScript value from string.
See L<Data::JavaScript::Anon>.

=cut

sub javascript_value {
    my ($class, $value) = @_;

    return Data::JavaScript::Anon->anon_dump($value);
}

=head2 javascript_uri($uri)

To uri string for JavaScript.

=cut

sub javascript_uri {
    my ($class, $uri) = @_;

    unless ($uri =~ m|^[a-zA-Z][a-zA-Z0-9.+\-]*:|) {
        return URI::file->new(File::Spce->rel2abs($uri))->as_string;
    }
    else {
        return URI->new($uri)->as_string;
    }
}

=head1 SEE ALSO

=over 4

=item L<Data::JavaScript::Anon>

=item L<URI>, L<URI::file>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-util@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Util
