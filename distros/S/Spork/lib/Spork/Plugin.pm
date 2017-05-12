package Spork::Plugin;
use Spoon::Plugin -Base;
our $VERSION = '0.01';

stub 'class_id';

field config   => {}, -init => '$self->hub->config';
field template => {}, -init => '$self->hub->template';
field formatter => {},-init => '$self->hub->formatter';


__END__

=head1 NAME

Spork::Plugin - Spork plugin base class

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
