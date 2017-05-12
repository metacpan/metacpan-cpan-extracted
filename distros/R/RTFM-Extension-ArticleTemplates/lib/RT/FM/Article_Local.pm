# BEGIN LICENSE BLOCK
#
#  Copyright (c) 2002-2008 Jesse Vincent <jesse@bestpractical.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of version 2 of the GNU General Public License
#  as published by the Free Software Foundation.
#
#  A copy of that license should have arrived with this
#  software, but in any event can be snarfed from www.gnu.org.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
# END LICENSE BLOCK

package RT::FM::Article;
use strict;
no warnings qw/redefine/;

=head2 ParseTemplate $CONTENT, %TEMPLATE_ARGS

Parses $CONTENT string as a template (L<Text::Template>).
$Article and other arguments from %TEMPLATE_ARGS are
available in code of the template as perl variables.

=cut

sub ParseTemplate {
    my $self = shift;
    my $content = shift;
    my %args = (
        Ticket => undef,
        @_
    );

    return ($content) unless defined $content && length $content;

    $args{'Article'} = $self;
    $args{'rtname'}  = $RT::rtname;
    if ( $args{'Ticket'} ) {
        my $t = $args{'Ticket'}; # avoid memory leak
        $args{'loc'} = sub { $t->loc(@_) };
    } else {
        $args{'loc'} = sub { $self->loc(@_) };
    }

    foreach my $key ( keys %args ) {
        next unless ref $args{ $key };
        next if ref $args{ $key } =~ /^(ARRAY|HASH|SCALAR|CODE)$/;
        my $val = $args{ $key };
        $args{ $key } = \$val;
    }

    # We need to untaint the content of the template, since we'll be working
    # with it
    $content =~ s/^(.*)$/$1/;
    my $template = Text::Template->new(
        TYPE   => 'STRING',
        SOURCE => $content
    );

    my $is_broken = 0;
    my $retval = $template->fill_in(
        HASH => \%args,
        BROKEN => sub {
            my (%args) = @_;
            $RT::Logger->error("Article parsing error: $args{error}")
                unless $args{error} =~ /^Died at /; # ignore intentional die()
            $is_broken++;
            return undef;
        },
    );
    return ( undef, $self->loc('Article parsing error') ) if $is_broken;

    return ($retval);
}

1
