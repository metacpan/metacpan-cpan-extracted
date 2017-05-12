package SyForm::Role::Bootstrap;
BEGIN {
  $SyForm::Role::Bootstrap::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: SyForm::ViewRole::Bootstrap configuration of the form
$SyForm::Role::Bootstrap::VERSION = '0.102';
use Moo::Role;

has bootstrap => (
  is => 'ro',
  predicate => 1,
);

1;

__END__

=pod

=head1 NAME

SyForm::Role::Bootstrap - SyForm::ViewRole::Bootstrap configuration of the form

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
