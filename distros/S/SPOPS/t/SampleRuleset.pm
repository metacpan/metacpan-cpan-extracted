package SampleRuleset;

# $Id: SampleRuleset.pm,v 3.0 2002/08/28 01:16:32 lachoy Exp $

use strict;

sub ruleset_factory {
    my ( $class, $ruleset ) = @_;
    push @{ $ruleset->{post_save_action} }, \&reset_id;
    return __PACKAGE__;
}

# Always rewrite the ID to 'blimey!'

sub reset_id {
    my ( $self ) = @_;
    return 1 if ( $self->is_saved );
    my $id_field = $self->id_field;
    $self->{ $id_field } = "blimey!";
    return 1;
}

1;
