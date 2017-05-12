package Pod::Weaver::Section::Extends;
{
  $Pod::Weaver::Section::Extends::VERSION = '0.009';
}

use strict;
use warnings;
use lib './lib';

# ABSTRACT: Add a list of parent classes to your POD.

use Moose;
use Module::Load;
with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

sub weave_section { 
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};
    return unless $filename =~ m{^lib/};

    # works only if one package pro file
    my $inc_filename = $filename;         #as in %INC's keys
    $inc_filename =~ s{^lib/}{};          # assume modules live under lib
    my $module = $inc_filename;
    $module =~ s{/}{::}g;
    $module =~ s{\.\w+$}{};

    eval { load $inc_filename };
    print $@ if $@;

    my @parents = $self->_get_parents( $module );        

    return unless @parents;

    my @pod = (
        Command->new( { 
            command   => 'over',
            content   => 4
        } ),

        ( map { 
            Command->new( {
                command    => 'item',
                content    => sprintf '* L<%s>', $_
            } ),
        } @parents ),
        Command->new( { 
            command   => 'back',
            content   => ''
        } )
    );        

    push @{ $doc->children },
        Nested->new( { 
            type      => 'command',
            command   => 'head1',
            content   => 'EXTENDS',
            children  => \@pod
        } );

}

sub _get_parents { 
    my ( $self, $module ) = @_;

    no strict 'refs';
    return @{ $module . '::ISA' };
}


1;

__END__

=pod

=head1 NAME

Pod::Weaver::Section::Extends - Add a list of parent classes to your POD.

=head1 VERSION

version 0.009

=head1 SYNOPSIS

In your C<weaver.ini>:

    [Extends]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates an "EXTENDS" section in your POD
which will contain a list of your class's parent classes. It accomplishes
this by attempting to compile your class and inspecting its C<@ISA>. 

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
