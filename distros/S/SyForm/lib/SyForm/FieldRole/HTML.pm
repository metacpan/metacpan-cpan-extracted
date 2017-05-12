package SyForm::FieldRole::HTML;
BEGIN {
  $SyForm::FieldRole::HTML::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: SyForm::ViewFieldRole::HTML configuration of the field
$SyForm::FieldRole::HTML::VERSION = '0.102';
use Moo::Role;

has input => (
  is => 'ro',
  predicate => 1,
);

has html_label => (
  is => 'ro',
  predicate => 1,
);

1;

__END__

=pod

=head1 NAME

SyForm::FieldRole::HTML - SyForm::ViewFieldRole::HTML configuration of the field

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
