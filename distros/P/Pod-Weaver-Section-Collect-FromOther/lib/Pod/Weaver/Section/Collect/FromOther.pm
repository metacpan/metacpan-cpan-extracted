#
# This file is part of Pod-Weaver-Section-Collect-FromOther
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Section::Collect::FromOther;
{
  $Pod::Weaver::Section::Collect::FromOther::VERSION = '0.002';
}

# ABSTRACT: Import sections from other POD

use Moose;
use namespace::autoclean;

use Moose::Autobox;

use Path::Class;

use PPI;
use Pod::Elemental::Selectors -all;
use Pod::Elemental;
use Pod::Elemental::Document;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Transformer::Gatherer;
use Pod::Elemental::Transformer::List::Converter;

use Pod::Weaver::Plugin::EnsurePod5;
use Pod::Weaver::Section::Collect;

# debugging...
#use Smart::Comments '###';

with
    'Pod::Weaver::Role::Preparer',
    ;

has command => (is => 'ro', isa => 'Str', default => 'from_other', required => 1);

has header => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => sub { shift->plugin_name },
);


sub prepare_input {
    my ($self, $input) = @_;

    my $our_doc = $input->{pod_document};

    ### our command: $self->command
    my $selector = s_command($self->command);
    return unless $our_doc->children->grep($selector)->length;

    # find our commands
    my @elts;
    $our_doc->children->each_value(sub {

        do { push @elts, $_; return }
            unless $_->does('Pod::Elemental::Command') && $_->command eq $self->command;

        # run against other file and stash
        my ($module, $header_text, $command) = split / \/ /, $_->content;
        my @other_nodes = $self->copy_sections_from_other($module, $header_text, $command);

        ### @other_nodes
        ### @elts
        push @elts, @other_nodes; #$self->copy_sections_from_other($module, $header_text, $command);
    });

    $our_doc->children( [ @elts ] );

    ### $our_doc
    return;
}

sub _find_module {
    my ($self, $module) = @_;

    my @module_as_fn = split /::/, $module . '.pm';

    ### looking for: $module
    for my $dir (map { dir $_ } @INC) {

        my $fn = file $dir, @module_as_fn;
        return $fn if $fn->stat;
    }

    # XXX native logging?
    die "Cannot find $module in \@INC?!";
}


sub copy_sections_from_other {
    my ($self, $module, $header_text, $command) = @_;

    ### find our remote nodes to copy...
    my $selector = s_command('head1');
    my $fn = $self->_find_module($module);

    ### $fn
    my $other_doc = Pod::Elemental->read_file($fn);
    Pod::Elemental::Transformer::Pod5->new->transform_node($other_doc);

    my $list_transform = Pod::Elemental::Transformer::List::Converter->new;
    my $nester = Pod::Elemental::Transformer::Nester->new({
         top_selector      =>  s_command('head1'),
         content_selectors => [
             s_command([ qw(head2 head3 head4 over item back) ]),
             s_flat,
         ],
    });

    my $container = Pod::Elemental::Element::Nested->new({
        command => 'head1',
        content => $self->header,
    });

    ### attack \$other_doc!...
    my @newbies;
    my $found_command = ($command || q{}) eq 'all' ? 1 : 0;

    $list_transform->transform_node($other_doc);
    $nester->transform_node($other_doc);
    $other_doc->children->each_value(sub {

        return unless $_->content eq $header_text;

        my @children = @{ $_->children };

        for my $child (@children) {

            # XXX we likely want to make this optional
            do { $found_command++ } if $child->does('Pod::Elemental::Command');
            next unless $found_command;
            push @newbies, $child;
        }
    });

    ### @newbies
    return (scalar @newbies ? (@newbies) : ());
}

__PACKAGE__->meta->make_immutable;

!!42;



=pod

=encoding utf-8

=head1 NAME

Pod::Weaver::Section::Collect::FromOther - Import sections from other POD

=head1 VERSION

This document describes 0.002 of Pod::Weaver::Section::Collect::FromOther - released February 28, 2012 as part of Pod-Weaver-Section-Collect-FromOther.

=head1 DESCRIPTION

Copy chunks of POD from other documents, and incorporate them.  Our purpose
here is to enable the easy documentation of packages that serve to combine
parts of preexisting packages (and thus preexisting documentation).

=head1 METHODS

=head2 prepare_input($input)

Check the given C<$input> for any commands that would trigger us, and
extract/insert pod as requested.

=head2 copy_sections_from_other($module, $header_text, $opts)

Loads the POD from C<$module> (specified as a package name, in our
C<@INC>), looks for a C<=head1> section with C<$header_text>, and copies
everything pulls it out until the next C<=head1> section.

We return the elements we find from the first command until the next section;
this is to enable preface text to be skipped.  This behaviour can be altered
by setting C<$opts> to 'all';

We return a series of elements suitable for inclusion directly into another
document. Note that if this set includes a list, that list will be converted,
with each C<=item> command becoming a C<=head2>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::Section::Collect>

=item *

L<L<Reindeer> uses this package to collect documentation from various sources.|L<Reindeer> uses this package to collect documentation from various sources.>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/pod-weaver-section-collect-fromother>
and may be cloned from L<git://github.com/RsrchBoy/pod-weaver-section-collect-fromother.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/pod-weaver-section-collect-fromother/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

