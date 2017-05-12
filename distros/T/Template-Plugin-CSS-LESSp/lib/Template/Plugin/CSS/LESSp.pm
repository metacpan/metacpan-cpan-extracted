package Template::Plugin::CSS::LESSp;
{
  $Template::Plugin::CSS::LESSp::VERSION = '0.03';
}

use strict;
use warnings;
use CSS::LESSp;

use base 'Template::Plugin::Filter';

=head1 NAME

Template::Plugin::CSS::LESSp - Filter your CSS with CSS::LESSp

=head1 SYNOPSIS

 [% USE CSS::LESSp %]
 [% FILTER CSS::LESSp %]
   your CSS with LESS extentions (variables, mixins, nested rules, operations)
 [% END %]

This filter is useful when you want to write less css ;-)

See L<CSS::LESSp> and L<http://lesscss.org/> for more information.

=cut

sub init {
    my ($self) = @_;
    $self->install_filter('CSS::LESSp');
    return $self;
}

sub filter {
    my ($self, $text) = @_;
    return join( '', CSS::LESSp->parse($text) );
}

=head1 AUTHOR

Michael Langner, C<< <mila at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-css-lessp at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-CSS-LESSp>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2014 Michael Langner, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

1; # track-id: 3a59124cfcc7ce26274174c962094a20
