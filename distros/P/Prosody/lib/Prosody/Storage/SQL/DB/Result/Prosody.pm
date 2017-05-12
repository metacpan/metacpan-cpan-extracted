package Prosody::Storage::SQL::DB::Result::Prosody;
BEGIN {
  $Prosody::Storage::SQL::DB::Result::Prosody::AUTHORITY = 'cpan:GETTY';
}
{
  $Prosody::Storage::SQL::DB::Result::Prosody::VERSION = '0.007';
}
# ABSTRACT: Result class for the prosody table

use DBIx::Class::Candy;
use Moose;

table 'prosody';

column host => {
	data_type => 'text',
	is_nullable => 1,
};

column user => {
	data_type => 'text',
	is_nullable => 1,
};

column store => {
	data_type => 'text',
	is_nullable => 1,
};

column key => {
	data_type => 'text',
	is_nullable => 1,
};

column type => {
	data_type => 'text',
	is_nullable => 1,
};

column value => {
	data_type => 'text',
	is_nullable => 1,
};

1;

__END__
=pod

=head1 NAME

Prosody::Storage::SQL::DB::Result::Prosody - Result class for the prosody table

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

