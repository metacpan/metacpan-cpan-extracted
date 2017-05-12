package Object::NulStr;

use 5.010001;

our $VERSION = '0.02'; # VERSION

use overload q{""} => sub { "\0" };

sub new { bless(\"$_[0]", $_[0]) }

1;
# ABSTRACT: Object which stringifies to NUL character ("\0")

__END__

=pod

=head1 NAME

Object::NulStr - Object which stringifies to NUL character ("\0")

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Object::NulStr;

 die Object::NulStr->new; # dies without seemingly printing anything

=head1 DESCRIPTION

Object::NulStr is like L<Object::BlankStr>, but instead of stringifying to ""
(empty string), it stringifies to "\0" (NUL character). This has the benefit of
having a boolean true value so checking exception is simpler (a simple if on $@
will do). But Object::BlankStr might suit you better if printing "\0" has some
undesired side effects. Too bad we can't have it both ways for now.

So far the only case I've found this to be useful is for die()-ing without
printing anything. If you just use 'die;' or 'die "";' Perl will print the
default "Died at ..." message. But if you say 'die Object::NulStr->new;' Perl
will die without seemingly printing anything.

=for Pod::Coverage ^(new)$

=head1 SEE ALSO

L<Object::BlankStr>

L<Object::SpaceBackStr>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
