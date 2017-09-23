package Mojo::IOLoop::ReadWriteProcess::Exception;
use Mojo::Base -base;

sub new {
  my $class = shift;
  my $value = @_ == 1 ? $_[0] : "";
  return bless \$value, ref $class || $class;
}

sub to_string { "${$_[0]}" }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Exception - Exception object for Mojo::IOLoop::ReadWriteProcess.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::Exception;

    my $e = Mojo::IOLoop::ReadWriteProcess::Exception->new("Errored!");

    print "Error $e";

    my $string_error = $e->to_string;

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Exception> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 to_string

    my $e = Mojo::IOLoop::ReadWriteProcess::Exception->new("Errored!");
    my $string_error = $e->to_string;

Returns stringified version of the error message.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
