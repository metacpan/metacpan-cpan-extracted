package OpenERP::OOM::Link;

use Moose;

has 'schema' => (
    is => 'ro',
);

has 'config' => (
    isa => 'HashRef',
    is  => 'ro',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Link

=head1 VERSION

version 0.44

=head1 DESCRIPTION

Base class for the link classes used to span OpenERP data and data in other
systems.  See OpenERP::OOM::Object for more information about the links that
can be setup between two data sources with the has_link property.  

=head1 NAME

OpenERP::OOM::Link

=head1 PROPERTIES

=head2 config

This property is usually used to store the configuration for the database connection
for the link.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
