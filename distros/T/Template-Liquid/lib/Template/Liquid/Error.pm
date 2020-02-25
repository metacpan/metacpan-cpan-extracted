package Template::Liquid::Error;
our $VERSION = '1.0.17';
use strict;
use warnings;
sub message { return $_[0]->{'message'} }
sub fatal   { return $_[0]->{'fatal'} }

sub new {
    my ($class, $args) = @_;
    $args->{'fatal'} = defined $args->{'fatal'} ? $args->{'fatal'} : 0;
    require Carp;
    Carp::longmess() =~ m[^.+?\n\t(.+)]so;
    $args->{'message'} = sprintf '%s [%s]: %s %s', $class, $args->{'type'},
        $args->{'message'}, $1;
    return bless $args, $class;
}

sub raise {
    my ($s) = @_;
    $s = ref $s ? $s : $s->new($_[1]);
    die $s->message if $s->fatal;
    warn $s->message;
}
sub render { $_[0]->{message} }
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Error - General Purpose Error Object

=head1 Description

This is really only to be used internally.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of L<The Artistic License
2.0|http://www.perlfoundation.org/artistic_license_2_0>. See the F<LICENSE>
file included with this distribution or L<notes on the Artistic License
2.0|http://www.perlfoundation.org/artistic_2_0_notes> for clarification.

When separated from the distribution, all original POD documentation is covered
by the L<Creative Commons Attribution-Share Alike 3.0
License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>. See the
L<clarification of the
CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
