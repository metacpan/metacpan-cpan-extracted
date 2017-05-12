package Runops::Optimized;
use 5.014;
use XSLoader;

our $VERSION = '0.02';

XSLoader::load "Runops::Optimized", $VERSION;

__END__

=head1 NAME

Runops::Optimized - Optimized run loop

=head1 SYNOPSIS

  use Runops::Optimized;

or

  export PERL5OPT=-mRunops::Optimized

=head1 DESCRIPTION

This is an B<experimental> runloop for perl >= 5.14. It replaces the core perl
runloop defined in F<run.c> with a version that unrolls the operations into
assembly. This could be a tiny bit faster depending on your CPU.

Please don't use this unless you wish to help development, the main reason it
is on CPAN is to get CPAN testers reports.

=head1 SEE ALSO

L<Runops::Switch>, L<Faster>.

=head1 LICENSE

Copyright 2011 L<David Leadbeater|http://dgl.cx>. This program is free
software; you can redistribute it and/or modify it under the same terms as perl
5.14 or any later version of perl 5.

Includes L<sljit|http://sljit.sourceforge.net>:
  
  Copyright 2009-2010 Zoltan Herczeg (hzmester@freemail.hu). All rights
  reserved.

Under a BSD-like license, see F<sljit/sljirLir.h>.

=head1 AUTHOR

David Leadbeater E<lt>L<dgl@dgl.cx>E<gt>, 2011

=head1 THANKS

Some ideas come from Reini Urban's L<Jit module|https://github.com/rurban/Jit>.

Additional inspiration from many sources, particularly
L<LuaJIT|http://luajit.org>, although obviously this is no match for that.

=cut
