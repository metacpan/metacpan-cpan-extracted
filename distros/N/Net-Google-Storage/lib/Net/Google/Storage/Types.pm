package Net::Google::Storage::Types;
$Net::Google::Storage::Types::VERSION = '0.2.0';
# ABSTRACT: Types library for L<Net::Google::Storage>. Pretty boring really.

use Moose::Util::TypeConstraints;

subtype 'Net::Google::Storage::Types::BucketLocation', as 'Str';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::Storage::Types - Types library for L<Net::Google::Storage>. Pretty boring really.

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
