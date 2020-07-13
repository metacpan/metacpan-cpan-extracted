package Path::Dispatcher::Rule;
# ABSTRACT: predicate and codeblock

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Bool);
use Path::Dispatcher::Match;

use constant match_class => "Path::Dispatcher::Match";

has payload => (
    is        => 'ro',
    predicate => 'has_payload',
);

has prefix => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# support for deprecated "block" attribute
sub block { shift->payload(@_) }
sub has_block { shift->has_payload(@_) }
around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);
    $args->{payload} ||= delete $args->{block}
        if exists $args->{block};

    return $args;
};

sub match {
    my $self = shift;
    my $path = shift;
    my %args = @_;

    my $result;

    if ($self->prefix) {
        $result = $self->_prefix_match($path);
    }
    else {
        $result = $self->_match($path);
    }

    return if !$result;

    if (ref($result) ne 'HASH') {
        die "Results returned from _match must be a hashref";
    }

    my $match = $self->match_class->new(
        path => $path,
        rule => $self,
        %{ $args{extra_constructor_args} || {} },
        %$result,
    );

    return $match;
}

sub complete {
    return (); # no completions
}

sub _prefix_match {
    my $self = shift;
    return $self->_match(@_);
}

sub run {
    my $self = shift;

    my $payload = $self->payload;

    die "No codeblock to run" if !$payload;
    die "Payload is not a coderef" if ref($payload) ne 'CODE';

    $self->payload->(@_);
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule - predicate and codeblock

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::Regex->new(
        regex => qr/^quit/,
        block => sub { die "Program terminated by user.\n" },
    );

    $rule->match("die"); # undef, because "die" !~ /^quit/

    my $match = $rule->match("quit"); # creates a Path::Dispatcher::Match

    $match->run; # exits the program

=head1 DESCRIPTION

A rule has a predicate and an optional codeblock. Rules can be matched (which
checks the predicate against the path) and they can be ran (which invokes the
codeblock).

This class is not meant to be instantiated directly, because there is no
predicate matching function. Instead use one of the subclasses such as
L<Path::Dispatcher::Rule::Tokens>.

=head1 ATTRIBUTES

=head2 block

An optional block of code to be run. Please use the C<run> method instead of
invoking this attribute directly.

=head2 prefix

A boolean indicating whether this rule can match a prefix of a path. If false,
then the predicate must match the entire path. One use-case is that you may
want a catch-all rule that matches anything beginning with the token C<ticket>.
The unmatched, latter part of the path will be available in the match object.

=head1 METHODS

=head2 match path -> match

Takes a path and returns a L<Path::Dispatcher::Match> object if it matched the
predicate, otherwise C<undef>. The match object contains information about the
match, such as the results (e.g. for regex, a list of the captured variables),
the C<leftover> path if C<prefix> matching was used, etc.

=head2 run

Runs the rule's codeblock. If none is present, it throws an exception.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Dispatcher>
(or L<bug-Path-Dispatcher@rt.cpan.org|mailto:bug-Path-Dispatcher@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
