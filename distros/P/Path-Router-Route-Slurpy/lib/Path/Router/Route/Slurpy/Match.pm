package Path::Router::Route::Slurpy::Match;
{
  $Path::Router::Route::Slurpy::Match::VERSION = '0.141330';
}
use Moose;

extends 'Path::Router::Route::Match';

# ABSTRACT: Matching with slurpy paths


__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Path::Router::Route::Slurpy::Match - Matching with slurpy paths

=head1 VERSION

version 0.141330

=head1 DESCRIPTION

This actually does nothing special.

=head1 EXTENDS

L<Path::Router::Route::Match>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
