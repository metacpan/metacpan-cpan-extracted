package Hints::Base::svplus;

use strict;
use Hints::Base;
use vars qw/$VERSION @ISA/;

$VERSION = '0.03';
@ISA = qw/Hints::Base/;

=head1 NAME

Hints::Base::svplus - Hints::Base(3) database for SchemaView Plus

=head1 SYNOPSIS

	use Hints::Base;

	my $hints = new Hints 'svplus';

	print $hints->random();

=head1 DESCRIPTION

Database for program SchemaView Plus usable through Hints::Base(3).

=cut

1;

__DATA__
You can use keypress <S> for changing selected relationship to smooth mode
(and of course back to normal).
---
For short relationships you can use direct relationship mode by keypress <D> on
selected relationship.
---
Normal relationships use traditional auto relationship mode. This mode can
be selected by keypress <A> on selected relationship.
---
Professionals can change any relationship mode to coords based relationship
mode for getting maximum flexibility. Keypress <C> recalculate any relationship
mode to coords based mode.
---
By keypress <F> or <T> you can change from/to which side of table relationship
go. This can be use ussually in auto or coords based relationship mode.
---
<Control> + left mouse button add dragpoint on selected relationship in coords
based mode.
---
<Control> + right mouse button drop inside dragpoint from selected relationship
in coords based mode (you must click on some dragpoint).
---
If relationship in coords based mode is selected you can use left mouse button
to move with dragpoints.
---
<Delete> key unplace relationship or table from canvas.
---
<Control> + <Delete> keys permanently drop selected table or relationship
from object repository (and from canvas too).
---
Try right-click to popup local context menu with useful commands.
---
For printing big poster on many smaller papers like A2 on eight A4 use Poster
predefined PostScript output.
---
Primary keys are shown with marker '='.
---
You can change primary key in edit table dialog.
__END__

=head1 VERSION

0.03

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>) for making
user-friendly interface.

=head1 SEE ALSO

perl(1), svplus(1), Hints(3), Hints::Base(3).

=cut

