package RTx::WorkflowBuilder;
use base 'Class::Accessor::Fast';
use strict;
use warnings;
__PACKAGE__->mk_accessors(qw(stages rule));

our $VERSION = '1.02';

=head1 NAME

RTx::WorkflowBuilder - helper for configuring approval workflow in RT

=head1 SYNOPSIS

# see rt-workflow

=cut

sub get_stage_object {
    my ($self, $stage, $previous, $approving) = @_;
    if (ref $stage eq 'ARRAY') {
        my @result;
        my @chain = @$stage;
        for (0..$#chain) {
            push @result,
                $self->get_stage_object($chain[$_],
                                        $_ ? $chain[$_-1] : undef,
                                        $_ == $#chain ? $approving : undef,
                                    );
        }
        return \@result;
    }
    elsif (ref $stage) {
        die "invalid argument $stage";
    }
    else {
        die "Stage $stage not defined" unless exists $self->stages->{$stage};
        return RTx::WorkflowBuilder::Stage->new( { name => $stage,
                                                   depends_on => $previous,
                                                   depended_on_by => $approving,
                                                   %{ $self->stages->{$stage} } });
    }
}

sub compile_template {
    my $self = shift;
    my $stages = $self->get_stage_object($self->rule, undef, 'TOP');
    return join('', map { $_->compile_template(@_) }
                    map { ref $_ eq 'ARRAY' ? @$_ : $_ } @$stages )."\n"; # flatten with map
}

package RTx::WorkflowBuilder::Stage;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(name owner content depends_on depended_on_by subject));

sub compile_template {
    my $self = shift;
    my $attributes = { Queue => '___Approvals',
                       Type => 'approval',
                       Owner => $self->owner,
                       Requestors => '{$Approving->Requestors}',
                       Subject => $self->subject || 'Approval for ticket {$Approving->Id}: {$Approving->Subject}',
                       'Refers-To' => 'TOP',
                       Due => '{time + 86400}', # XXX: configurable
                       'Content-Type' => 'text/plain',
                       @_,
                       $self->depends_on ? (
                           'Depends-On' => "workflow-".$self->depends_on,
                       ) : (),
                       $self->depended_on_by ? (
                           'Depended-On-By' => $self->depended_on_by,
                       ) : (),
                   };

    if (ref $attributes->{Cc} eq 'ARRAY') {
        # filter out owner.  Note that at this stage the value can
        # still be template, so we can not filter the owner if the
        # template is different but yields same value.
        $attributes->{Cc} =
            join(',', grep { $_ ne $self->owner } @{$attributes->{Cc}});
    }
    $attributes->{SquelchMailTo} = $attributes->{Cc}
        if $attributes->{Cc};

    for (values %$attributes) {
        s/\$Approving/\$Tickets{TOP}/g;
    }

    my $content = $self->content || "\n";

    return join("\n",
                "===Create-Ticket: workflow-".$self->name,
                (map { "$_: $attributes->{$_}" } keys %$attributes),
                "Content: $content\nENDOFCONTENT\n");
}

1;
