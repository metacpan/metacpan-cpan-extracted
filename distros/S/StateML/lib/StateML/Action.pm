package StateML::Action;

use strict ;
use base qw(StateML::Object ) ;

=head1 NAME

StateML::Action - A single action that can be used in multiple event handlers

=head1 DESCRIPTION

This is an optional part of StateML.  It can be handy to package up an
action that occurs in several places in a state machine using <action>
elements and the corresponding action_id attributes.

=cut

sub handlers {
    my $self = shift;
    @{$self->{HANDLERS}} = @_ if @_;
    return @{$self->{HANDLERS} || []};
}

sub description {
    my $self = shift;
    $self->{DESCRIPTION} = shift if @_;
    return $self->{DESCRIPTION};
}

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1 ;
