package Net::HTTP::Spore::Meta::Class;
$Net::HTTP::Spore::Meta::Class::VERSION = '0.07';
# ABSTRACT: metaclass for all API client

use Moose::Role;

with qw/Net::HTTP::Spore::Meta::Method::Spore/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Meta::Class - metaclass for all API client

=head1 VERSION

version 0.07

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
