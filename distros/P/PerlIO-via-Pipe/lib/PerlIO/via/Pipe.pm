use 5.008;
use strict;
use warnings;

package PerlIO::via::Pipe;
our $VERSION = '1.100860';
# ABSTRACT: PerlIO layer to filter input through a Text::Pipe
use Exporter qw(import);
our %EXPORT_TAGS = (util => [qw(set_io_pipe)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub set_io_pipe ($) {
    our $pipe = shift;
}

sub PUSHED {
    my ($class, $mode) = @_;
    return -1 if $mode ne 'r';
    my $buf = '';
    bless \$buf, $class;
}

sub FILL {
    my ($self, $fh) = @_;
    my $line = <$fh>;
    return unless defined $line;
    our $pipe;
    $pipe->filter($line);
}
1;


__END__
=pod

=head1 NAME

PerlIO::via::Pipe - PerlIO layer to filter input through a Text::Pipe

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    use PerlIO::via::Pipe 'set_io_pipe';
    use Text::Pipe 'PIPE';

    my $pipe = PIPE('...') | PIPE('...');

    open my $file, '<:via(Pipe)', 'foo.txt'
        or die "can't open foo.txt $!\n";

=head1 DESCRIPTION

This package implements a PerlIO layer for reading files only. It exports, on
request, a function C<set_io_pipe> that you can use to set a L<Text::Pipe>
pipe. If you then use the C<Pipe> layer as shown in the synopsis, the input
gets filtered through the pipe.

=head1 FUNCTIONS

=head2 FILL

FIXME

=head2 PUSHED

FIXME

=head2 set_io_pipe

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PerlIO-via-Pipe>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/PerlIO-via-Pipe/>.

The development version lives at
L<http://github.com/hanekomu/PerlIO-via-Pipe/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

