package Signal::Safety;
{
  $Signal::Safety::VERSION = '0.002';
}
use 5.008001;
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: Enable or disable safe signal handling



=pod

=head1 NAME

Signal::Safety - Enable or disable safe signal handling

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 {
     local $Signal::Safety = 0;
     do_something_scary():
 }

=head1 DESCRIPTION

This module exposes perl's signal safety feature. It allows you to temporarily turn off safe signal handling in a user-friendly way.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

