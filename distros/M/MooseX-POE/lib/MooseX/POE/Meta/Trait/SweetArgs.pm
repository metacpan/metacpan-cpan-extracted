package MooseX::POE::Meta::Trait::SweetArgs;
{
  $MooseX::POE::Meta::Trait::SweetArgs::VERSION = '0.215';
}
# ABSTRACT: Yes, its a trap... i mean trait

use Moose::Role;

around add_state_method => sub {
  my $orig = shift;
  my ($self, $name, $method) = @_;
  $orig->($self, $name, sub {
    $method->(@_[POE::Session::OBJECT(), POE::Session::ARG0()..$#_])
  });
}; 

no Moose::Role;

1;


=pod

=head1 NAME

MooseX::POE::Meta::Trait::SweetArgs - Yes, its a trap... i mean trait

=head1 VERSION

version 0.215

=head1 SYNOPSIS

use MooseX::POE::Meta::Trait::SweetArgs;

=head1 DESCRIPTION

The MooseX::POE::Meta::Trait::SweetArgs class implements ...

=head1 SUBROUTINES / METHODS

There are no public methods.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Yuval (nothingmuch) Kogman

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Ash Berlin, Chris Williams, Yuval Kogman, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

