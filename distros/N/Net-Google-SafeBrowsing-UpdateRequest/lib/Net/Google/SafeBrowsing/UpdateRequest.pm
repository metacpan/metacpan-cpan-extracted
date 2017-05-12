#   Copyright 2007 Daniel Born <danborn@cpan.org>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

=head1 NAME

Net::Google::SafeBrowsing::UpdateRequest - Update a Google SafeBrowsing table

=head1 SYNOPSIS

  my $u = Net::Google::SafeBrowsing::UpdateRequest->new(
    $apikey, $dbfile, $blocklist);
  if ($u->update and $u->close) {
    print "Successfully updated $blocklist in $dbfile\n";
  }

=head1 DESCRIPTION

The UpdateRequest module updates the local cache of a Google SafeBrowsing URI
table. The cache is stored in a 'DB_File'.

=head1 METHODS

=over

=cut

package Net::Google::SafeBrowsing::UpdateRequest;
use strict;
use warnings;
use fields (
    'apikey',         # Google API key
    'dbfile',         # Path to DB_File with URL hashes
    'blocklist',      # Name of Google blocklist to update
    'reqfile',        # Read /update from a local file (testing)
    'keysfile',       # Read MAC keys froma local file (testing)
    'skip_mac',       # Skip message authentication code verification
    'db',             # Database handle, tied to dbfile
    'tabledata_ref',  # Reference to the table data block
    'mac',            # Message authentication code for this update
);
use LWP::UserAgent;
use English;
use Fcntl;
use Digest::MD5;
use MIME::Base64;
use DB_File;
use Net::Google::SafeBrowsing::Blocklist qw(:all);
our $VERSION = '1.06';

=item Net::Google::SafeBrowsing::UpdateRequest->new($apikey, $dbfile,
    $blocklist, $reqfile, $keysfile, $skip_mac)

Create an UpdateRequest for the specified table.

=over

=item $apikey

API key from Google.

=item $dbfile

Path to place to store the results.

=item $blocklist

Name of URI table to update.

=item $reqfile

Optional. If specified, read an update from a local text file rather than
downloading one from Google (mostly for testing).

=item $keysfile

Optional. If specified, read a /getkeys result from a local file (mostly for
testing).

=item $skip_mac

Optional. If true, skip MAC verification.

=back

=cut

sub new {
  my ($class, $apikey, $dbfile, $blocklist, $reqfile, $keysfile, $skip_mac) = @_;
  my Net::Google::SafeBrowsing::UpdateRequest $self = fields::new(
      ref $class || $class);
  $self->{apikey} = $apikey;
  $self->{dbfile} = $dbfile;
  $self->{blocklist} = $blocklist;
  $self->{reqfile} = $reqfile;
  $self->{keysfile} = $keysfile;
  $self->{skip_mac} = $skip_mac;
  my %db;
  tie %db, 'DB_File', $dbfile, O_RDWR|O_CREAT, 0666, $DB_HASH
    or die "Cannot open db file '$dbfile': $!";
  if (not defined($db{$MAJORVERSION})) {
    $db{$MAJORVERSION} = 1;
  }
  if (not defined($db{$MINORVERSION})) {
    $db{$MINORVERSION} = -1;
  }
  $self->{db} = \%db;
  return $self;
}

sub get_local_file {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my ($file) = @_;
  if (not sysopen(FH, $file, O_RDONLY)) {
    warn "open $file: $!";
    return undef;
  }
  my $content;
  {
    local $/ = undef;
    $content = <FH>;
  }
  close(FH);
  return \$content;
}

sub get_remote_content {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my ($uri) = @_;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(60);
  $self->{db}->{$LASTATTEMPT} = time();
  my $resp = $ua->get($uri);
  if ($resp->is_success) {
    $self->{db}->{$ERRORS} = 0;
    return $resp->content_ref;
  } else {
    ++$self->{db}->{$ERRORS};
    warn "Request for '$uri' failed: ", $resp->status_line,
      ", error count: ", $self->{db}->{$ERRORS};
    return undef;
  }
}

sub get_keys {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my $content_ref;
  if ($self->{keysfile}) {
    l("Getting keys from local file ", $self->{keysfile});
    if (not ($content_ref = $self->get_local_file($self->{keysfile}))) {
      return 0;
    }
  } elsif (not ($content_ref = $self->get_remote_content(
       'https://sb-ssl.google.com/safebrowsing/getkey?client=api'))) {
    warn "/getkey request failed";
    return 0;
  }
  if (not $self->parse_getkey($content_ref)) {
    return 0;
  }
  return 1;
}

=item $u->update

Attempt to update the blocklist.

=cut

