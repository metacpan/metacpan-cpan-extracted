package Net::Google::Code::Role::HTMLTree;
use Any::Moose 'Role';

use HTML::TreeBuilder;
use Params::Validate qw(:all);
use Scalar::Util qw/blessed/;

sub html_tree {
    my $self = shift;
    my %args = validate( @_, { html => { type => SCALAR } } );
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content($args{html});
    $tree->elementify;
    return $tree;
}

sub html_tree_contains {
    my $self = shift;
    my %args = validate(
        @_,
        {
            html      => { type => SCALAR },
            look_down => { type => ARRAYREF, optional => 1 },

            # SCALARREF is for the regex
            as_text => { type => SCALAR | SCALARREF },
        }
    );

    my $tree;
    my $need_delete;
    if ( blessed $args{html} ) {
        $tree = $args{html};
    }
    else {
        $tree = $self->html_tree( html => $args{html} );
        $need_delete = 1;
    }

    my $part = $tree;
    if ( $args{look_down} ) {
        ($part) = $tree->look_down( @{ $args{look_down} } );
    }


    my $text = $part && $part->as_text;
    $tree->delete if $need_delete;

    return unless defined $text;

    return 1 if $text eq $args{as_text};

    if ( ( ref $args{as_text} eq 'Regexp' ) && ( my @captures =
        $text =~ $args{as_text} ) )
    {
# note, if there's no captures at all but the string matches, 
# @captures will be set to (1), so don't use @captures unless you 
# know there's some capture in the regex
        return wantarray ? ( 1, @captures ) : 1;
    }
    return;
}

no Any::Moose;

1;

__END__

=head1 NAME

Net::Google::Code::Role::HTMLTree - HTMLTree Role

=head1 DESCRIPTION

=head1 INTERFACE

=head2 html_tree

return a new HTML::TreeBuilder object, with current content parsed

=head2 html_tree_contains

a help method to help test if the current content contains some stuff, args are:
look_down => [ look_down's args ]
as_text => qr/foo/

look_down is used to limit the area,
as_text's value can be regex or string 

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


