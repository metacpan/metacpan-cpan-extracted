package Template::Plugin::HTML::Prototype;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Template::Plugin';

use HTML::Prototype;

sub new($$@) {
	my ($prot, $context, @params) = @_;
	return new HTML::Prototype(@params);
}

1;
__END__

=head1 NAME

Template::Plugin::HTML::Prototype - Template Toolkit Plugin for the Prototype Library

=head1 SYNOPSIS

In a Template:

    [% USE proto = HTML::Prototype %]

    [% proto.define_javascript_functions %]
    [% proto.form_remote_tag(...) %]
    [% proto.link_to_function(...) %]
    [% proto.link_to_remote(...) %]
    [% proto.observe_field(...) %]
    [% proto.observe_form(...) %]
    [% proto.periodically_call_remote(...) %]
    [% proto.submit_to_remote(...) %]

=head1 DESCRIPTION

This module provides a simple interface to the Prototype JavaScript OO library for use in the Template Toolkit. 

It directly returns a L<HTML::Prototype> object, so you can call all methods there.

=head1 SEE ALSO

L<HTML::Prototype>, L<Template>

L<http://prototype.conio.net>

=head1 AUTHOR

Bernhard Bauer, E<lt>bauerb@in.tum.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Bernhard Bauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
