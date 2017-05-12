package Sub::Way;
use strict;
use warnings;
use parent 'Exporter';

our $VERSION = '0.02';

our @EXPORT_OK = qw/ match /;

sub match {
    my ($target, $cond, $and) = @_;

    if ( ref($cond) eq 'ARRAY' ) {
        if ($and) {
            for my $c (@{$cond}) {
                return unless _match($target, $c);
            }
            return 1;
        }
        else {
            for my $c (@{$cond}) {
                return 1 if _match($target, $c);
            }
        }
    }
    else {
        return 1 if _match($target, $cond);
    }

    return; # not match
}

sub _match {
    my ($target, $cond) = @_;

    if ( !ref($cond) || ref($cond) eq 'Regexp' ) {
        return 1 if $target =~ m!$cond!;
    }
    elsif ( ref($cond) eq 'CODE' ) {
        return 1 if $cond->($target); 
    }

    return;
}

1;

__END__

=head1 NAME

Sub::Way - several ways of matching


=head1 SYNOPSIS

    use Sub::Way qw/match/;

    if ( match($target_text, $condition) ) {
        # do something
    }


=head1 DESCRIPTION

Sub::Way is the matching utility.


=head1 METHOD

=head2 match($target, $condition, $and_opt)

sevelal ways below:

    match('example text', 'amp'); # true
    match('example text', qr/amp/); # true
    match('example text', sub { my $t = shift; return 1 if $t =~ /^amp/; }); # true

    match(
        'example text',
        [
            'amp',
            qr/amp/,
            sub { my $t = shift; return 1 if $t =~ /^amp/; },
        ]
    ); # of course true

    match(
        'example text',
        [
            'yamp', # not match
            qr/amp/,
            sub { my $t = shift; return 1 if $t =~ /^amp/; },
        ],
        1,
    ); # false

By default, the array of condition is evaluated as 'OR'.


=head1 REPOSITORY

Sub::Way is hosted on github: L<http://github.com/bayashi/Sub-Way>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
