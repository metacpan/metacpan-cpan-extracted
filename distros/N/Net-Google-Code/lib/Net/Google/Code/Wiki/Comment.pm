package Net::Google::Code::Wiki::Comment;

use Any::Moose;
use Params::Validate qw(:all);
with 'Net::Google::Code::Role::HTMLTree';

has 'content' => (
    isa => 'Str',
    is  => 'rw',
);

has 'author' => (
    isa => 'Str',
    is  => 'rw',
);

has 'date' => (
    isa => 'Str',
    is  => 'rw',
);

sub parse {
    my $self    = shift;
    my $element = shift;
    my $need_update = not blessed $element;
    $element = $self->html_tree( html => $element ) unless blessed $element;

    my $author =
      $element->look_down( class => 'author' )->find_by_tag_name('a')->as_text;
    my $date = $element->look_down( class => 'date' )->attr('title');
    my $content = $element->look_down( class => 'commentcontent' )->as_text;
    $content =~ s/\s+$//; # remove trailing spaces

    $self->author( $author ) if $author;
    $self->date( $date ) if $date;
    $self->content( $content ) if $content;
    $element->delete if $need_update;
    return 1;
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Google::Code::Wiki::Comment - Google Code Wiki Comment

=head1 INTERFACE

=over 4

=item parse( HTML::Element or html segment string )

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

