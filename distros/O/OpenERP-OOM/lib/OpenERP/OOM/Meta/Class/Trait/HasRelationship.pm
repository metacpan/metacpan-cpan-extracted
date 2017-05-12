package OpenERP::OOM::Meta::Class::Trait::HasRelationship;
use Moose::Role;


has relationship => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub {{}},
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Meta::Class::Trait::HasRelationship

=head1 VERSION

version 0.44

=head1 DESCRIPTION

A trait used internally for managing the relationships

=head1 NAME

OpenERP::OOM::Meta::Class::Trait::HasRelationship

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
