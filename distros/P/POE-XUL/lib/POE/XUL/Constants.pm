package POE::XUL::Constants;
# $Id: Constants.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.

use strict;
use warnings;
use Carp;

our $VERSION = '0.0601';

require Exporter;
our @ISA = qw( Exporter );

our @EXPORT = qw(
	FLEX ALIGN_START ALIGN_CENTER ALIGN_END ALIGN_BASELINE ALIGN_STRETCH
	ALIGN_LEFT ALIGN_CENTER ALIGN_RIGHT PACK_START PACK_CENTER PACK_END
	ORIENT_HORIZONTAL ORIENT_VERTICAL DIR_FORWARD DIR_REVERSE CROP_START
	CROP_CENTER CROP_END SIZE_TO_CONTENT DISABLED ENABLED TYPE_CHECKBOX
	TYPE_RADIO TYPE_MENU TYPE_MENU_BUTTON TYPE_BUTTON TYPE_PASSWORD FILL
);

use constant FLEX              => (flex => 1);

use constant ALIGN_START       => (align => 'start');
use constant ALIGN_CENTER      => (align => 'center');
use constant ALIGN_END         => (align => 'end');
use constant ALIGN_BASELINE    => (align => 'baseline');
use constant ALIGN_STRETCH     => (align => 'stretch');
use constant ALIGN_LEFT        => (align => 'left');
use constant ALIGN_RIGHT       => (align => 'right');

use constant PACK_START        => (pack => 'start');
use constant PACK_CENTER       => (pack => 'center');
use constant PACK_END          => (pack => 'end');

use constant ORIENT_HORIZONTAL => (orient => 'horizontal');
use constant ORIENT_VERTICAL   => (orient => 'vertical');

use constant DIR_FORWARD       => (dir => 'forward');
use constant DIR_REVERSE       => (dir => 'reverse');

use constant CROP_START        => (crop => 'start');
use constant CROP_CENTER       => (crop => 'center');
use constant CROP_END          => (crop => 'end');

use constant SIZE_TO_CONTENT   => (sizeToContent => 1);

use constant DISABLED          => (disabled => 1);
use constant ENABLED           => (disabled => 0);

use constant TYPE_CHECKBOX     => (type => 'checkbox');
use constant TYPE_RADIO        => (type => 'radio');
use constant TYPE_MENU         => (type => 'menu');
use constant TYPE_MENU_BUTTON  => (type => 'menu-button');
use constant TYPE_BUTTON       => (type => 'button');
use constant TYPE_PASSWORD     => (type => 'PASSWORD');

use constant FILL              => (ALIGN_STRETCH, FLEX);

1;

__END__

=head1 NAME

POE::XUL::Constants - XUL attribute helpers

=head1 SYNOPSIS

    use POE::XUL::Node;

    Window( SIZE_TO_CONTENT, ORIENT_HORIZONTAL );
    Description( FILL, "Some text" );
    my $item = MenuItem( DISABLED, label=>"--------" );
    $item->setAttribute( ENABLED );

=head1 DESCRIPTION

POE::XUL::Constants provides a bunch of constants for commonly used
attributes.

=head1 CONSTANTS

=over 4

=item FLEX

    flex="1"

=item ALIGN_START

    align="start";

=item ALIGN_CENTER

    align="center"

=item ALIGN_END

    align="end"

=item ALIGN_BASELINE

    align="baseline"

=item ALIGN_STRETCH

    align="stretch"

=item ALIGN_LEFT

    align="left"

=item ALIGN_RIGHT

    align="right"


=item PACK_START

    pack="start"

=item PACK_CENTER

    pack="center"

=item PACK_END

    pack="end"


=item ORIENT_HORIZONTAL

    orient="horizontal"

=item ORIENT_VERTICAL

    orient="vertical"

=item DIR_FORWARD

    dir="forward"

=item DIR_REVERSE

    dir="reverse"

=item CROP_START

    crop="start"

=item CROP_CENTER

    crop="center"

=item CROP_END

    crop="end"

=item SIZE_TO_CONTENT

    sizeToContent="1"

=item DISABLED

    disabled="1"

=item ENABLED

    disabled="0"

=item TYPE_CHECKBOX

    type="checkbox"

=item TYPE_RADIO

    type="radio"

=item TYPE_MENU

    type="menu"

=item TYPE_MENU_BUTTON

    type="menu-button"

=item TYPE_BUTTON

    type="button"

=item TYPE_PASSWORD

    type="password"


=item FILL

    align="stretch" stretch="1"

=back


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node::Constants by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Node>, , L<POE::XUL::TextNode>.

=cut

