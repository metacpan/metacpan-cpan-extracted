package Pod::Weaver::Section::Consumes;
{
  $Pod::Weaver::Section::Consumes::VERSION = '0.010';
}

# ABSTRACT: Add a list of roles to your POD.

use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

sub weave_section {
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};

    #consumes section is written only for lib/*.pm and for one package pro file
    #see Pod::Weaver::Section::ClassMopper for an alternative
    return if $filename !~ m{^lib};
    return if $filename !~ m{\.pm$};

    my $module = $filename;
    $module =~ s{^lib/}{};
    $module =~ s{/}{::}g;
    $module =~ s{\.pm$}{};

    #print "module:$module\n";
    if ( !Class::Inspector->loaded($module) ) {
        eval { local @INC = ( 'lib', @INC ); Module::Load::load $module };
        print "$@" if $@;    #warn
    }

    return unless $module->can('meta');
    my @roles = sort
      grep { $_ ne $module } $self->_get_roles($module);

    return unless @roles;

    my @pod = (
        Command->new(
            {
                command => 'over',
                content => 4
            }
        ),

        (
            map {
                Command->new(
                    {
                        command => 'item',
                        content => "* L<$_>",
                    }
                  ),
            } @roles
        ),

        Command->new(
            {
                command => 'back',
                content => ''
            }
        )
    );

    push @{ $doc->children },
      Nested->new(
        {
            type     => 'command',
            command  => 'head1',
            content  => 'CONSUMES',
            children => \@pod
        }
      );

}

sub _get_roles {
    my ( $self, $module ) = @_;
    my @roles = map { $_->name } eval { $module->meta->calculate_all_roles };
    print "Possibly harmless: $@" if $@;

    #print "@roles\n";
    return @roles;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Pod::Weaver::Section::Consumes - Add a list of roles to your POD.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

In your C<weaver.ini>:

    [Consumes]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "CONSUMES" section in your POD
which contains a list of the roles consumed by your class. It accomplishes this 
by loading all classes and interrogating their metaclass.

All classes (*.pm files) in your distribution's lib directory will be loaded.
Classes which do not have a C<meta> method will be skipped. POD is changed only
for files which actually consume roles. 

=head1 CAVEAT

In case you use L<Dist::Zilla> to install dependencies of your distribution,
you might encounter a quirk caused by this plugin. If you run C<dzil listdeps>, 
dzil will load this module which in turn will load all classes in lib which in 
turn may want to load classes which are not yet installed. Currently, there 
seems to be no easy way around this with L<Dist::Zilla> alone. But there are 
workarounds. You could, for example, eliminate weaver.ini during the 
installation process:

    #temporarily remove weaver.ini during install
    cpanm Pod::Weaver::Section::Consumes
    mv weaver.ini _weaver.ini
    dzil authordeps | cpanm
    dzil listdeps | cpanm
    mv _weaver.ini weaver.ini

Or install dependencies before you run listdeps, for example by adding them
as authordeps to dist.ini.

    #dist.ini 
    #authordep JSON = 2.57

=head1 SEE ALSO

L<Pod::Weaver::Section::Extends> 

=cut

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
