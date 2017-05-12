package Module::New::File::Readme;

use strict;
use warnings;
use Module::New::File;

file 'README' => content { return <<'EOT';
<%= $c->distname %>

INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

COPYRIGHT AND LICENSE

Copyright (C) <%= $c->date->year %> <%= $c->config('author') %>

<%= $c->license->notice %>
EOT
};

1;

__END__

=head1 NAME

Module::New::File::Readme

=head1 DESCRIPTION

a template for C<README> file.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
