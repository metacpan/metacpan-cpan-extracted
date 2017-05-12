package SyForm::Exception::UnknownErrorOnCreateValuesByArgs;
BEGIN {
  $SyForm::Exception::UnknownErrorOnCreateValuesByArgs::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Exception on SyForm::Process->create_values_by_args
$SyForm::Exception::UnknownErrorOnCreateValuesByArgs::VERSION = '0.102';
use Moo;
extends 'SyForm::Exception';

with qw(
  SyForm::Exception::Role::WithSyForm
  SyForm::Exception::Role::WithOriginalError
);

has args => (
  is => 'ro',
  required => 1,
);

sub throw_with_args {
  my ( $class, $syform, $args, $original_error ) = @_;
  $class->rethrow_syform_exception($original_error);
  $class->throw($class->error_message_text($original_error).' on create_values_by_args',
    syform => $syform,
    original_error => $original_error,
    args => $args,
  );
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::UnknownErrorOnCreateValuesByArgs - Exception on SyForm::Process->create_values_by_args

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
