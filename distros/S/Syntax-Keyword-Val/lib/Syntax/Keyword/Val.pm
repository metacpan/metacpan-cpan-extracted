package Syntax::Keyword::Val;
our $VERSION = '0.001';

# ABSTRACT: A readonly variant of 'my' called 'val'

use strict;
use warnings;
use warnings::register;

use Carp;
use Data::Lock qw[];
use Keyword::Simple;

sub import {
    Data::Lock->import;
    Keyword::Simple::define 'val', \&_process_val_keyword
}
 
sub unimport {
    Keyword::Simple::undefine 'val'
}

sub _process_val_keyword {
    my ($buf) = @_;

    if (warnings::enabled()) {
        $$buf =~ /\A\s*\(?\s*[@%]/
          and carp "'val' has no effect on arrays or hashes (use an arrayref or hashref instead)";
        
        $$buf =~ /\A\s*\(/
          and carp "'val' has no effect on multiple variables after the first";
    }

    substr($$buf, 0, 0) = 'Data::Lock::dlock my'
}


1;

__END__

=pod

=head1 NAME

Syntax::Keyword::Val - Provides a readonly variant of 'my' called 'val'

=head1 WARNING

While I do have serious intentions for this module in the future, it
is definitely a I<toy> as written now.  At this stage, it serves
better as a simple example of using Keyword::Simple.

=head1 DESCRIPTION

Simply use this module, then place the C<val> keyword where you'd normally
use C<my> for a read-only variant.

 use Syntax::Keyword::Val;

 val $foo = "bar";
 $foo = 123;        # ERROR

 val $foo = {a => 123, b => 456};
 $foo->{a}   = 666;       # ERROR
 $foo->{xyz} = "xyzzy";   # ERROR
 delete $foo->{b};        # ERROR

The implementation uses Data::Lock, which itself uses the very fast
internal SV flag to enforce the read-only status, so there should be
no runtime penalty for using it.

=head1 BUGS

Bugs and missing features aplenty.  To start, due to the hacky
implementation using Keyword::Simple (which is great, but quite
limited), the C<val> keyword currently only works for standalone
declarations, i.e. statements that would normally begin with C<my>.
Statements like this will not work:

 # Doesn't work, will generate a syntax error
 open val $fh, '<', $filename;

Only scalars and references can be declared as C<val>.  Attempting to
declare a list or hash as a val will make it a normal variable (and
issue a warning)

 # Issues a warning (assuming 'use warnings' is in effect)
 val @foo = qw(foo bar baz);

Finally, C<val> only applies to the first variable in a group, and the
rest are read-write as normal.

 # Issues a warning (assuming 'use warnings' is in effect)
 val ($foo, $bar) = @baz;

=head1 AUTHOR

Chuck Adams <cja987@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chuck Adams
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
