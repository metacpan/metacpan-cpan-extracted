#
# This file is part of Template-Plugin-Map
#
# This software is copyright (c) 2017 by Michael Schout <mschout@cpan.org>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Template::Plugin::Map;
$Template::Plugin::Map::VERSION = '0.03';
# ABSTRACT: map VMethod for Template::Tookit

use strict;
use warnings;
use base 'Template::Plugin::VMethods';

our @LIST_OPS = (map => \&map_list);

sub map_list {
    my ($list, $method) = @_;

    [map { $_->$method } @$list];
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Map - map VMethod for Template::Tookit

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  [% USE Map %]
  [% list.map('method').join(', ') %]

=head1 DESCRIPTION

This module is a Template Tooklit plugin that provides a C<map> VMethod.  This
just provides a way to map a method call to a list of objects.

=for Pod::Coverage map_list

=head1 SEE ALSO

L<Template>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/template-plugin-map>
and may be cloned from L<git://github.com/mschout/template-plugin-map.git>

=head1 BUGS

Please report any bugs or feature requests to bug-template-plugin-map@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Map

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout <mschout@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
