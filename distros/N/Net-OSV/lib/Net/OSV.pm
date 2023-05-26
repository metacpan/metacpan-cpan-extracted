use v5.20;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use JSON ();
use HTTP::Tiny;

our $VERSION = '0.0.1';

package Net::OSV {
  sub new ($class) {
    return bless { ua => _build_user_agent() }, $class;
  }

  sub query ($self, %options) {
    my $res = $self->{ua}->request(
      'POST',
      'https://api.osv.dev/v1/query',
      { content => JSON::encode_json(\%options) },
    );
    return $res->{success} ? (JSON::decode_json($res->{content}))->{vulns}->@* : ();
  }

  sub query_batch ($self, @queries) {
    my %options = (queries => \@queries);
    my $res = $self->{ua}->request(
      'POST',
      'https://api.osv.dev/v1/querybatch',
      { content => JSON::encode_json(\%options) },
    );
    return $res->{success} ? (JSON::decode_json($res->{content}))->{results}->@* : ();
  }

  sub vuln ($self, $id) {
    my $res = $self->{ua}->request('GET', 'https://api.osv.dev/v1/vulns/' . $id);
    return $res->{success} ? JSON::decode_json($res->{content}) : undef;;
  }

  sub _build_user_agent {
    return HTTP::Tiny->new(
      agent      => __PACKAGE__ . '/' . $VERSION,
      verify_SSL => 1,
    );
  }
};

1;
__END__

=head1 NAME

Net::OSV - search known vulnerabilities on the Open Source Vulnerabilities Database (OSV)

=head1 SYNOPSIS

    use Net::OSV;

    my $osv = Net::OSV->new;

    my @vulns = $osv->query( commit => '6879efc2c1596d11a6a6ad296f80063b558d5e0f' );

    @vulns = $osv->query(
        package => { ecosystem => 'Debian:10', name => 'imagemagick' },
    );

    say $vulns[0]{details};


=head1 DESCRIPTION

This modules provides a Perl interface to the L<< Open Source Vulnerabilities Database (OSV) | https://osv.dev/ >>, allowing developers to search and retrieve vulnerability and security advisory information from many open source projects and ecosystems.

=head1 METHODS

=head2 new()

    my $osv = Net::OSV->new;

Instantiates a new object.

=head2 query( %options )

Returns a list with the vulnerabilities matching a search criteria.

=over 4

=item * commit - search for a specific commit hash. If specified, version should not be set.

=item * version - version string to query for. A fuzzy match is done against upstream versions. If specified, commit should not be set.

=item * package - a hashref containing any combinations of the keys C<name>, C<ecosystem> and C<purl>and their desired values. You can find the current list of ecosystems L<here|https://ossf.github.io/osv-schema/#affectedpackage-field>.

=back

B<NOTE>: if you use 'commit', you cannot set 'version' (and vice-versa). Also,
the 'package' is optional when you use 'commit'.

Please refer to L<OSV API Specification|https://google.github.io/osv.dev/post-v1-query/> for more information on the search parameters above.

=head2 query_batch( @queries )

    my @vulns = $osv->query_batch(
      { package => { ecosystem => 'Debian:10', name => 'imagemagick' } },
      { package => { ecosystem => 'npm', name => 'm.static' } },
      { package => { name => 'redis' }, version => '4.0.0' },
      { commit  => '6879efc2c1596d11a6a6ad296f80063b558d5e0f' },
    );

Same as C<query()> above, but lets you make several distinct queries at once.
Returns a list of result objects, in the same order of the queries.
B<NOTE> in batch queries, B<only the 'vulnerability id' and 'modified' fields are returned>.

=head2 vuln( $id )

    my $details = $osv->vuln( 'OSV-2020-111' );

Returns vulnerability information related to the given vulnerability id.


=head1 LICENSE AND COPYRIGHT

Copyright 2023- Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This product uses data from the Open Source Vulnerabilities Database (OSV)
but is not endorsed or certified by the OSV.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
