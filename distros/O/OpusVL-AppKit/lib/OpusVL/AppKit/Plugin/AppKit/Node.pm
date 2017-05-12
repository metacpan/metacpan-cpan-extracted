package OpusVL::AppKit::Plugin::AppKit::Node;

use Moose;

has node_name       => ( is => 'rw'       , isa => 'Str'                     , required => 1 );

# Controller (if any) linked to this node..
has controller      => ( is => 'rw'       , isa => 'Catalyst::Controller'    );

# Action Path (if any) linked to this node..
has action_path     => ( is => 'rw'       , isa => 'Str'                     );

# Array of roles that can access this node..
has access_only     => ( is => 'rw'       , isa => 'ArrayRef'                );

# Hash of attributes..
has action_attrs    => ( is => 'rw'       , isa => 'HashRef'                 );

has in_feature      => ( is => 'rw', isa => 'Bool', required => 1 );

# maybe for future use?.... currently being delt with in the Base::Controller::GUI...
#   has navigation      => ( is => 'rw'       , isa => 'Int'                     , default  => 0 );
#   has navigation_name => ( is => 'rw'       , isa => 'Str'                     );
#   has home_navigation => ( is => 'rw'       , isa => 'Int'                     , default  => 0 );
#   has portlet         => ( is => 'rw'       , isa => 'Int'                     , default  => 0 );
#   has portlet_name    => ( is => 'rw'       , isa => 'Str'                     );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Plugin::AppKit::Node

=head1 VERSION

version 2.29

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
