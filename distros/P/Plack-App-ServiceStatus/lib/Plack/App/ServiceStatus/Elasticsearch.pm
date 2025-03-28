package Plack::App::ServiceStatus::Elasticsearch;

# ABSTRACT: Check Elasticsearch connection

our $VERSION = '0.913'; # VERSION

use 5.018;
use strict;
use warnings;

sub check {
    my ( $class, $es ) = @_;

    my $rv = $es->ping;
    return 'ok' if $rv == 1;
    return 'nok', "got: $rv";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::ServiceStatus::Elasticsearch - Check Elasticsearch connection

=head1 VERSION

version 0.913

=head1 SYNOPSIS

  my $es         = Search::Elasticsearch->new;
  my $status_app = Plack::App::ServiceStatus->new(
      app           => 'your app',
      Elasticsearch => $es,
  );

=head1 CHECK

Calls C<ping> on the C<$elasticsearch> object.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
