package Statistics::CountAverage::XS;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Statistics::CountAverage::XS', $VERSION);


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Statistics::CountAverage::XS - XS implementation of Statistics::CountAverage

=head1 SYNOPSIS

  use Statistics::CountAverage::XS;
  my $avg = new Statistics::CountAverage::XS(10);
  $avg->count;
  ...

=head1 DESCRIPTION

XS implementation of Statistics::CountAverage

=head2 EXPORT

None by default.

=head1 SEE ALSO

Statistics::CountAverage


=head1 AUTHOR

Ildar Efremov, E<lt>iefremov@suse.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ildar Efremov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
