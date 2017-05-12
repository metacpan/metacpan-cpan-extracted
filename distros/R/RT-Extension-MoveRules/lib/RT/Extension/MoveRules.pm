use 5.008003;
use strict;
use warnings;

package RT::Extension::MoveRules;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::MoveRules - control ticket movements between queues

=head1 DESCRIPTION

If you move tickets between queues a lot then probably you want
to control this process. This extension allows you to configure
rules which are required to move a ticket from a queue to another
queue, for example if custom field X is equal to Y then a ticket
can be moved from queue A to B. As well you can define which
fields should be set before move.

=head1 INSTALLATION

This extension works with RT 3.8 and depends on
L<RT::Condition::Complex>. Otherwise installation process is
usuall:

    perl Makefile.PL
    make
    make install

=head1 CONFIGURATION

Extension is controlled with one config option C<@MoveRules>
with the following syntax:

    Set( @MoveRules,
        {
            From       => 'queue',
            To         => 'queue',
            Rule       => 'a rule',
            Condition  => 'a rule',
            ShowAction => 1/0,

        },
        ...
    );

=head2 From and To

These keys define queues either by name or id. Both are
mandatory options. Example:

    Set( @MoveRules,
        { From => 'X', To => 'Y' },
    );

Such configuration allows users to move tickets from queue
"X" to "Y", but not any other move.

=head2 ShowAction

Boolean option that controls whether action for this move is
displayed in the action menu (Open, Take) or not. By default
no actions are displayed.

=head2 Rule

Rule is a condition defining additional limits on the move.
This is a string with syntax implemented by
L<RT::Condition::Complex> and L<RT::Extension::ColumnMap>.
Syntax is close to TicketSQL, slightly different, some
examples:

    Rule => 'Subject = "good" AND Status = "open"',

=head2 Condition

Condition is very similar to L</Rule>. The difference
is that users can not see a condition until they try
to move a ticket.

Moving limits between condition is up to you, but
probably condition is better to leave with checks
if a field is empty or not. For example:

    Condition => 'CustomField{"X"} is not empty',

=cut

$RT::Config::META{'MoveRules'} = {
    Type => 'ARRAY',
};


{ my $cache;
sub Config {
    my $self = shift;
    unless ( $cache ) {
        $cache = {};
        foreach my $rule ( RT->Config->Get('MoveRules') ) {
            $cache->{ lc $rule->{'From'} }{ lc $rule->{'To'} }
                = { %$rule };
        }
    }
    return $cache unless @_;

    my %args = @_;
    return $cache->{ lc $args{'From'}->Name }{lc $args{'To'}->Name};
} }

use RT::Condition::Complex;


sub Check {
    my $self = shift;
    my %args = (
        From => undef, To => undef,
        Ticket => undef,
        @_
    );
    my ($status, $msg);
    ($status, $msg) = $self->CheckPossibility( %args );
    return ($status, $msg) unless $status;
    ($status, $msg) = $self->CheckRule( %args );
    return ($status, $msg) unless $status;
    ($status, $msg) = $self->CheckCondition( %args );
    return ($status, $msg) unless $status;
    return 1;
}

sub CheckPossibility {
    my $self = shift;
    my %args = (@_);
    return 1 if $args{'From'}->id == $args{'To'}->id;

    my $config = $self->Config( %args );
    return 1 if $config;
    return (0, $args{'Ticket'}->loc('Ticket move to that queue is not allowed'));
}

sub CheckRule {
    my $self = shift;
    my %args = (@_);
    return 1 if $args{'From'}->id == $args{'To'}->id;

    my $config = $self->Config( %args );
    die "CheckPossibility first" unless $config;

    return $self->CheckConditionString(
        %args, String => $config->{'Rule'}
    );
}

sub CheckCondition {
    my $self = shift;
    my %args = (@_);
    return 1 if $args{'From'}->id == $args{'To'}->id;

    my $config = $self->Config( %args );
    die "CheckPossibility first" unless $config;

    return $self->CheckConditionString(
        %args, String => $config->{'Condition'}
    );
}

sub CheckConditionString {
    my $self = shift;
    my %args = (@_);

    return 1 unless defined $args{'String'} && length $args{'String'};

    my $cond = RT::Condition::Complex->new(
        TicketObj      => $args{'Ticket'},
        TransactionObj => $args{'Transaction'},
        CurrentUser    => $RT::SystemUser,
    );
    my ($res, $tree, $desc) = $cond->Solve(
        $args{'String'},
        '' => $args{'Ticket'},
        From => $args{'From'},
        To => $args{'To'},
    );
    return (0, $args{'Ticket'}->loc('Ticket can not be moved until the following rules are met: [_1]', $desc))
        unless $res;
    return 1;
}

sub Possible {
    my $self = shift;
    my %args = @_;
    $args{'Queue'} = $args{'Ticket'}->QueueObj
        if !$args{'Queue'} && $args{'Ticket'};

    my $config = $self->Config->{ lc $args{'Queue'}->Name } || {};

    my @res;
    push @res, $args{'Queue'}->Name unless $args{'SkipThis'};
    push @res,
        map $_->{'To'},
        grep { $args{'WithAction'} && !$_->{'ShowAction'}? 0 : 1 }
        values %$config;
    return sort @res;
}

use RT::Ticket;
package RT::Ticket;

{
    my $old_sub = \&RT::Ticket::SetQueue;
    no warnings 'redefine';
    *RT::Ticket::SetQueue = sub {
        my $self = shift;
        return $old_sub->( $self, @_ ) unless $self->Type eq 'ticket';

        my $new_id = shift;

        # we have to duplicate some code

        my $new = RT::Queue->new( $self->CurrentUser );
        $new->Load( $new_id );
        unless ( $new->id ) {
            return (0, $self->loc("That queue does not exist"));
        }

        my $old = $self->QueueObj;
        if ( $old->id == $new->id ) {
            return ( 0, $self->loc('That is the same value') );
        }

        my ($status, $msg) = RT::Extension::MoveRules->Check(
            From => $old, To => $new,
            Ticket => $self,
        );
        return ($status, $msg) unless $status;

        return $old_sub->( $self, $new_id, @_ );
    }
}

=head1 LICENSE

Under the same terms as perl itself.

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=cut

1;
