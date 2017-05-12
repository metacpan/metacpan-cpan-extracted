package MooseX::Singleton::Role::Object;
use Moose::Role;
use Carp qw( confess );

our $VERSION = '0.30';

sub instance { shift->new }

sub initialize {
    my ( $class, @args ) = @_;

    my $existing = $class->meta->existing_singleton;
    confess "Singleton is already initialized" if $existing;

    return $class->new(@args);
}

override new => sub {
    my ( $class, @args ) = @_;

    my $existing = $class->meta->existing_singleton;
    confess "Singleton is already initialized" if $existing and @args;

    # Otherwise BUILD will be called repeatedly on the existing instance.
    # -- rjbs, 2008-02-03
    return $existing if $existing and !@args;

    return super();
};

sub _clear_instance {
    my ($class) = @_;
    $class->meta->clear_singleton;
}

no Moose::Role;

1;

# ABSTRACT: Object class role for MooseX::Singleton

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Singleton::Role::Object - Object class role for MooseX::Singleton

=head1 VERSION

version 0.30

=head1 DESCRIPTION

=for Pod::Coverage *EVERYTHING*

This just adds C<instance> as a shortcut for C<new>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Singleton>
(or L<bug-MooseX-Singleton@rt.cpan.org|mailto:bug-MooseX-Singleton@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
