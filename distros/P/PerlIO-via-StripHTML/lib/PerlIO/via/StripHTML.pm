package PerlIO::via::StripHTML;

require 5.008;
use strict;
use warnings;
use HTML::Parser 3.00;

our $VERSION = 0.04;

sub PUSHED {
    my ($class, $mode) = @_;
    return -1 if $mode ne 'r';
    # The following variables are updated / accessed via the closures below
    my $buffer = ''; # internal buffer for this layer
    my %inside = ();
    bless {
	buffer => sub : lvalue { $buffer },
	parser => new HTML::Parser(
	    api_version => 3,
	    marked_sections => 1,
	    start_h => [
		sub {
		    $buffer .= "\n"   if $_[0] =~ /^[bt]r$/;
		    $buffer .= "\n\n" if $_[0] eq 'p';
		    ++$inside{$_[0]};
		},
		'tagname',
	    ],
	    end_h => [
		sub { --$inside{$_[0]} },
		'tagname',
	    ],
	    text_h => [
		sub {
		    $buffer .= $_[0] unless $inside{script} || $inside{style};
		},
		'dtext',
	    ],
	),
    }, $class;
}

sub FILL {
    my ($self, $fh) = @_;
    my $line = <$fh>;
    return undef unless defined $line;
    $self->{buffer}->() = '';
    $self->{parser}->parse($line) or return undef;
    $self->{parser}->eof;
    return $self->{buffer}->();
}

1;

__END__

=head1 NAME

PerlIO::via::StripHTML - PerlIO layer to strip HTML tags from an input file

=head1 SYNOPSIS

    use PerlIO::via::StripHTML;
    open my $file, '<:via(StripHTML)', 'foo.html'
	or die "Can't open foo.html: $!\n";

=head1 DESCRIPTION

This package implements a PerlIO layer, for reading files only. It
strips HTML tags from the input, leaving only plain text. This can be
useful, for example, to find something in the text of a HTML page.

=head1 BUGS

This is only a preliminary version.

=head1 SEE ALSO

PerlIO::via

=head1 AUTHOR

Copyright (c) 2002 Rafael Garcia-Suarez. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The HTML stripping code was borrowed from the F<eg/htext> script in the
C<HTML-Parser> distribution.

=cut
