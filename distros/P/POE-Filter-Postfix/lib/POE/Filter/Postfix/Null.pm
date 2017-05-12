use strict;
use warnings;

package POE::Filter::Postfix::Null;
our $VERSION = '0.003';


use base qw(POE::Filter::Postfix);

sub attribute_separator  { "\0" }
sub attribute_terminator { "\0" }
sub request_terminator   { "\0" }

1;

__END__
=head1 NAME

POE::Filter::Postfix::Null

=head1 VERSION

version 0.003

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

