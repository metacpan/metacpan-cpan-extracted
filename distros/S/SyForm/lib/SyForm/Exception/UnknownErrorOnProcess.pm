package SyForm::Exception::UnknownErrorOnProcess;
BEGIN {
  $SyForm::Exception::UnknownErrorOnProcess::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Exception on SyForm::Process->process
$SyForm::Exception::UnknownErrorOnProcess::VERSION = '0.102';
use Moo;
extends 'SyForm::Exception';

with qw(
  SyForm::Exception::Role::WithSyForm
  SyForm::Exception::Role::WithOriginalError
);

has process_args => (
  is => 'ro',
  required => 1,
);

sub throw_with_args {
  my ( $class, $syform, $process_args, $error ) = @_;
  $class->rethrow_syform_exception($error);
  $class->throw($class->error_message_text($error).' on process',
    syform => $syform,
    original_error => $error,
    process_args => $process_args,
  );
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::UnknownErrorOnProcess - Exception on SyForm::Process->process

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
