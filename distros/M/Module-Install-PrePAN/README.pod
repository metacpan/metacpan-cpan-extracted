package Module::Install::PrePAN;
use 5.008001;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.05';

use base qw(Module::Install::Base);

my %SCHEMA = (
    module_url => 1,
    author_url => 1,
);

sub prepan {
    my ($self, %args) = @_;
    my @invalid_keys = grep { !$SCHEMA{$_} } keys %args;
    Carp::croak "invalid keys: " . join ', ', @invalid_keys if @invalid_keys;
    $self->resources(
        X_prepan_author => $args{author_url},
        X_prepan_module => $args{module_url},
    );
}

!!1;

__END__

=encoding utf8

=head1 NAME

Module::Install::PrePAN - Designate resources at PrePAN related to a
module

=head1 SYNOPSIS

  # Makefile.PL
  prepan module_url => 'http://prepan.org/module/3Yz7PYrBJG',
         author_url => 'http://prepan.org/user/3XR97nG2Gi';

=head1 DESCRIPTION

Module::Install::PrePAN is a Module::Install extension to designate
some resources at PrePAN, social reviewing site for Perl modules
(L<http://prepan.org/>).

=head1 METHODS

=head2 prepan ( I<%args> )

Adds resources at PrePAN passed in as C<%args> under
$meta.resources.X_prepan_{author,module}.

CPAN META Spec version 1.4 specifies that unofficial keys under
$meta.resource must include at least one upper-case letter but version
2 doesn't. Besides, ver.2 formalized all custom keys not listed in the
official spec use "x_" or "X_". See L<CPAN::Meta::Spec> and
L<CPAN::Meta::History> for details.

This module uses the key "X_prepan_*" because of that.

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=over 4

=item * L<Module::Install>

=item * PrePAN

L<http://prepan.org/>

=back

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
