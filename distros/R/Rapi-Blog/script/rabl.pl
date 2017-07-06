#!/usr/bin/env perl

use strict;

use Rapi::Blog::Util::Rabl;

if (!$ARGV[0] || $ARGV[0] eq '--help') {
  Rapi::Blog::Util::Rabl::usage();
  exit; # redundant
}

Rapi::Blog::Util::Rabl->argv_call();

1;

__END__

=head1 NAME

rabl.pl - Rapi::Blog Utility Script

=head1 SYNOPSIS

 rabl.pl [MODULE] [options]
 
 Available Modules:
   * create

=head1 DESCRIPTION

C<rabl.pl> is a multi-purpose utility script which comprises sub-modules that expose
misc functions on the command line. C<rabl.pl> should be called with the first argument
containing the name of the module followed by its argument list which will be passed in
to the given module.

Call a module with the argument C<--help> to see its usage.

Module names are translated into CamelCased class named under the C<Rapi::Blog::Util::Rabl::*>
namespace. For example, C<'create'> becomes C<'Rapi::Blog::Util::Rabl::Create'>.

So far, the only module which has been written is L<Rapi::Blog::Util::Rabl::Create> which creates
a new L<Rapi::Blog> site in the supplied directory:

  rabl.pl create /path/to/new-site
  cd /path/to/new-site && plackup

=head1 SEE ALSO

=over

=item * 

L<Rai::Blog>

=item *

L<Rapi::Blog::Manual>

=item * 

L<RapidApp>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
