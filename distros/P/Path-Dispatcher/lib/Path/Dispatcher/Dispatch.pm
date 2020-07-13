package Path::Dispatcher::Dispatch;
# ABSTRACT: a list of matches

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Try::Tiny;
use Carp qw(confess);
use Types::Standard qw(ArrayRef);

use Path::Dispatcher::Match;

has _matches => (
    is        => 'ro',
    isa       => ArrayRef,
    default   => sub { [] },
);

sub add_match {
    my $self = shift;

    $_->isa('Path::Dispatcher::Match')
        or confess "$_ is not a Path::Dispatcher::Match"
            for @_;

    push @{ $self->{_matches} }, @_;
}

sub matches     { @{ shift->{_matches} } }
sub has_match   { scalar @{ shift->{_matches} } }
sub first_match { shift->{_matches}[0] }

# aliases
sub add_matches { goto \&add_match }
sub has_matches { goto \&has_match }

sub run {
    my $self = shift;
    my @args = @_;
    my @matches = $self->matches;
    my @results;

    while (my $match = shift @matches) {
        my $exception;

        try {
            local $SIG{__DIE__} = 'DEFAULT';

            push @results, $match->run(@args);

            # we always stop after the first match UNLESS they explicitly
            # ask to continue on to the next rule
            die "Path::Dispatcher abort\n";
        }
        catch {
            $exception = $_;
        };

        last if $exception =~ /^Path::Dispatcher abort\n/;
        next if $exception =~ /^Path::Dispatcher next rule\n/;

        die $exception;
    }

    return @results if wantarray;
    return $results[0];
}

__PACKAGE__->meta->make_immutable;

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Dispatch - a list of matches

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $dispatcher = Path::Dispatcher->new(
        rules => [
            Path::Dispatcher::Rule::Tokens->new(
                tokens => [ 'attack', qr/^\w+$/ ],
                block  => sub { attack(shift->pos(2)) },
            ),
        ],
    );

    my $dispatch = $dispatcher->dispatch("attack goblin");

    $dispatch->matches;     # list of matches (in this case, one)
    $dispatch->has_matches; # whether there were any matches

    $dispatch->run; # attacks the goblin

=head1 DESCRIPTION

Dispatching creates a C<dispatch> which is little more than a (possibly empty!)
list of matches.

=head1 ATTRIBUTES

=head2 matches

The list of L<Path::Dispatcher::Match> that correspond to the rules that were
matched.

=head1 METHODS

=head2 run

Executes the first match.

Each match's L<Path::Dispatcher::Match/run> method is evaluated in scalar
context. The return value of this method is a list of these scalars (or the
first if called in scalar context).

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
