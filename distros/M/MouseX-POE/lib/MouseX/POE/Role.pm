package MouseX::POE::Role;
$MouseX::POE::Role::VERSION = '0.216';
# ABSTRACT: Eventful roles
use MouseX::POE::Meta::Role;

use Mouse::Exporter;
use Mouse::Util::MetaRole;
use Mouse::Role;

Mouse::Exporter->setup_import_methods(
    as_is           => [qw(event)],
    also            => 'Mouse::Role',
);

sub init_meta {
    my ( $class, %args ) = @_;

    my $for = $args{for_class};
    eval qq{package $for; use POE; };

    my $meta = Mouse->init_meta( %args );

    Mouse::Util::MetaRole::apply_metaroles(
      for     => $args{for_class},
      role_metaroles => {
        role => ['MouseX::POE::Meta::Role','MouseX::POE::Meta::Trait'],
      },
    );

    Mouse::Util::MetaRole::apply_base_class_roles(
      for_class => $args{for_class},
      roles => ['MouseX::POE::Meta::Trait::Object','MouseX::POE::Meta::Trait','MouseX::POE::Meta::Trait::Class'],
    );

    return $meta;
}

sub event {
    my $class = Mouse::Meta::Class->initialize( scalar caller );
    $class->add_state_method( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MouseX::POE::Role - Eventful roles

=head1 VERSION

version 0.216

=head1 SYNOPSIS

    package Counter;
    use MouseX::POE::Role;

    ...

    package RealCounter;

    with qw(Counter);

=head1 DESCRIPTION

This is what L<MouseX::POE> is to Mouse but with L<Mouse::Role>.

=head1 METHODS

=head2 event $name $subref

Create an event handler named $name.

=for Pod::Coverage   init_meta

=head1 KEYWORDS

=for :list * L<MouseX::POE|MouseX::POE>
* L<Mouse::Role>

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
