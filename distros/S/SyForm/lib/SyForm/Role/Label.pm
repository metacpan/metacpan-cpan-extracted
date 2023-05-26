package SyForm::Role::Label;
BEGIN {
  $SyForm::Role::Label::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: A label for the form
$SyForm::Role::Label::VERSION = '0.103';
use Moo::Role;

has label => (
  is => 'ro',
  predicate => 1,
);

1;

__END__

=pod

=head1 NAME

SyForm::Role::Label - A label for the form

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
