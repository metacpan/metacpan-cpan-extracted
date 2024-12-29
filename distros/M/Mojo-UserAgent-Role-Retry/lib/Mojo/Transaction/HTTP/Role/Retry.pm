package Mojo::Transaction::HTTP::Role::Retry 0.002;

# ABSTRACT: Adds a retries attribute

use Mojo::Base -role;


has retries => 0;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Transaction::HTTP::Role::Retry - Adds a retries attribute

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Mojo::Base -signatures;

  {
    use Mojolicious::Lite;
    my $ok = 0;
    get '/' => sub ($c) {
      return $ok++ ?
        $c->render(text => 'OK!') :
        $c->render(text => 'Not OK!', status => 429);
    };
  }

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new;
  $ua->get(
    '/' => sub ($ua, $tx) {
      say $tx->retries; # 1
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;

=head1 DESCRIPTION

This role adds a C<retries> attribute to L<Mojo::Transaction::HTTP>.

=head1 ATTRIBUTES

=head2 retries

The number of retries that have been attempted.

=head1 SEE ALSO

L<Mojo::UserAgent::Role::Retry>.

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christian Segundo <ssmn@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
