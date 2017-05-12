package SyForm::Exception::UnknownArgOnCreateValuesByArgs;
BEGIN {
  $SyForm::Exception::UnknownArgOnCreateValuesByArgs::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Unknown arg on SyForm::Process->create_values_by_args
$SyForm::Exception::UnknownArgOnCreateValuesByArgs::VERSION = '0.102';
use Moo;
extends 'SyForm::Exception';

with qw(
  SyForm::Exception::Role::WithSyForm
);

has arg => (
  is => 'ro',
  required => 1,
);

sub throw_with_args {
  my ( $class, $syform, $arg ) = @_;
  my $ref = ref $arg;
  $class->throw('Unknown arg of ref "'.$ref.'" on create_values_by_args',
    syform => $syform,
    arg => $arg,
  );
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::UnknownArgOnCreateValuesByArgs - Unknown arg on SyForm::Process->create_values_by_args

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
