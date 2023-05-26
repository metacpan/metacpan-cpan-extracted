package SyForm::Exception::OddNumberOfArgsOnCreateValuesByArgs;
BEGIN {
  $SyForm::Exception::OddNumberOfArgsOnCreateValuesByArgs::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Exception on SyForm::Process->create_values_by_args
$SyForm::Exception::OddNumberOfArgsOnCreateValuesByArgs::VERSION = '0.103';
use Moo;
extends 'SyForm::Exception';

with qw(
  SyForm::Exception::Role::WithSyForm
);

has process_args => (
  is => 'ro',
  required => 1,
);

sub throw_with_args {
  my ( $class, $syform, $process_args, $error ) = @_;
  $class->rethrow_syform_exception($error);
  $class->throw('Odd number of elements on args of create_values_by_args',
    syform => $syform,
    process_args => $process_args,
  );
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::OddNumberOfArgsOnCreateValuesByArgs - Exception on SyForm::Process->create_values_by_args

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
