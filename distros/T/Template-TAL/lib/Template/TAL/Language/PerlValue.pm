=head1 NAME

Template::TAL::Language::PerlValue - use perl in TAL attributes

=head1 SYNOPSIS

  (in a template)
  
  <hi tal:content="perl: `cat /etc/passwd`">title here</h1>
  
=head1 DESCRIPTION

Loading this module as a language into your TAL parser will allow you to use 
perl code in your attribute values. This is, of course, horribly dangerous. 
The core of TAL is safe to expose to users - there are no core functions that 
let a template damage your system. But loading PerlValue will let the writer 
of the template perform arbitrary actions on your server as the user that is 
running the perl process. You have access to all of perl from within your 
attribute code. You can load modules, open files, delete things, send email, 
whatever.

If you just want the ability to do simple computations in your templates I 
suggest you look at Template::TAL::Language::JavaScript, which embeds a nicely 
sandboxed JavaScript interpreter, and is much safer.

Assuming you're happy with this...

In your perl code, you will have access to a $context hashref, which is
the local TAL context. Altering this hash will change the context.

=cut

package Template::TAL::Language::PerlValue;
use warnings;
use strict;
use base qw( Template::TAL::Language );

=over

=item process_tales_perl( path, contexts, plugins )


=cut

sub process_tales_perl {
  # use really weird variable names, to try to avoid clashing with things.
  my ($___class, $___path, $___contexts, $___plugins) = @_;
  my $context = { map(%$_, reverse @$___contexts) };
  my $___res = eval($___path);
  die $@ if $@;
  return $___res;
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut



1;
