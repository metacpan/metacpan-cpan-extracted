package OpenERP::OOM::Meta::Class::Trait::HasLink;
use Moose::Role;

=head1 NAME

OpenERP::OOM::Meta::Class::Trait::HasLink

=head1 DESCRIPTION

A trait used internally for managing the links

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

has link => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub {{}},
);

1;
