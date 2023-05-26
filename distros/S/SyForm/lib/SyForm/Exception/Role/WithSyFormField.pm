package SyForm::Exception::Role::WithSyFormField;
BEGIN {
  $SyForm::Exception::Role::WithSyFormField::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Role for exceptions with a SyForm field as reference
$SyForm::Exception::Role::WithSyFormField::VERSION = '0.103';
use Moo::Role;

has field => (
  is => 'ro',
  required => 1,
  handles => [qw(
    syform
  )],
);

1;

__END__

=pod

=head1 NAME

SyForm::Exception::Role::WithSyFormField - Role for exceptions with a SyForm field as reference

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
