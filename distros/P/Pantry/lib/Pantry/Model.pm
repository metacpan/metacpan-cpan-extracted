use v5.14;
use warnings;

package Pantry::Model;
# ABSTRACT: Pantry data model class framework
our $VERSION = '0.012'; # VERSION

1;

__END__

=pod

=head1 NAME

Pantry::Model - Pantry data model class framework

=head1 VERSION

version 0.012

=head1 DESCRIPTION

The C<Pantry::Model::*> classes provide a data model and API for managing files
in a 'pantry' directory.  These classes describe in abstract terms the
information needed to manage servers with the
L<chef-solo|http://wiki.opscode.com/display/chef/Chef+Solo> configuration management
tool.

The classes include:

=over 4

=item *

L<Pantry::Model::Pantry> -- models the 'pantry' directory and its contents

=item *

L<Pantry::Model::Node> -- models configuration data for a 'node', including a

C<run_list> of recipes/roles and associated configuration attributes

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