sub update {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my $now = time();
  my $errs = $self->{db}->{$ERRORS} || 0;
  my $last = $self->{db}->{$LASTATTEMPT} || 0;
  my $sincelast = $now - $last;
  if (($errs >= 5 and $sincelast < 360 * 60) or
      ($errs == 4 and $sincelast < 180 * 60) or
      ($errs == 3 and $sincelast < 60 * 60) or
      ($errs >= 1 and $sincelast < 60)) {
    warn "Too many failures: $errs. Last attempt: $last.";
    return 0;
  }
  my $wrkey = '';
  if (not $self->{skip_mac}) {
    if (not ($self->{db}->{$CLIENTKEY} and $self->{db}->{$WRAPPEDKEY})) {
      if (not $self->get_keys) {
        return 0;
      }
    }
    $wrkey .= '&wrkey=' . $self->{db}->{$WRAPPEDKEY};
  }
  my $content_ref;
  if ($self->{reqfile}) {
    l("Getting update from local file ", $self->{reqfile});
    if (not ($content_ref = $self->get_local_file($self->{reqfile}))) {
      return 0;
    }
  } elsif (not ($content_ref = $self->get_remote_content(
        sprintf('http://sb.google.com/safebrowsing/update?client=api' .
                '&apikey=%s&version=%s:%d:%d%s',
                $self->{apikey}, $self->{blocklist},
                $self->{db}->{$MAJORVERSION},
                $self->{db}->{$MINORVERSION}, $wrkey)))) {
    warn "/update request failed";
    return 0;
  }
  if (${$content_ref} =~ /^\s*pleaserekey:/i) {
    if (not $self->get_keys) {
      return 0;
    }
  }
  if (not $self->parse_update($content_ref)) {
    warn "Failed to parse response: '${$content_ref}'";
    return 0;
  }
  if (not $self->{skip_mac} and $self->{tabledata_ref}) {
    if (not defined($self->{mac})) {
      warn "No MAC returned";
      return 0;
    }
    my $digest;
    if (not $self->check_mac($self->{db}->{$CLIENTKEY},
                             $self->{tabledata_ref}, $self->{mac}, \$digest)) {
      warn "MAC does not match, digest: '", $digest, "', MAC: '",
        $self->{mac}, "'";
      return 0;
    }
  }
  $self->{db}->{$TIMESTAMP} = time();
  return 1;
}

sub check_mac {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my ($clientkey, $tabledata_ref, $expected, $actual_ref) = @_;
  my $sep = ':coolgoog:';
  my $data = $clientkey . $sep . ${$tabledata_ref} . $sep . $clientkey;
  ${$actual_ref} = Digest::MD5::md5_base64($data) . '==';
  return ${$actual_ref} eq $expected;
}

sub parse_getkey {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my ($content_ref) = @_;
  my $got = 0;
  foreach my $line (split(/[\n\r]+/, ${$content_ref})) {
    if ($line =~ /^\s*clientkey:(\d+):(.+)$/i) {
      $self->{db}->{$CLIENTKEY} = MIME::Base64::decode_base64(
          substr($2, 0, int($1)));
      ++$got;
    } elsif ($line =~ /^\s*wrappedkey:(\d+):(.+)$/i) {
      $self->{db}->{$WRAPPEDKEY} = substr($2, 0, int($1));
      ++$got;
    }
  }
  if ($got < 2) {
    warn "Failed to parse /getkey response";
    return 0;
  }
  return 1;
}

# This modifies ${$content_ref}.
sub parse_update {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my ($content_ref) = @_;
  if (${$content_ref} =~ /^\s*$/) {
    # Empty response if there are no updates.
    return 1;
  }
  # Parse header line.
  if (${$content_ref} !~ s/^\s*\[\s*(\S+)\s+(\d+)\.(\d+)(\s+update)?\s*\]//i) {
    warn "Failed to parse header";
    return 0;
  }
  my $postmatch = $POSTMATCH;
  my $blocklist = $1;
  if ($blocklist ne $self->{blocklist}) {
    warn "Got wrong blocklist: '$blocklist', expected: '",
      $self->{blocklist}, "'";
    return 0;
  }
  my $is_replacement = not defined($4);
  if ($is_replacement) {
    $self->clear_table;
  }
  $self->{db}->{$MAJORVERSION} = int($2);
  $self->{db}->{$MINORVERSION} = int($3);
  if ($postmatch =~ /^\s*\[(.+?)\]/) {
    # Parse optional key=value pairs.
    my $opts = $1;
    foreach my $kvp (split(/\s+/, $opts)) {
      my ($key, $value) = split(/=/, $kvp, 2);
      if (lc($key) eq 'mac') {
        $self->{mac} = $value;
        last; # mac is the only recognized key.
      }
    }
  }
  # Delete until end of header line's \n.
  ${$content_ref} =~ s/^.*[\n\r]+//;
  # Delete blank line after the end of the table data.
  if (${$content_ref} =~ /[\n\r]{2}$/) {
    ${$content_ref} =~ s/[\n\r]$//;
  }
  $self->{tabledata_ref} = $content_ref;
  foreach my $line (split(/[\n\r]+/, ${$content_ref})) {
    if ($line =~ /^\s*([+-])(\S+)/) {
      my $key = pack('H32', $2);
      if ($1 eq '+') {
        $self->{db}->{$key} = '';
      } else {
        delete $self->{db}->{$key};
      }
    }
  }
  return 1;
}

sub clear_table {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  my %special;
  foreach my $k (@SPECIAL_KEYS) {
    $special{$k} = $self->{db}->{$k};
  }
  undef(%{$self->{db}});
  %{$self->{db}} = %special;
}

=item $u->close

Close the $dbfile.

=cut

sub close {
  my Net::Google::SafeBrowsing::UpdateRequest $self = shift;
  if (not untie($self->{db})) {
    warn "Failed to untie '", $self->{dbfile}, "': $!";
    return 0;
  }
  return 1;
}

sub l {
#print STDERR @_, "\n";
}

=back

=cut


1;

