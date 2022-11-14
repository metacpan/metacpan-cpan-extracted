package Protocol::FIX::MessageInstance;

use strict;
use warnings;

our $VERSION = '0.07';    ## VERSION

=head1 NAME

Protocol::FIX::MessageInstance - handy accessor for deserialized FIX message

=cut

=head1 METHODS

=head3 new

    new($class, $message, $tags_accessor)

Creates new Message Instance (performed by Parser)

=cut

sub new {
    my ($class, $message, $tags_accessor) = @_;
    my $obj = {
        name          => $message->{name},
        category      => $message->{category},
        tags_accessor => $tags_accessor,
    };
    return bless $obj, $class;
}

=head3 value

    value($self, $name)

Tiny wrapper of tag-accessors for direcly accessed message fileds.

If C<$name> refers to field, then it returns field value.

If C<$name> refers to component, it returns L<TagAccessor>,
where C<value> method can me invoked, i.e.

  $mi->value('Component')->value('Field')

If C<$name> refers to (repetitive) group, then it returns
array of L<TagAccessor>s, i.e.

  $mi->value('Group')->[0]->value('Field')

If field/component/group are not found in stream, or
are not direclty available in message definition, C<undef>
will be returned.

=cut

sub value {
    return shift->{tags_accessor}->value(shift);
}

=head3 name

    name($self, $name)

Returns message name, e.g. C<LogOn>

=cut

sub name { return shift->{name} }

=head3 category

    category($self, $name)

Returns message category, e.g. C<app> or C<admin>

=cut

sub category { return shift->{category} }

1;
