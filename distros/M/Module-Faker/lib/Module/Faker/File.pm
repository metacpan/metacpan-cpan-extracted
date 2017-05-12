package Module::Faker::File;
# ABSTRACT: a fake file in a fake dist
$Module::Faker::File::VERSION = '0.017';
use Moose;
with 'Module::Faker::Appendix';

has filename => (is => 'ro', isa => 'Str', required => 1);
has content  => (is => 'ro', isa => 'Str', required => 1);

sub as_string { shift->content }

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::File - a fake file in a fake dist

=head1 VERSION

version 0.017

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
