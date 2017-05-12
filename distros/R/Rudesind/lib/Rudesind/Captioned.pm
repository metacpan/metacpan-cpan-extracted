package Rudesind::Captioned;

use strict;

use Class::Roles role => [ qw( has_caption caption save_caption caption_as_html ) ];

use File::Slurp ();
use Rudesind::UI;

sub has_caption
{
    my $self = shift;

    return exists $self->{caption} || -e $self->_caption_file;
}

sub caption
{
    my $self = shift;

    return $self->{caption} if exists $self->{caption};

    return unless $self->has_caption;

    my $file = $self->_caption_file;

    my $caption = File::Slurp::read_file( $file . '' );
    chomp $caption;

    return $self->{caption} = $caption;
}

sub save_caption
{
    my $self = shift;
    my $caption = shift;

    delete $self->{caption};

    my $file = $self->_caption_file;
    if ( defined $caption && length $caption )
    {
        open my $fh, '>', $file
            or die "Cannot write to $file: $!";
        print $fh $caption
            or die "Cannot write to $file: $!";
        close $fh;
    }
    else
    {
        return unless -f $file;

        unlink $file
            or die "Cannot unlink $file: $!";
    }
}

sub caption_as_html
{
    my $self = shift;

    return Rudesind::UI::text_to_html( $self->caption );
}


1;

__END__

=pod

=head1 NAME

Rudesind::Captioned - A role for things with captions

=head1 SYNOPSIS

  use Class::Roles does => 'Rudesind::Captioned';

  $self->caption

=head1 DESCRIPTION

This module provides a role for objects which are captioned, galleries
and images.  Any class that uses it must provide a C<_caption_file()>
method.

It provides the following methods:

=over 4

=item * has_caption

Returns a boolean indicating whether or not the object has an existing
caption.

=item * caption

Returns the object's caption.  Returns a false value if no caption
exists.

=item * save_caption ($caption)

Given a string, this method saves the caption.  If the argument given
is undefined or the empty string, it deletes the object's caption file
entirely.

=item * caption_as_html

Calls C<Rudesind::UI::text_to_html()> to turn the object's caption
into HTML.

=back

=cut
