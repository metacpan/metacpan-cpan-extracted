package Prosody::Storage::SQL::DB;
BEGIN {
  $Prosody::Storage::SQL::DB::AUTHORITY = 'cpan:GETTY';
}
{
  $Prosody::Storage::SQL::DB::VERSION = '0.007';
}
# ABSTRACT: DBIx::Class::Schema for the prosody database

use Moose;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

1;

__END__
=pod

=head1 NAME

Prosody::Storage::SQL::DB - DBIx::Class::Schema for the prosody database

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

