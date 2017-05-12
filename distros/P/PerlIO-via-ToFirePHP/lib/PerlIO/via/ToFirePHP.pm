use 5.008;
use strict;
use warnings;

package PerlIO::via::ToFirePHP;
our $VERSION = '1.100860';
# ABSTRACT: log to FirePHP via an PerlIO layer

sub PUSHED {
    my ($class, $mode, $fh) = @_;
    return -1 unless $mode eq 'w';
    bless { buf => '', }, $class;
}

sub OPEN {
    my ($self, $path, $mode, $fh) = @_;

    # $path is actually our FirePHP::Dispatcher object
    $self->{fire_php} = $path;
    1;
}

sub WRITE {
    my ($self, $buf, $fh) = @_;

    # accumulate whole lines before logging
    $self->{buf} .= $buf;
    if ($self->{buf} =~ tr/\n//) {
        $self->{fire_php}->log($self->{buf});

        # finalize now in case CLOSE() doesn't get called; it's idempotent
        $self->{fire_php}->finalize;
        $self->{buf} = '';
    }
    length $buf;
}

sub CLOSE {
    my $self = shift;
    $self->{fire_php}->finalize;
    0;
}
1;


__END__
=pod

=head1 NAME

PerlIO::via::ToFirePHP - log to FirePHP via an PerlIO layer

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    use PerlIO::via::ToFirePHP;
    my $fire_php = FirePHP::Dispatcher->new(HTTP::Headers->new);
    open my $fh, '>:via(ToFirePHP)', $fire_php;
    # Everything you print on the filehandle will be sent to FirePHP

=head1 DESCRIPTION

This PerlIO layer sends everything it receives to FirePHP. When constructing a
filehandle using this layer using C<open()>, you need to pass an object of
type L<FirePHP::Dispatcher> that has been initialized with a L<HTTP::Headers>
object.

A typical use of this PerlIO layer is to send L<DBI> trace output to FirePHP:

    use PerlIO::via::ToFirePHP;

    my $dbh = DBI->connect(...);

    open my $fh, '>:via(ToFirePHP)',
        FirePHP::Dispatcher->new($http_headers_object);
    $dbh->trace(2, $fh);

Now the trace output of all calls to that database handle will be sent to
FirePHP.

The PerlIO layer is implemented in C<PerlIO::via::ToFirePHP> instead of just
C<PerlIO::via::FirePHP> because of a bug in C<PerlIO::via> in perl 5.10.0 and
earlier versions. If we used just C<PerlIO::via::FirePHP>, we would not be
able to use the shorthand layer notation of C<open my $fh, ':>via(FirePHP),
$fire_php>. C<PerlIO::via> would look for a C<PUSHED> method in package
C<FirePHP>. There is no such method, but because C<FirePHP::Dispatcher> has
been loaded, the namespace C<FirePHP> has been autovivified. So C<PerlIO::via>
would stop looking. This bug seems to be fixed in perl 5.10.1.

=head1 METHODS

=head2 PUSHED

Called by L<PerlIO::via> - read its documentation for details.

=head2 OPEN

Called by L<PerlIO::via> - read its documentation for details.

=head2 WRITE

Called by L<PerlIO::via> - read its documentation for details.

C<WRITE()> accumulates input until a newline is seen, only then will it remove
the newline and send the accumulated input to the L<FirePHP::Dispatcher>
object. The motivation for this was that L<DBI>'s C<trace()> method reports
trace output in chunks, not necessarily whole lines.

=head2 CLOSED

Called by L<PerlIO::via> - read its documentation for details.

=head1 SEE ALSO

=over 4

=item L<HTTP::Engine::FirePHP>

The C<get_fire_php_fh()> method it places in L<HTTP::Engine::Response> returns
a filehandle constructed with PerlIO::via::ToFirePHP.

=item L<PerlIO::via>

See this module for how to implement PerlIO layers in Perl.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PerlIO-via-ToFirePHP>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/PerlIO-via-ToFirePHP/>.

The development version lives at
L<http://github.com/hanekomu/PerlIO-via-ToFirePHP/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

