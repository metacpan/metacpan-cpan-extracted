package Path::Dispatcher::Rule::Eq;
# ABSTRACT: predicate is a string equality

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Str Bool);

extends 'Path::Dispatcher::Rule';

has string => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has case_sensitive => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;

    if ($self->case_sensitive) {
        return unless $path->path eq $self->string;
    }
    else {
        return unless lc($path->path) eq lc($self->string);
    }

    return {};
}

sub _prefix_match {
    my $self = shift;
    my $path = shift;

    my $truncated = substr($path->path, 0, length($self->string));

    if ($self->case_sensitive) {
        return unless $truncated eq $self->string;
    }
    else {
        return unless lc($truncated) eq lc($self->string);
    }

    return {
        leftover => substr($path->path, length($self->string)),
    };
}

sub complete {
    my $self = shift;
    my $path = shift->path;
    my $completed = $self->string;

    # by convention, complete does include the path itself if it
    # is a complete match
    return if length($path) >= length($completed);

    my $partial = substr($completed, 0, length($path));
    if ($self->case_sensitive) {
        return unless $partial eq $path;
    }
    else {
        return unless lc($partial) eq lc($path);
    }

    return $completed;
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Eq - predicate is a string equality

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::Eq->new(
        string => 'comment',
        block  => sub { display_comment(shift->pos(1)) },
    );

=head1 DESCRIPTION

Rules of this class simply check whether the string is equal to the path.

=head1 ATTRIBUTES

=head2 string

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
