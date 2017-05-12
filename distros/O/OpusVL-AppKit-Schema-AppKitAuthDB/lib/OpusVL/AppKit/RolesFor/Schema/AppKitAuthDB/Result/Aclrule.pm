package OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Aclrule;

use strict;
use Moose::Role;

sub setup_authdb
{
    my $class = shift;
    $class->many_to_many( roles => 'aclrule_roles', 'role');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Aclrule

=head1 VERSION

version 6

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
