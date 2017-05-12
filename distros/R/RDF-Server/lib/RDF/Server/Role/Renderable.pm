package RDF::Server::Role::Renderable;

use Moose::Role;

requires 'render';

1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Renderable - role for resources that can be rendered

=head1 SYNOPSIS

 package My::Resource;

 use Moose;

 with 'RDF::Server::Role::Renderable';

 sub to_xml { }

=head1 DESCRIPTION

=head2 Methods

=over 4

=item render ($formatter, $path)

=back

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

