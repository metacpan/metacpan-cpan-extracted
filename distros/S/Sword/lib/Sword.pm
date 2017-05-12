package Sword;
BEGIN {
  $Sword::VERSION = '0.102800';
}
use strict;
use warnings;

use Sword::Key;
use Sword::Manager;
use Sword::Module;

# ABSTRACT: provides an interface to the Sword Open Source Bible Software API


1;

__END__
=pod

=head1 NAME

Sword - provides an interface to the Sword Open Source Bible Software API

=head1 VERSION

version 0.102800

=head1 SYNOPSIS

  use Sword;
  use List::Util qw( first );
  
  my $library = Sword::Manager->new;
  
  print "Your library contains:\n\n";
  for my $module (sort { $a->type cmp $b->type } @{ $library->modules }) {
      print "    ", $module->type, ": ", $module->name, " - ", 
  	  $module->description, "\n";
  }
  
  print "\n";
  
  # Try a preferred list of Bibles...
  my $bible = $library->get_module('ESV')
           || $library->get_module('KJV');
  
  # Or find any Bible...
  $bible = first { $_->type eq 'Biblical Texts' } @{ $library->modules };
  
  if ($bible) {
      $bible->set_key('John 3:16'); # can us abbrevs, like jn3.16
      my $verse = $bible->render_text;
      print "John 3:16: $verse\n";
  }
  
  else {
      print "No Bible was found in your library. You may need to open your Sword software to install one.\n";
  }
  
  print "\n\n";
  
  my $dict = $library->get_module('WebstersDict');
  if ($dict) {
      $dict->set_key('dictionary');
      my $description = $dict->description;
      print "According to $description:\n\n";
      print $dict->render_text, "\n";
  }

=head1 DESCRIPTION

B<EXPERIMENTAL>. The goal is to reproduce the Sword Engine API in Perl. This is really just the first foray into that direction. It simply provides just enough to do what's shown in the L</SYNOPSIS> and perhaps a bit more. Future versions should do more, but the Perl API may change in the process, so be sure to check the F<Changes> file for each release for API compatibility.

This module exists for convenience and does nothing more than load the most commonly needed modules:

=over

=item *

L<Sword::Key>

=item *

L<Sword::Manager>

=item *

L<Sword::Module>

=back

=head1 BUGS

=over

=item *

This almost certainly leaks memory. I need to work on that.

=item *

This library does not yet cover very much of what the Sword API is capable of.

=back

=head1 SEE ALSO

L<Sword::Manager>, L<Sword::Module>.

Sword Project: L<http://www.crosswire.org/sword/index.jsp>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

