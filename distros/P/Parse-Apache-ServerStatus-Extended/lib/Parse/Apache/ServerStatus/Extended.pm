package Parse::Apache::ServerStatus::Extended;

use warnings;
use strict;
use Web::Scraper;
use base qw( Parse::Apache::ServerStatus );

our $VERSION = '0.02';
use 5.8.1;

sub parse {
    my $self    = shift;
    my $content = $_[0] ? shift : $self->{content};
    return $self->_raise_error('no content received') unless $content;

    my $table = scraper {
        process 'table[border="0"] tr',
            'rows[]' => scraper {
                process 'td',
                    'values[]' => 'TEXT';
            }
    };

    my @scraped;
    for ( @{ $table->scrape($content)->{rows} } ) {
        next unless $_->{values};
        my $stat = $_->{values};
        push @scraped, {
            srv     => $stat->[0],
            pid     => $stat->[1],
            acc     => $stat->[2],
            m       => $stat->[3],
            cpu     => $stat->[4],
            ss      => $stat->[5],
            req     => $stat->[6],
            conn    => $stat->[7],
            child   => $stat->[8],
            slot    => $stat->[9],
            client  => $stat->[10],
            vhost   => $stat->[11],
            request => $stat->[12],
        };
    }

    return \@scraped;
}

1;
__END__

=head1 NAME

Parse::Apache::ServerStatus::Extended - Simple module to parse apache's extended server-status.


=head1 SYNOPSIS

    use Parse::Apache::ServerStatus::Extended;

    my $parser = Parse::Apache::ServerStatus::Extended->new;

    $parser->request(
       url     => 'http://localhost/server-status',
       timeout => 30
    ) or die $parser->errstr;

    my $stat = $parser->parse or die $parser->errstr;

    # or both in one step

    my $stats = $parser->get(
       url     => 'http://localhost/server-status',
       timeout => 30
    ) or die $parser->errstr;


=head1 DESCRIPTION

This module parses the content of apache's extended server-status.It works nicely with
apache versions 1.3 and 2.x.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Parse::Apache::ServerStatus::Extended object.

=head2 request()

This method accepts one or two arguments: C<url> and C<timeout>. It requests the url
and safes the content into the object. The option C<timeout> is set to 180 seconds if
it is not set.

=head2 parse()

Call C<parse()> to parse the extended server status. This method returns an array reference with
the parsed content.

It's possible to call C<parse()> with the content as an argument.

    my $stat = $prs->parse($content);

If no argument is passed then C<parse()> looks into the object for the content that is
stored by C<request()>.

=head2 get()

Call C<get()> to C<request()> and C<parse()> in one step. It accepts the same options like
C<request()> and returns the array reference that is returned by C<parse()>.

=head1 SEE ALSO

L<Parse::Apache::ServerStatus>

=head1 AUTHOR

Gosuke Miyashita  C<< <gosukenator at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
