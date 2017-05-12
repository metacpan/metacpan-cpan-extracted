package MooseX::POE::Role;
{
  $MooseX::POE::Role::VERSION = '0.215';
}
# ABSTRACT: Eventful roles
use MooseX::POE::Meta::Role;

use Moose::Exporter;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->setup_import_methods(
    with_caller    => [qw(event)],
    also           => 'Moose::Role',
    install        => [qw(import unimport)],
    role_metaroles => {
        role => ['MooseX::POE::Meta::Role'],
    },
);

sub init_meta {
    my ( $class, %args ) = @_;

    my $for = $args{for_class};
    eval qq{package $for; use POE; };

    Moose::Role->init_meta( for_class => $for );

    goto $init_meta;
}

sub event {
    my ( $caller, $name, $method ) = @_;
    my $class = Moose::Meta::Class->initialize($caller);
    $class->add_state_method( $name => $method );
}


1;


=pod

=head1 NAME

MooseX::POE::Role - Eventful roles

=head1 VERSION

version 0.215

=head1 SYNOPSIS

    package Counter;
    use MooseX::POE::Role;

    ...

    package RealCounter;

    with qw(Counter);

=head1 DESCRIPTION

This is what L<MooseX::POE> is to Moose but with L<Moose::Role>.

=head1 METHODS

=head2 event $name $subref

Create an event handler named $name. 

=head1 KEYWORDS

=for :list * L<MooseX::POE|MooseX::POE>
* L<Moose::Role> 

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

