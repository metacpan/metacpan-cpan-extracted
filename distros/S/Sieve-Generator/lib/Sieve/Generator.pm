package Sieve::Generator 0.001;
# ABSTRACT: generate Sieve email filter scripts

use v5.36.0;

#pod =head1 SYNOPSIS
#pod
#pod   use Sieve::Generator::Sugar '-all';
#pod
#pod   my $script = sieve(
#pod     command('require', qstr([ qw(fileinto imap4flags) ])),
#pod     blank(),
#pod     ifelse(
#pod       header_exists('X-Spam'),
#pod       block(
#pod         command('addflag', qstr('$Junk')),
#pod         command('fileinto', qstr('Spam')),
#pod       ),
#pod     ),
#pod   );
#pod
#pod   print $script->as_sieve;
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Sieve::Generator> is a library for generating Sieve (RFC 5228) email filter
#pod programs.  With it, you build a tree of objects that can be rendered as a
#pod complete, correctly-indented Sieve script.  These trees can be snipped apart
#pod and stitched together, so you can generate subtrees and combined them into the
#pod behavior you want.
#pod
#pod The primary interface is L<Sieve::Generator::Sugar>, which exports short
#pod constructor functions (C<sieve>, C<ifelse>, C<block>, C<command>, C<qstr>,
#pod and so on) for building the object tree without referring to the underlying
#pod class names directly.
#pod
#pod The object tree will be made up of objects that expose an C<as_sieve> method,
#pod which renders the object (and all its descendants) as Sieve.  Some of the
#pod classes are meant to be suitable for direct use, and others are implementation
#pod details that might change later.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator - generate Sieve email filter scripts

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Sieve::Generator::Sugar '-all';

  my $script = sieve(
    command('require', qstr([ qw(fileinto imap4flags) ])),
    blank(),
    ifelse(
      header_exists('X-Spam'),
      block(
        command('addflag', qstr('$Junk')),
        command('fileinto', qstr('Spam')),
      ),
    ),
  );

  print $script->as_sieve;

=head1 DESCRIPTION

C<Sieve::Generator> is a library for generating Sieve (RFC 5228) email filter
programs.  With it, you build a tree of objects that can be rendered as a
complete, correctly-indented Sieve script.  These trees can be snipped apart
and stitched together, so you can generate subtrees and combined them into the
behavior you want.

The primary interface is L<Sieve::Generator::Sugar>, which exports short
constructor functions (C<sieve>, C<ifelse>, C<block>, C<command>, C<qstr>,
and so on) for building the object tree without referring to the underlying
class names directly.

The object tree will be made up of objects that expose an C<as_sieve> method,
which renders the object (and all its descendants) as Sieve.  Some of the
classes are meant to be suitable for direct use, and others are implementation
details that might change later.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
