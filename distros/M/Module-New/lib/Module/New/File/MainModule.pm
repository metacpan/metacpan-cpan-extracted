package Module::New::File::MainModule;

use strict;
use warnings;
use Module::New::File;

our $VERSION = '0.15'; # because this file had one previously

file '{MAINFILE}' => content { return <<'EOT';
package <%= $c->module %>;

use strict;
use warnings;

our <%= '$'.'VERSION' %> = '0.01';

% if ($c->config('xs')) {
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);
% }

1;

__END__

=encoding utf-8

=head1 NAME

<%= $c->module %> - 

=head1 SYNOPSIS

    use <%= $c->module %>;

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

<%= $c->config('author') %>, E<lt><%= $c->config('email') %>E<gt>

=head1 COPYRIGHT AND LICENSE

<%= $c->license->notice %>
=cut
EOT
};

1;

__END__

=head1 NAME

Module::New::File::MainModule

=head1 DESCRIPTION

a template for a main module (C<lib/Module/Name.pm>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
