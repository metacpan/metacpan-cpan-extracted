use strict; use warnings;
package Module::Install::InlineModule;
our $VERSION = '0.03';

use base 'Module::Install::Base';
use Inline::Module();

sub inline {
    my ($self, %args) = @_;

    my $meta = \%args;
    my $makemaker = {};
    my $postamble = Inline::Module::postamble(
        $makemaker,
        inline => $meta,
    );
    $self->postamble($postamble);
    for my $module (Inline::Module->included_modules($meta)) {
        $self->include($module);
    }
}

1;
