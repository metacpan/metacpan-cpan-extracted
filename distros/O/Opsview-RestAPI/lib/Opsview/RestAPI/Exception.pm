use 5.12.1;
use strict;
use warnings;

package Opsview::RestAPI::Exception;
$Opsview::RestAPI::Exception::VERSION = '1.251900';
# ABSTRACT: Opsview::RestAPI Exception object


use overload
    bool => sub {1},
    eq   => sub { $_[0]->as_string },
    '""' => sub { $_[0]->as_string },
    "0+" => sub {1};


sub new {
    my ( $class, %args ) = @_;

    my @caller_keys = (
        qw/ package filename line subroutine hasargs wantarray evaltext is_require / 
    );
    #hints bitmask hinthash /

    # Build up the callstack to a max of 7 levels
    my $i=0;
    # note '{{' is to allow use of 'last'
    do {{
        my @caller = (caller($i++));
        last unless(@caller);

        push( @{ $args{callstack} }, { map { $caller_keys[$_] => $caller[$_] } ( 0 .. $#caller_keys) } );
    }} while ( $i < 7 );

    bless { %args }, $class;
}


sub line     { $_[0]->{callstack}[0]{line} }
sub path     { $_[0]->{callstack}[0]{filename} }
sub filename { $_[0]->{callstack}[0]{filename} }
sub package  { $_[0]->{callstack}[0]{package} }


sub message {
    return $_[0]->{message};
}


sub http_code {
    return $_[0]->{http_code};
}


sub as_string {
    my $self = shift;

    return sprintf( "Error: %s at %s line %s.\n",
        $self->message, $self->path, $self->line );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Opsview::RestAPI::Exception - Opsview::RestAPI Exception object

=head1 VERSION

version 1.251900

=head1 SYNOPSIS

use Carp qw(croak confess);
use Opsview::RestAPI::Exception;

# exception 
croak(Opsview::RestAPI::Exception->new( message => 'some text', http_code => 404));

# exception with stack trace
confess(Opsview::RestAPI::Exception->new( message => 'some text', http_code => 404));

=head1 DESCRIPTION

Exception objects created when Opsview::RestAPI encountered problems

=head2 METHODS

=over 4

=item $object = Opsview::RestAPI::Exception->new( ... )

Create a new exception object.  By default will add in package, filename and line the exception occurred on

=item $line = $object->line;

=item $path = $object->path;

=item $filename = $object->filename;

=item $package = $object->package;

Return the line, path and package the exception occurred in

=item $message = $object->message;

Return the message provided when the object was created

=item $message = $object->http_code;

Return the http_code provided when the object was created

=item $string = $object->as_string

Concatinate the message, path and line into a string string

=back

=head1 AUTHOR

Duncan Ferguson <duncan_j_ferguson@yahoo.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Duncan Ferguson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
