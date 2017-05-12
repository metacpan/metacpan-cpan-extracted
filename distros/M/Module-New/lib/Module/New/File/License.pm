package Module::New::File::License;

use strict;
use warnings;
use Module::New::File;

file 'LICENSE' => content { return <<'EOT';
<%= $c->license->fulltext %>
EOT
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::File::License

=head1 DESCRIPTION

a template for LICENSE file.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
