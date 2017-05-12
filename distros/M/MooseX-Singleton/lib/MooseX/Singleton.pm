package MooseX::Singleton; # git description: 0.25-37-g820a8b5

use Moose 1.10 ();
use Moose::Exporter;
use MooseX::Singleton::Role::Object;
use MooseX::Singleton::Role::Meta::Class;
use MooseX::Singleton::Role::Meta::Instance;

our $VERSION = '0.30';

Moose::Exporter->setup_import_methods( also => 'Moose' );

sub init_meta {
    shift;
    my %p = @_;

    Moose->init_meta(%p);

    my $caller = $p{for_class};

    Moose::Util::MetaRole::apply_metaroles(
        for             => $caller,
        class_metaroles => {
            class => ['MooseX::Singleton::Role::Meta::Class'],
            instance =>
                ['MooseX::Singleton::Role::Meta::Instance'],
            constructor =>
                ['MooseX::Singleton::Role::Meta::Method::Constructor'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $caller,
        roles =>
            ['MooseX::Singleton::Role::Object'],
    );

    return $caller->meta();
}


1;

# ABSTRACT: Turn your Moose class into a singleton

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Singleton - Turn your Moose class into a singleton

=head1 VERSION

version 0.30

=head1 SYNOPSIS

    package MyApp;
    use MooseX::Singleton;

    has env => (
        is      => 'rw',
        isa     => 'HashRef[Str]',
        default => sub { \%ENV },
    );

    package main;

    delete MyApp->env->{PATH};
    my $instance = MyApp->instance;
    my $same = MyApp->instance;

=head1 DESCRIPTION

A singleton is a class that has only one instance in an application.
C<MooseX::Singleton> lets you easily upgrade (or downgrade, as it were) your
L<Moose> class to a singleton.

All you should need to do to transform your class is to change C<use Moose> to
C<use MooseX::Singleton>. This module uses metaclass roles to do its magic, so
it should cooperate with most other C<MooseX> modules.

=head1 METHODS

A singleton class will have the following additional methods:

=head2 Singleton->instance

This returns the singleton instance for the given package. This method does
I<not> accept any arguments. If the instance does not yet exist, it is created
with its defaults values. This means that if your singleton requires
arguments, calling C<instance> will die if the object has not already been
initialized.

=head2 Singleton->initialize(%args)

This method can be called I<only once per class>. It explicitly initializes
the singleton object with the given arguments.

=head2 Singleton->_clear_instance

This clears the existing singleton instance for the class. Obviously, this is
meant for use only inside the class itself.

=head2 Singleton->new

This method currently works like a hybrid of C<initialize> and
C<instance>. However, calling C<new> directly will probably be deprecated in a
future release. Instead, call C<initialize> or C<instance> as appropriate.

=for Pod::Coverage init_meta

=head1 SOME CODE STOLEN FROM

=for stopwords Anders

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 AND PATCHES FROM

Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Singleton>
(or L<bug-MooseX-Singleton@rt.cpan.org|mailto:bug-MooseX-Singleton@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Karen Etheridge Ricardo SIGNES Kaare Rasmussen Anders Nor Berle Jonathan Rockway Hans Dieter Pearcey

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Kaare Rasmussen <kaare@jasonic.dk>

=item *

Anders Nor Berle <berle@cpan.org>

=item *

Jonathan Rockway <jon@jrock.us>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
