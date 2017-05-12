package Term::ProgressBar::IO;
use strict;
use warnings;

our $VERSION = '2.17';

#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
# Copyright 2014 by Don Armstrong <don@donarmstrong.com>.

=head1 NAME

Term::ProgressBar::IO -- Display a progress bar while reading from a seekable filehandle

=head1 SYNOPSIS

  my $pb = Term::ProgressBar::IO->new($fh);

  while (<$fh>) {
      # do something
      $pb->update();
  }

=head1 DESCRIPTION

Displays a progress bar using L<Term::ProgressBar> which corresponds
to reading from a filehandle.

This module inherits from L<Term::ProgressBar> and has all of its
options.

=head1 BUGS

None known.

=cut

use parent qw(Term::ProgressBar);
use Carp;
use Fcntl qw(:seek);

=head1 METHODS

=head2 new

Create and return a new Term::ProgressBar::IO instance.

=over

=item ARGUMENTS

=over

=item count

A valid filehandle or item count. L<IO::Uncompress> filehandles are
also properly handled.

=item OTHER ARGUMENTS

All other arguments are documented in L<Term::ProgressBar>

=back

=back

=cut

sub init {
    my $self = shift;
    my $count;
    if (@_==2) {
        $count = $_[1];
    } else {
        croak
            sprintf("Term::ProgressBar::IO::new We don't handle this many arguments: %d",
                    scalar @_)
            if @_ != 1;
    }
    my %config;
    if ( UNIVERSAL::isa ($_[0], 'HASH') ) {
        ($count) = @{$_[0]}{qw(count)};
        %config = %{$_[0]};
    } else {
        ($count) = @_;
    }
    if (ref($count) and $count->can("seek")) {
        $self->{__filehandle} = $count;
        $count = $self->__determine_max();
    }
    $config{count} = $count;
    $self->SUPER::init(\%config);
}

=head2 update

Automatically update the progress bar based on the position of the
filehandle given at construction time.

=over

=item ARGUMENTS

=over

=item so_far

Current progress point; this defaults to the current position of the
filehandle. [You probably don't actually want to ever give this.]

=back

=back

=cut

sub update {
    my $self = shift;
    my $count = $self->__determine_count();
    $self->SUPER::update(scalar @_? @_ : $count);
}

sub __determine_max {
    my $self = shift;
    # is this an IO::Uncompress handle?
    my $max = 0;
    if ($self->{__filehandle}->can('getHeaderInfo')) {
        $self->{__filehandle} = *$self->{__filehandle}{FH};
    }
    eval {
        my $cur_pos = $self->{__filehandle}->tell;
        $self->{__filehandle}->seek(0,SEEK_END);
        $max = $self->{__filehandle}->tell;
        $self->{__filehandle}->seek($cur_pos,SEEK_SET);
    };
    return $max;
}

sub __determine_count {
    my $self = shift;
    my $count = 0;
    eval {
        $count = $self->{__filehandle}->tell;
    };
    return $count;
}

1;


__END__






