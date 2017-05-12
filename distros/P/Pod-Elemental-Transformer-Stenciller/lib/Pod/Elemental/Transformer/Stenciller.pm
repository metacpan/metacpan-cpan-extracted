use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Stenciller;

our $VERSION = '0.0300'; # VERSION:
# ABSTRACT: Injects content from textfiles transformed with Stenciller

use Moose;
use MooseX::AttributeDocumented;
with qw/Pod::Elemental::Transformer Stenciller::Utils/;

use namespace::autoclean;
use Types::Standard -types;
use Types::Path::Tiny qw/Dir/;
use Types::Stenciller qw/Stenciller/;
use Carp qw/carp croak/;
use Module::Load qw/load/;
use Path::Tiny;
use Stenciller;

has directory => (
    is => 'ro',
    isa => Dir,
    coerce => 1,
    required => 1,
    documentation => 'Path to directory where the stencil files are.'
);
has settings => (
    is => 'ro',
    isa => HashRef,
    traits => ['Hash'],
    default => sub { +{} },
    handles => {
        get_setting => 'get',
        set_setting => 'set',
        all_settings => 'elements',
    },
    documentation_default => '{ }',
    documentation_order => 0,
    documentation => 'If a plugin takes more attributes..',
);
has plugins => (
    is => 'ro',
    isa => HashRef,
    default => sub { +{} },
    documentation_default => '{ }',
    documentation_order => 0,
    init_arg => undef,
    traits => ['Hash'],
    handles => {
        get_plugin => 'get',
        set_plugin => 'set',
    },
    documentation_order => 0,
);
has stencillers => (
    is => 'ro',
    isa => HashRef,
    traits => ['Hash'],
    init_arg => undef,
    handles => {
        get_stenciller_for_filename => 'get',
        set_stenciller_for_filename => 'set',
    },
    documentation_order => 0,
);

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;
    my @args = @_;

    my $args = ref $args[0] eq 'HASH' ? $args[0] : { @args };

    $class->$next(
        directory => delete $args->{'directory'},
        settings  => $args
    );
};

sub transform_node {
    my $self = shift;
    my $main_node = shift;

    NODE:
    foreach my $node (@{ $main_node->children }) {
        my $content = $node->content;
        my $start = substr($content, 0, 11, '');
        next NODE if $start ne ':stenciller';

        $content =~ s{^\h+}{};             # remove leading whitespace
        next if $content !~ m{([^\h\v]+)}; # the next sequence of non-space is the wanted plugin name

        my $wanted_plugin = $1;
        my $plugin_name = $self->ensure_plugin($wanted_plugin);

        (undef, my($filename, $possible_hash)) = split /\h+/ => $content, 3;
        chomp $filename;
        my $node_settings = defined $possible_hash && $possible_hash =~ m{\{.*\}} ? $self->eval_to_hashref($possible_hash, $filename) : {};

        my $stenciller = $self->get_stenciller_for_filename($filename);

        if(!Stenciller->check($stenciller)) {
            $stenciller = Stenciller::->new(filepath => path($self->directory)->child($filename));
            if(!$stenciller->has_stencils) {
                carp sprintf '! no stencils in %s/%s - skipping', $self->directory, $filename;
                return;
            }

            $self->set_stenciller_for_filename($filename => $stenciller);
        }

        my $transformed_content = $stenciller->transform(plugin_name => $plugin_name,
                                                         constructor_args => $self->settings,
                                                         transform_args => { %$node_settings, require_in_extra => { key => 'to_pod', value => 1, default => 1 } },
                                                        );
        $transformed_content =~ s{[\v\h]+$}{};
        $node->content($transformed_content);

    }
}
sub ensure_plugin {
    my $self = shift;
    my $plugin_name = shift;

    return $self->get_plugin($plugin_name) if $self->get_plugin($plugin_name);

    my $plugin_class = sprintf 'Stenciller::Plugin::%s', $plugin_name;
    load($plugin_class);

    if(!$plugin_class->does('Stenciller::Transformer')) {
        croak("[$plugin_name] doesn't do the Stenciller::Transformer role. Quitting.");
    }
    $self->set_plugin($plugin_name => $plugin_name);
    return $plugin_name;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Stenciller - Injects content from textfiles transformed with Stenciller



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.14+-brightgreen.svg" alt="Requires Perl 5.14+" /> <a href="https://travis-ci.org/Csson/p5-Pod-Elemental-Transformer-Stenciller"><img src="https://api.travis-ci.org/Csson/p5-Pod-Elemental-Transformer-Stenciller.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-88.6%-orange.svg" alt="coverage 88.6%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.14+](https://img.shields.io/badge/perl-5.14+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Pod-Elemental-Transformer-Stenciller.svg?branch=master)](https://travis-ci.org/Csson/p5-Pod-Elemental-Transformer-Stenciller) ![coverage 88.6%](https://img.shields.io/badge/coverage-88.6%-orange.svg)

=end markdown

=head1 VERSION

Version 0.0300, released 2016-02-02.



=head1 SYNOPSIS

    # in weaver.ini
    [-Transformer / Stenciller]
    transformer = Stenciller
    directory = path/to/stencildir

=head1 DESCRIPTION

This transformer uses a special command in pod files to inject content from elsewhere via a L<Stenciller> transformer plugin.

=head2 Example

1. Start with the C<weaver.ini> from the L</"synopsis">.

2. Add a textfile, in C<path/to/stencildir/file-with-stencils.stencil>:

    == stencil { to_pod => 1 } ==

    Header text

    --input--

        Input text

    --end input--

    Between text

    --output--

        Output text

    --end output--

    Footer text

3. Add a Perl module:

    package A::Test::Module;

    1;

    __END__

    =pod

    =head1 NAME

    =head1 DESCRIPTION

    :stenciller ToUnparsedText file-with-stencils.stencil

The last line in the Perl module will result in the following:

=over 4

=item *

The textfile is parsed with L<Stenciller>

=item *

The textfile is then transformed using the L<Stenciller::Plugin::ToUnparsedText> plugin.

=item *

The ':stenciller ...' line in the pod is replaced with the transformed content.

=back

=head2 Pod hash

It is possible to filter stencils by index with an optional hash in the pod:

    :stenciller ToUnparsedText 1-test.stencil { stencils => [0, 2..4] }

This will only include the stencils with index 0, 2, 3 and 4 from C<file-with-stencils.stencil>.

=head2 Stencil hash

This module checks for the C<to_pod> key in the stencil hash. If it has a true value (or doesn't exist) it is included in the transformation.

However, any stencil excluded by the L</"Pod hash"> is already disregarded. It is probably least confusing to choose B<one> of these places to do all filtering.

=head1 ATTRIBUTES


=head2 directory

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Dir">Dir</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to directory where the stencil files are.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Dir">Dir</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to directory where the stencil files are.</p>

=end markdown

=head1 SEE ALSO

=over 4

=item *

L<Stenciller>

=item *

L<Stenciller::Plugin::ToUnparsedText>

=item *

L<Pod::Weaver>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Elemental-Transformer-Stenciller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Elemental-Transformer-Stenciller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
