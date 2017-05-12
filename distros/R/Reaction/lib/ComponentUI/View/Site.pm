package ComponentUI::View::Site;

use Reaction::Class;
use aliased 'Reaction::UI::View::TT';

use namespace::clean -except => [ qw(meta) ];
extends TT;



__PACKAGE__->meta->make_immutable;


1;

__END__;

