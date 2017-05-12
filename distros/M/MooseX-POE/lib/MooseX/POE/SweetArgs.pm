package MooseX::POE::SweetArgs;
{
  $MooseX::POE::SweetArgs::VERSION = '0.215';
}
# ABSTRACT: sugar around MooseX::POE event arguments

use Moose ();
use MooseX::POE;
use Moose::Exporter;


Moose::Exporter->setup_import_methods(
    also        => 'MooseX::POE',
);

sub init_meta {
    my ($class, %args) = @_;
    MooseX::POE->import({ into => $args{for_class} });

    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            class => ['MooseX::POE::Meta::Trait::SweetArgs'],
        },
    );
}


1;


=pod

=head1 NAME

MooseX::POE::SweetArgs - sugar around MooseX::POE event arguments

=head1 VERSION

version 0.215

=head1 SYNOPSIS

  package Thing;
  use MooseX::POE::SweetArgs;

  # declare events like usual
  event on_success => sub {
    # unpack args like a Perl sub, not a POE event
    my ($self, $foo, $bar) = @_;
    ...
    POE::Kernel->yield('foo');
    ...
  };

=head1 DESCRIPTION

Normally, when using MooseX::POE, subs declared as events need to use POE
macros for unpacking C<@_>, e.g.:

  my ($self, $foo, $bar) = @_[OBJECT, ARG0..$#_];

Using MooseX::POE::SweetArgs as a metaclass lets you avoid this, and just use
C<@_> as normal:

  my ($self, $foo, $bar) = @_;

Since the POE kernel is a singleton, you can access it using class methods, as
shown in the synopsis.

In all other respects, this behaves exactly like MooseX::POE

=for :list * L<MooseX::POE|MooseX::POE>

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

