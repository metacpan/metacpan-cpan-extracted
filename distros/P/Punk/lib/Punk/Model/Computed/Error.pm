package Punk::Model::Computed::Error;

use 5.010;
use strict;
use warnings;
use Punk ();
use overload '""' => 'message', fallback => 1;

our $VERSION = '0.65';

1;

__END__

=head1 NAME

Punk::Model::Computed::Error - a visitor's input a computed backend will not take, naming its field

=head1 SYNOPSIS

    my $runs = eval { $c->model('TimeRun')->search({ rule => $expr }) };
    if (ref $@ && $@->isa('Punk::Model::Computed::Error')) {
        return $c->json({ error => $@ }, 400);
    }

    Punk::Model::Computed::Error->throw(zone => "no time zone is called 'Mars/Olympus'");

=head1 DESCRIPTION

What a L<Punk::Model::Computed> backend dies with when a visitor's input will not
do: a C<field> (the filter field at fault) and a C<message> (a sentence for the
visitor). It stringifies to the message, and C<TO_JSON> gives both, so it can be
returned as a JSON body as it is.

A program's misuse of a backend (a field the model does not declare, an operator or
an option the backend does not take) croaks with a plain string instead: that is
the program's fault, not the visitor's.

A subclass of this class is an error of this kind too: C<from> and
L<Punk::Model::Computed/wrap> pass one through unchanged.

=head1 METHODS

=head2 new

    my $e = Punk::Model::Computed::Error->new($field, $message);

=head2 throw

    Punk::Model::Computed::Error->throw($field, $message);

Dies with a new error of the class it is called on.

=head2 from

    my $e = Punk::Model::Computed::Error->from($field, $@);

The error a die becomes: the die itself when it is one of these already, else a new
one for C<$field> with the die's text as L</said> gives it.

=head2 said

    my $text = Punk::Model::Computed::Error->said($@);

A die's text as a visitor should read it: without the C<at FILE line N.> it ends
with (and perl's C<< , <FH> line N >> after that), and without a leading
C<< Class->method: >>, the way a module's croak names itself. So C<<
Time::Keeper->new: no such month at lib/Time/Keeper.pm line 40. >> is C<no such
month>. An object is its string.

=head2 field

=head2 message

=head2 TO_JSON

C<< { field => ..., message => ... } >>.

=head1 SEE ALSO

L<Punk::Model::Computed>, L<Punk::Validate>.

=cut
