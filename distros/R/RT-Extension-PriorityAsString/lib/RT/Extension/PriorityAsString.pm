use 5.008003;
use strict;
use warnings;

package RT::Extension::PriorityAsString;

our $VERSION = '1.04';

=head1 NAME

RT::Extension::PriorityAsString - show priorities in RT as strings instead of numbers

=head1 SYNOPSIS

    # in RT config
    Set(@Plugins, qw(... RT::Extension::PriorityAsString ...));

    # Specify a mapping between priority strings and the internal
    # numeric representation
    Set(%PriorityAsString, (Low => 0, Medium => 50, High => 100));

    # Fine-tuned control of the order of priorities as displayed in the
    # drop-down box; usually this computed automatically and need not be
    # set explicitly.  It can be used to limit the set of options
    # presented during update, but allow a richer set of levels when
    # they are adjusted automatically.
    # Set(@PriorityAsStringOrder, qw(Low Medium High));

    # Uncomment if you want to apply different configurations to
    # different queues.  Each key is the name of a different queue;
    # queues which do not appear in this configuration will use RT's
    # default numeric scale.
    # This option means that %PriorityAsString and
    # @PriorityAsStringOrder are ignored (no global override, you must
    # specify a set of priorities per queue). You can safely leave them
    # out of your RT_SiteConfig.pm to avoid confusion.
    # Set(%PriorityAsStringQueues,
    #    General => { Low => 0, Medium => 50, High => 100 },
    #    Binary  => { Low => 0, High => 10 },
    # );

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::PriorityAsString');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::PriorityAsString));

or add C<RT::Extension::PriorityAsString> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

require RT::Ticket;
package RT::Ticket;

$RT::Config::META{PriorityAsString}{Type} = 'HASH';
$RT::Config::META{PriorityAsStringOrder}{Type} = 'ARRAY';
$RT::Config::META{PriorityAsStringQueues}{Type} = 'HASH';


# Returns String: Various Ticket Priorities as either a string or integer
sub PriorityAsString {
    my $self = shift;
    return $self->_PriorityAsString($self->Priority);
}

sub InitialPriorityAsString {
    my $self = shift;
    return $self->_PriorityAsString( $self->InitialPriority );
}

sub FinalPriorityAsString {
    my $self=shift;
    return $self->_PriorityAsString( $self->FinalPriority );
}

sub _PriorityAsString {
    my $self = shift;
    my $priority = shift;
    return undef unless defined $priority && length $priority;

    my %map;
    my $queues = RT->Config->Get('PriorityAsStringQueues');
    if (@_) {
        %map = %{ shift(@_) };
    } elsif ($queues and $queues->{$self->QueueObj->Name}) {
        %map = %{ $queues->{$self->QueueObj->Name} };
    } else {
        %map = RT->Config->Get('PriorityAsString');
    }

    # Count from high down to low until we find one that our number is
    # greater than or equal to.
    foreach my $label ( sort { $map{$b} <=> $map{$a} } keys %map ) {
        return $label if $priority >= $map{ $label };
    }
    return "unknown";
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-PriorityAsString@rt.cpan.org|mailto:bug-RT-Extension-PriorityAsString@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-PriorityAsString>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2014, Best Practical Solutions LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
