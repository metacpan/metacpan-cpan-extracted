package MouseX::POE;
# ABSTRACT: The Illicit Love Child of Mouse and POE
$MouseX::POE::VERSION = '0.216';
use Mouse ();
use Mouse::Exporter;
use Mouse::Util::MetaRole;
use Mouse::Util;
use MouseX::POE::Meta::Trait::Class;

Mouse::Exporter->setup_import_methods(
    as_is           => [qw(event)],
    also            => 'Mouse',
);

sub init_meta {
    my ( $class, %args ) = @_;

    my $for = $args{for_class};
    eval qq{package $for; use POE; };

    my $meta = Mouse->init_meta( %args );

    Mouse::Util::MetaRole::apply_metaroles(
      for     => $args{for_class},
      class_metaroles => {
        class       => ['MouseX::POE::Meta::Trait::Class'],
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

MouseX::POE - The Illicit Love Child of Mouse and POE

=head1 VERSION

version 0.216

=head1 SYNOPSIS

    package Counter;
    use MouseX::POE;

    has count => (
        isa     => 'Int',
        is      => 'rw',
        lazy    => 1,
        default => sub { 0 },
    );

    sub START {
        my ($self) = @_;
        $self->yield('increment');
    }

    event increment => sub {
        my ($self) = @_;
        print "Count is now " . $self->count . "\n";
        $self->count( $self->count + 1 );
        $self->yield('increment') unless $self->count > 3;
    };

    no MouseX::POE;

    Counter->new();
    POE::Kernel->run();

=head1 DESCRIPTION

MouseX::POE is a L<Mouse> wrapper around a L<POE::Session>.

=head1 METHODS

Default POE-related methods are provided by L<MouseX::POE::Meta::Trait::Object|MouseX::POE::Meta::Trait::Object>
which is applied to your base class (which is usually L<Mouse::Object|Mouse::Object>) when
you use this module. See that module for the documentation for it. Below is a list
of methods on that class so you know what to look for:

=head2 event $name $subref

Create an event handler named $name.

=head2 get_session_id

Get the internal POE Session ID, this is useful to hand to other POE aware
functions.

=head2 yield

=head2 call

=head2 delay

=head2 alarm

=head2 alarm_add

=head2 delay_add

=head2 alarm_set

=head2 alarm_adjust

=head2 alarm_remove

=head2 alarm_remove_all

=head2 delay_set

=head2 delay_adjust

A cheap alias for the same POE::Kernel function which will gurantee posting to the object's session.

=head2 STARTALL

=head2 STOPALL

=for Pod::Coverage   init_meta

=head1 KEYWORDS

=head1 SEE ALSO

=for :list * L<Mouse|Mouse>
* L<POE|POE>

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
