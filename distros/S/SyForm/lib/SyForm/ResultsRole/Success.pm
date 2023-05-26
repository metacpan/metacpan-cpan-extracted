package SyForm::ResultsRole::Success;
BEGIN {
  $SyForm::ResultsRole::Success::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: A bool for holding the success of the form process
$SyForm::ResultsRole::Success::VERSION = '0.103';
use Moo::Role;

use overload 'bool' => sub { $_[0]->success };

has success => (
  is => 'ro',
  required => 1,
);

1;

__END__

=pod

=head1 NAME

SyForm::ResultsRole::Success - A bool for holding the success of the form process

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
