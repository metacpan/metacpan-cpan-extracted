package Parse::SVNDiff;
$Parse::SVNDiff::VERSION = '0.05';

use 5.008;

use base qw(Class::Tangram);

use Parse::SVNDiff::Window;

use bytes;
use strict;
use warnings;


=head1 NAME

Parse::SVNDiff - Subversion binary diff format parser

=head1 VERSION

This document describes version 0.05 of Parse::SVNDiff, released
January 3, 2006.

=head1 SYNOPSIS

    use Parse::SVNDiff;
    $diff = Parse::SVNDiff->new;
    $diff->parse($raw_svndiff);
    $raw_svndiff = $diff->dump;
    $target_text = $diff->apply($source_text);

    $diff->apply_fh($source_fh, $target_fh);

=head1 DESCRIPTION

This module implements a parser and a dumper for Subversion's
I<svndiff> binary diff format.  The API is still subject to change in
the next few versions.

=head2 Lazy Diffs

If you pass the lazy option to the constructor;

  $diff = Parse::SVNDiff->new( lazy => 1 );

Then the module does not actually parse the diff until you either dump
it or apply it to something.

Note that Lazy Diffs are so lazy that they also forget their contents
after a C<apply> or C<dump> so can't be applied twice.  This is under
the assumption that if you're doing it lazy, you're probably only
going to want to do one of those.

You can also make individual data windows lazy load parts of
themselves; it remains to be seen whether this will see a new
performance improvement or degradation.  The option is;

  $diff = Parse::SVNDiff->new( lazy => 1,
                               lazy_windows => 1,
                             );

Currently you can't use C<lazy_windows> unless the input stream to
C<-E<gt>parse()> is seekable.

=head2 Bitches at the SVN Diff binary format

Each window specifies a "source" offset that is from the beginning of
the file, not a relative position from its last position.  It would be
much better if that was the case, as well as it not being allowed to
be negative.  That way, the "source" data stream would be able to be a
stream and not a seekable file.

This means two things;

=over

=item *

The "source" filehandle in C<apply_fh()> B<must> permit seeking

=item *

Very large window sizes are not currently treated in a lazy fashion;
each window is processed in a chunk.  This limitation is just a matter
of getting more tuits to handle large chunk sizes properly, however.

=back

=cut

our $schema = 
    { fields => { transient => [ qw(fh) ],
		  array => { windows =>
			     { class => 'Parse::SVNDiff::Window' },
			   },
		  int => [ qw(lazy lazy_windows) ] },
    };

sub parse {
    my $self = shift;

    my $fh;
    if (UNIVERSAL::isa($_[0] => 'GLOB')) {
        $fh = $_[0];
    }
    else {
        open $fh, '<', \$_[0];
    }
    binmode($fh);

    local $/ = \4;
    #exception not tested
    <$fh> eq "SVN\0" or die "Svndiff has invalid header";

    $self->set_fh($fh);

    unless ($self->lazy) {
	1 while $self->get_window;
    }

    return $self;
}

sub get_window {
    my $self = shift;
    my $fh   = $self->fh or die "self is :".YAML::Dump($self);
    if (eof($fh)) {
	$self->set_fh(undef);
	return undef;
    }
    my $window = Parse::SVNDiff::Window->new( lazy => $self->lazy_windows );
    if ( $window->parse($fh) ) {
	$self->windows_push($window);
	#push @{$self->{windows}||=[]}, $window;
	return $window;
    }
}

sub next_window {
    my $self = shift;
    if ( $self->lazy ) {
	if ( $self->windows_size ) {
	    return $self->windows_shift; #shift @{$self->{windows}};
	} elsif ( $self->fh ) {
	    $self->get_window unless $self->windows_size; #@{$self->{windows}||=[]};
	    return $self->windows_shift;
	}
    }
    else {
	$self->{_cue} ||= 0;
	return $self->windows($self->{_cue}++);
    }
}

sub dump {
    my $self = shift;
    join '', "SVN\0", map { $_->dump } $self->windows;
}

sub apply {
    my $self   = shift;
    my $source = shift;
    my $target = '';
    open (my $source_fh, "<", \$source) or die $!;
    open (my $target_fh, "+>", \$target) or die $!;

    #kill 2, $$;

    $self->apply_fh($source_fh, $target_fh);
    return $target;
    #seek($target_fh, 0, 0);
    #local($/);
    #return <$target_fh>;
}

sub apply_fh {
    my $self = shift;
    my $source_fh = shift;
    seek($source_fh, 0, 0) or die $!;
    my $target_fh = shift;
    seek($target_fh, 0, 0) or die $!;

    while ( my $window = $self->next_window ) {
	$window->apply_fh($source_fh, $target_fh);
    }
}


=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>

Sam Vilain E<lt>samv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005, 2006 by Audrey Tang, Sam Vilain.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

