use strict;
use warnings;

package SVN::RaWeb::Light::OutputListOnly;

use base 'SVN::RaWeb::Light';

sub _process_dir
{
    my $self = shift;
    $self->_get_dir();
    $self->_print_items_list();
}

1;

package SVN::RaWeb::Light::OutputTransAndList;

use base 'SVN::RaWeb::Light';

sub _process_dir
{
    my $self = shift;
    $self->_get_dir();

    print $self->_render_top_url_translations_text();
    $self->_print_items_list();
}

1;

