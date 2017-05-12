# ============================================================================
package MooseX::App::Message::Envelope;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

use MooseX::App::Message::Block;

use overload
    '""' => "overload";

has 'blocks' => (
    is          => 'ro',
    isa         => 'ArrayRef[MooseX::App::Message::Block]',
    traits      => ['Array'],
    handles     => {
        add_block       => 'push',
        list_blocks     => 'elements',
    },
);

has 'exitcode' => (
    is          => 'ro',
    isa         => 'Int',
    predicate   => 'has_exitcode',
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my @args = @_;

    my $params;
    if (scalar @args == 1
        && ref($args[0]) eq 'HASH') {
        $params = $args[0];
    } else {
        $params = {
            blocks  => [],
        };
        my @blocks;
        foreach my $element (@args) {
            next
                unless defined $element;
            if (blessed $element
                && $element->isa('MooseX::App::Message::Block')) {
                push(@{$params->{blocks}},$element);
            } elsif ($element =~ /^\d+$/
                && $element <= 255
                && $element >= 0) {
                $params->{exitcode} = $element;
            } else {
                push(@{$params->{blocks}},MooseX::App::Message::Block->new(
                    header  => $element,
                ));
            }
        }
    }

    return $self->$orig($params);
};

sub overload {
    my ($self) = @_;

    if ($self->has_exitcode) {
        my $exitcode = $self->exitcode;
        if ($exitcode == 0) {
            print $self->stringify;
        } else {
            print STDERR $self->stringify;
        }
        exit $exitcode;
    } else {
        print $self->stringify;
    }
    return;
}

sub stringify {
    my ($self) = @_;

    my $message = '';
    foreach my $block ($self->list_blocks) {
        $message .= $block->stringify;
    }

    return $message;
}

sub AUTOLOAD {
    my ($self) = @_;
    $self->overload;
    return $MooseX::App::Null::NULL;
}

{
    package MooseX::App::Null;

    use strict;
    use warnings;

    use overload
      'bool'   => sub { 0 },
      '""'     => sub { '' },
      '0+'     => sub { 0 };
    our $NULL = bless {}, __PACKAGE__;
    sub AUTOLOAD { return $NULL }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Message::Envelope - Message presented to the user

=head1 DESCRIPTION

Whenever MooseX::App needs to pass a message to the user, it does so by
generating a MooseX::App::Message::Envelope object. The object usually
contains one or more blocks (L<MooseX::App::Message::Block>) and can be
easily stringified.

Usually a MooseX::App::Message::Envelope object is generated and returned
by the L<new_with_command method in MooseX::App::Base|MooseX::App::Base/new_with_command>
if there is an error or if the user requests help.

To avoid useless object type checks when working with this method,
MooseX::App::Message::Envelope follows the Null-class pattern. So you can do
this, no matter if new_with_command fails or not:

 MyApp->new_with_command->some_method->only_called_if_successful;

If

=head1 METHODS

=head2 stringify

Stringifies the messages

=head2 overload

This method is called whenever the object is stringified via overload. In this
case it prints the message on either STDERR or STDOUT, and exits the process
with the given exitcode (if any).

=head2 add_block

Adds a new message block. Param must be a L<MooseX::App::Message::Block>

=head2 list_blocks

Returns a list on message blocks.

=head2 blocks

Message block accessor.

=head2 exitcode

Exitcode accessor.

=head2 has_exitcode

Check if exitcode is set.

=head2 OVERLOAD

Stringification of this object is overloaded.

=head2 AUTOLOAD

You can call any method on the message class.
