package Mojo::Cloudflare::RecordSet;

=head1 NAME

Mojo::Cloudflare::RecordSet - A set of Mojo::Cloudflare::Record objects

=head1 DESCRIPTION

L<Mojo::Cloudflare::RecordSet> holds a list of L<Mojo::Cloudflare::Record>
objects.

=cut

use Mojo::Base 'Mojo::JSON::Pointer';

# Will be public once I know what to call the attribute
has _cf => sub { Mojo::Cloudflare->new };

=head1 METHODS

=head2 all

  @records = $self->all;

Returns a list of L<Mojo::Cloudflare::Record> objects.

=cut

sub all {
  my $self = shift;

  return @{
    $self->{all} ||= [
      map {
        my $obj = Mojo::Cloudflare::Record->new($_);
        Scalar::Util::weaken($obj->_cf($self->_cf)->{_cf});
        $obj;
      } @{$self->get('/objs') || []}
    ]
  };
}

=head2 single

  $record = $self->single(sub { $_->name =~ /^foo/ });

Used find a single record from L</all>. C<undef> is returned
if no records match.

NOTE! This will only return the first record found.

=cut

sub single {
  my ($self, $filter) = @_;

  for ($self->all) {
    next unless $self->$filter;
    return $_;
  }

  return undef;
}

sub _new_from_tx {
  my ($class, $tx) = @_;
  my $err = $tx->error;
  my $json = $tx->res->json || {};

  $json->{result} //= '';
  $err ||= $json->{msg} || $json->{result} || 'Unknown error.' if $json->{result} ne 'success';

  return $err, $class->new($json->{response}{recs} || {});
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
