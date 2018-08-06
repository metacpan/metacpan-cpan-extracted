package Pod::Knit;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Stitches together POD documentation
$Pod::Knit::VERSION = '0.0.1';

use 5.20.0;
use warnings;

use Path::Tiny;
use YAML;

use List::Util qw/ reduce /;

use Pod::Knit::Document;

use Moose;

use experimental 'signatures', 'postderef';


has config_file => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub {
        -f 'knit.yml' ? 'knit.yml' : undef;
    },
);


has config => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        YAML::LoadFile($self->config_file);
    },
);


has stash => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->config->{stash} || {}
    },
);


has plugins => (
    traits => [ 'Array' ],
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my @plugins;
        if( my $plugins = $self->config->{plugins} ) {
            for my $p ( @$plugins ) {
                my( $plugin, $args ) = ref $p ? %$p : ( $p );

                $plugin = 'Pod::Knit::Plugin::' . $plugin;

                use Module::Runtime qw/ use_module /;
                use_module( $plugin );

                push @plugins, $plugin->new( 
                    stash => $self->stash,
                    %$args, knit => $self );
            }
        }

        \@plugins;
    },
    handles => {
        all_plugins => 'elements',
    },
);

sub munging_plugins ($self) {
    grep { $_->can( 'munge' ) } $self->all_plugins;
}


sub munge_document($self,@rest) {
    my( $doc ) = ( @rest == 1 ) ? @rest : ( Pod::Knit::Document->new( knit => $self, @rest ) );
    return reduce { $b->munge($a->clone) } $doc, $self->munging_plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit - Stitches together POD documentation

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    my $knit = Pod::Knit->new( config => {
        plugins => [
            'Abstract',
            'Version',
            { Sort => { order => [qw/ NAME * VERSION /] },
        ]
    });
    
    print $knit->munge_document( file => './lib/Pod/Knit.pm' )->as_string;

=head1 DESCRIPTION

C<Pod::Knit> is a POD processor heavily inspired by L<Pod::Weaver>. The
main difference being that C<Pod::Weaver> uses a L<Pod::Elemental> DOM to
represent and transform the POD document, whereas C<Pod::Knit> uses
representation of the document (the tags used in that representation are
given in L<Pod::Knit::Document>).

This module mostly take care of taking in the desired configuration, and
transform POD documents based on it. For documentation of the system as a
whole, peer at L<Pod::Knit::Manual>.

=head1 attributes

=head3 config_file

Configuration file for the knit pipeline. Must be a YAML file.

E.g.:

--- stash: author: Yanick Champoux <yanick@cpan.org> plugins: - Abstract -
Attributes - Methods - NamedSections: sections: - synopsis - description -
Version - Authors - Legal - Sort: order: - NAME - VERSION - SYNOPSIS -
DESCRIPTION - ATTRIBUTES - METHODS - '*' - AUTHORS - AUTHOR - COPYRIGHT AND
LICENSE

=head4 F<./knit.yml> if the file exists.

=head3 config

Hashref of the configuration for the knit pipeline.

The configuration recognizes two keys: C<stash>, which value is a hashref
of configuration elements to pass to the plugins, and C<plugins>, the
arrayref of plugins and (optionally) their arguments. See C<config_file>
for an example.

=head4 the content of the C<config_file>, if it exists.

=head3 stash

Hashref of values accessible to the knit pipeline. Can be used to set
values required by various plugins, like the distribution's version, the
list of authors, etc.

=head4 the C<stash> value of the config attribute, if presents. Else an empty hashref.

=head1 methods

=head3 munge_document

    my $doc = $knit->munge_document( %args )

    my $doc = $knit->munge_document( $original )

Takes a L<Pod::Knit::Document> and returns a new document munged by the
plugins.

If the input is C<%args>, it is a shortcut for

    my $doc = $knit->munge_document( 
        Pod::Knit::Document->new( knit => $knit, %args )
    );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

