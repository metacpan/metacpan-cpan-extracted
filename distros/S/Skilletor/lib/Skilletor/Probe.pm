package Skilletor::Probe;
# ABSTRACT: The probe of `skilletor add` for a generic host – git ls-remote, then a HEAD on the tarball

use strict;
use warnings;

use Exporter qw( import );
use HTTP::Tiny;
use Skilletor::FSUtil qw( encode_text );
use Skilletor::GitEnv qw( git_env );
use Skilletor::Process qw( run_command );
use Skilletor::URL qw( parse_url );

our $VERSION = '0.008000';

our @EXPORT_OK = qw( make_probe );

use constant TIMEOUT_MS => 5_000;

# The headers Node's fetch sends with a HEAD (as Skilletor::Source::Url's requests carry them),
# so a host answers the probe as it answers the reference's.
my %FETCH_HEADERS = (
  accept            => '*/*',
  'accept-language' => '*',
  'sec-fetch-mode'  => 'cors',
  'accept-encoding' => 'gzip, deflate',
);

sub make_probe {
  my ( %args ) = @_;
  my $timeout_ms = $args{timeout_ms} // TIMEOUT_MS;
  my $http = $args{http}
    // HTTP::Tiny->new( agent => 'node', timeout => $timeout_ms / 1000, verify_SSL => 1, max_redirect => 20 );
  return sub {
    my ( $base ) = @_;
    return { git => 1 } if _ls_remote( $base, $timeout_ms );
    return { tarball => 1 } if _head_ok( $http, $base.'.tar.gz' );
    return {};
  };
}

# Does git list the address's refs within the timeout? The address goes after `--`, never an
# option (k85); git runs in git's environment, never steered by an exported GIT_DIR (k91).
sub _ls_remote {
  my ( $url, $timeout_ms ) = @_;
  my $r = eval {
    run_command( cmd => [ 'git', 'ls-remote', '--', encode_text($url) ], env => git_env(), timeout_ms => $timeout_ms );
  };
  return $r && !$r->{timed_out} && !$r->{spawn_error} && defined $r->{code} && $r->{code} == 0 ? 1 : 0;
}

# Does a HEAD on the URL answer 2xx, redirects followed? What fetch refuses to send – no URL to
# `new URL`, another scheme than http(s), credentials in the URL – is no answer; the URL goes
# out as fetch sends it (the host IDNA-encoded, the path percent-encoded, no fragment).
sub _head_ok {
  my ( $http, $url ) = @_;
  my $u = parse_url($url);
  return 0 unless $u && $u->{protocol} =~ /\Ahttps?:\z/ && $u->{username} eq '' && $u->{password} eq '';
  my $href = $u->{protocol}.'//'.$u->{hostname}.( length $u->{port} ? ':'.$u->{port} : '' ).$u->{pathname}.$u->{search};
  my $res = eval { $http->request( 'HEAD', encode_text($href), { headers => {%FETCH_HEADERS} } ) };
  return $res && $res->{success} ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Probe - The probe of `skilletor add` for a generic host – git ls-remote, then a HEAD on the tarball

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Probe qw( make_probe );
  use Skilletor::Spec qw( resolve_spec );

  my $r = resolve_spec( 'skills.example.org/team', make_probe() );
  # { kind => 'git', value => 'https://skills.example.org/team', ... } when git answers there,
  # { kind => 'url', value => 'https://skills.example.org/team.tar.gz', ... } when the tarball does

=head1 DESCRIPTION

The reference's F<src/probe.ts> (spec §4.2): what C<skilletor add> asks a
generic host – a C<host.tld[/path]> spec – before it writes the source. First
C<git ls-remote -- E<lt>urlE<gt>>, no shell, in L<Skilletor::GitEnv>'s
environment, stdin on F</dev/null>, ended after the timeout; then a C<HEAD> on
C<< E<lt>urlE<gt>.tar.gz >>, which counts when it answers 2xx after up to 20
redirects. Neither is an error: the probe answers what it found, and
L<Skilletor::Spec/resolve_spec> words the refusal.

The C<HEAD> runs in this process through L<HTTP::Tiny> (TLS through
L<IO::Socket::SSL>, certificates verified), where the reference starts a short
Node child for it – a packed binary needs no other program than C<git>. Its
timeout is L<HTTP::Tiny>'s, per connect and read, not one for the whole request.

=head2 make_probe

  my $probe = make_probe();
  my $probe = make_probe( timeout_ms => 5000, http => HTTP::Tiny->new(...) );

A code reference for L<Skilletor::Spec/resolve_spec>: called with the base URL,
it returns C<< { git => 1 } >>, C<< { tarball => 1 } >> or C<{}>.
C<timeout_ms> (default 5000) bounds the C<ls-remote> and is the C<HEAD>'s
timeout; C<http> replaces the L<HTTP::Tiny> agent, for a test.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
