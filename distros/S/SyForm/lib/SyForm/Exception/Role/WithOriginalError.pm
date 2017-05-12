package SyForm::Exception::Role::WithOriginalError;
BEGIN {
  $SyForm::Exception::Role::WithOriginalError::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Role for exceptions with a non SyForm error
$SyForm::Exception::Role::WithOriginalError::VERSION = '0.102';
use Moo::Role;

has original_error => (
  is => 'ro',
  required => 1,
);

sub rethrow_syform_exception {
  my ( $class, $error ) = @_;
  die $error if $error->isa('SyForm::Exception');
}

sub error_message_text {
  my ( $class, $error ) = @_;
  my $error_type = $error->isa('Moose::Exception')
    ? 'Moose exception' : 'Unknown error';
}

around throw => sub {
  my ( $orig, $class, $message, %args ) = @_;
  $message .= "\n".'[Original Error] '.$args{original_error};
  return $class->$orig($message, %args);
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::Role::WithOriginalError - Role for exceptions with a non SyForm error

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
