package SyForm::Exception::UnknownErrorOnResultsBuildView;
BEGIN {
  $SyForm::Exception::UnknownErrorOnResultsBuildView::AUTHORITY = 'cpan:GETTY';
}
$SyForm::Exception::UnknownErrorOnResultsBuildView::VERSION = '0.103';
use Moo;
extends 'SyForm::Exception';

with qw(
  SyForm::Exception::Role::WithSyFormResults
  SyForm::Exception::Role::WithOriginalError
);

sub throw_with_args {
  my ( $class, $results, $original_error ) = @_;
  $class->rethrow_syform_exception($original_error);
  $class->throw($class->error_message_text($original_error).' on build of view',
    original_error => $original_error,
    results => $results,
  );
};

1;

__END__

=pod

=head1 NAME

SyForm::Exception::UnknownErrorOnResultsBuildView

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
