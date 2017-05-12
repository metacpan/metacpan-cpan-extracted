package SyForm::Exception::Role::WithSyFormResults;
BEGIN {
  $SyForm::Exception::Role::WithSyFormResults::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Role for exceptions with a SyForm::Results
$SyForm::Exception::Role::WithSyFormResults::VERSION = '0.102';
use Moo::Role;

has results => (
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

SyForm::Exception::Role::WithSyFormResults - Role for exceptions with a SyForm::Results

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
