package Module::New::File::XS;

use strict;
use warnings;
use Module::New::File;

file '{MODULEBASE}.xs' => content { return <<'EOT';
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "<%= $c->module_base %>.h"
#ifdef __cplusplus
}
#endif

MODULE = <%= $c->module %>  PACKAGE = <%= $c->module %>
EOT
};

file '{MODULEBASE}.h' => content { return <<'EOT';
#ifndef <%= uc $c->module_id %>_H
#define <%= uc $c->module_id %>_H 1

#endif /* #ifndef <%= uc $c->module_id %>_H */
EOT
};

1;

__END__

=head1 NAME

Module::New::File::XS

=head1 DESCRIPTION

a template for a main xs (C<Name.xs>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
