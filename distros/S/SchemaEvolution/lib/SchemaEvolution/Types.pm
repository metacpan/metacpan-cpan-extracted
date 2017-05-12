package SchemaEvolution::Types;
our $VERSION = '0.03';


use MooseX::Types (-declare => [qw( DBH )]);

class_type DBH, { class => 'DBI::db' };

1;


__END__
=pod

=head1 NAME

SchemaEvolution::Types

=head1 VERSION

version 0.03

=head1 NAME

SchemaEvolution::Types - type constraints used in SchemaEvolution

=head1 VERSION

version 0.03

=head2 DESCRIPTION

Type constraints used through SchemaEvolution

=cut

=head1 AUTHOR

  Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Oliver Charles.

This is free software, licensed under:

  The Artistic License 2.0

=cut

