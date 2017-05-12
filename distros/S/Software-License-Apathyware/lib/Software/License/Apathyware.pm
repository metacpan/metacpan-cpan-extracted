use strict;
use warnings;
package Software::License::Apathyware;
{
  $Software::License::Apathyware::VERSION = '0.0.3';
}

use base 'Software::License';
# ABSTRACT: Apathyware License

sub name { 'Apathyware License v1' }
sub url  { 'https://www.google.com/search?num=100&hl=en&safe=off&site=&source=hp&q=apathyware&oq=apathyware' }
sub meta_name  { 'open_source' }
sub meta2_name { 'open_source' }


1;

=pod

=head1 NAME

Software::License::Apathyware - Apathyware License

=head1 VERSION

version 0.0.3

=head1 NAME

Software::License::Apathyware - Apathyware License

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Marc Kandel <marc.kandel.cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Marc Kandel.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Marc Kandel <marc.kandel.cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Marc Kandel.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
__NOTICE__
This software is copyright (c) {{$self->year}} by {{$self->holder}}.

This code is released as Apathyware:

"The code doesn't care what you do with it, and neither do I."
__LICENSE__
