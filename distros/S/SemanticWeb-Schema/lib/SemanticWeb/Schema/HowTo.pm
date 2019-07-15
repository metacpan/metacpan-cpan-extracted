use utf8;

package SemanticWeb::Schema::HowTo;

# ABSTRACT: Instructions that explain how to achieve a result by performing a sequence of steps.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'HowTo';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has estimated_cost => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'estimatedCost',
);



has perform_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'performTime',
);



has prep_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'prepTime',
);



has step => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'step',
);



has steps => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'steps',
);



has supply => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'supply',
);



has tool => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'tool',
);



has total_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'totalTime',
);



has yield => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'yield',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowTo - Instructions that explain how to achieve a result by performing a sequence of steps.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Instructions that explain how to achieve a result by performing a sequence
of steps.

=head1 ATTRIBUTES

=head2 C<estimated_cost>

C<estimatedCost>

The estimated cost of the supply or supplies consumed when performing
instructions.

A estimated_cost should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Str>

=back

=head2 C<perform_time>

C<performTime>

=for html The length of time it takes to perform instructions or a direction (not
including time to prepare the supplies), in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration format</a>.

A perform_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<prep_time>

C<prepTime>

=for html The length of time it takes to prepare the items to be used in instructions
or a direction, in <a href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601
duration format</a>.

A prep_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<step>

A single step item (as HowToStep, text, document, video, etc.) or a
HowToSection.

A step should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::HowToSection']>

=item C<InstanceOf['SemanticWeb::Schema::HowToStep']>

=item C<Str>

=back

=head2 C<steps>

A single step item (as HowToStep, text, document, video, etc.) or a
HowToSection (originally misnamed 'steps'; 'step' is preferred).

A steps should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<Str>

=back

=head2 C<supply>

A sub-property of instrument. A supply consumed when performing
instructions or a direction.

A supply should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HowToSupply']>

=item C<Str>

=back

=head2 C<tool>

A sub property of instrument. An object used (but not consumed) when
performing instructions or a direction.

A tool should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HowToTool']>

=item C<Str>

=back

=head2 C<total_time>

C<totalTime>

=for html The total time required to perform instructions or a direction (including
time to prepare the supplies), in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration format</a>.

A total_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<yield>

The quantity that results by performing instructions. For example, a paper
airplane, 10 personalized candles.

A yield should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
