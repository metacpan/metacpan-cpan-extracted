package Pushmi;
use strict;
use version; our $VERSION = qv(1.0.0);

1;

=head1 NAME

Pushmi - Subversion repository replication tool

=head1 SYNOPSIS

  pushmi mirror /var/db/my-local-mirror http://master.repository/svn
  pushmi sync /var/db/my-local-mirror

=head1 DESCRIPTION

Pushmi provides a mechanism for bidirectionally synchronizing
Subversion repositories.  The main difference between Pushmi and
other replication tools is that Pushmi makes the "slave" repositories
writable by normal Subversion clients.

=head1 CONFIGURATION

=over

=item Install and run memcached

We use memcached for better atomic locking for mirrors, as the
subversion revision properties used for locking in SVK is insufficient
in terms of atomicity.

You need to start memcached on the C<authproxy_port> port specified in
pushmi.conf.  For exmaple:

  memcached -p 7123 -dP /var/run/memcached.pid

=item Set up your local repository

Create F</etc/pushmi.conf> and setup username and password.  See
F<t/pushmi.conf> for example.

  pushmi mirror /var/db/my-local-mirror http://master.repository/svn

=item Bring the mirror up-to-date.

  pushmi sync --nowait /var/db/my-local-mirror

Configure a cron job to run this command every 5 minutes.

=item Configure your local svn

Set up your svn server to serve F</var/db/my-local-mirror> at
C<http://slave.repository/svn>

=back

For your existing Subversion checkouts, you may now switch to the slave 
using this command:

  svn switch --relocate http://master.repository/svn http://slave.repository/svn

From there, you can use normal C<svn> commands to work with your checkout.

=item Setup auto-verify

You can optionally enable auto-verify after every commit by setting
revision property C<pushmi:auto-verify> on revision 0 for the
repository, Which can also be done with:

  pushmi verify --enable /path/to/repository

You will also need to specify the full path of F<verify-mirror>
utility in the C<verify_mirror> configuration option.

When the repository is in inconsistent state, users will be advised to
switch back to the master repository when trying to commit.  The
inconsistent state is denoted by the C<pushmi:inconsistent> revision
property on revision 0, and can be cleared with:

  pushmi verify --correct /path/to/repository

=head1 AUTHENTICATION

The above section describes the minimum setup without authentication
and authorisation.

=over

=item For svn:// access

You can we svn:// access for Pushmi, but there are some limitations
for it as of the current implementation.  First of all it will have to
be using the shared credential when committing to the master.  So you
will need to make sure the user is allowed to write to the master.
And as a side-effect, the commits via the slave will be committed by
the shared user on the master.  You can however use some post-commit
hook or other means to set the C<svn:author> revision property
afterwards.  You will need to make sure C<use_shared_commit> is
enabled, and if you are using svn+ssh://, make sure the user pushmi
runs as has the correct ssh key to commit to the master.

=item For authz_svn-controlled master repository

You need to use an external mechanism to replicate the authz file and
add a C<AuthzSVNAccessFile> directive in the slave's slave
C<httpd.conf>, along with whatever authentication modules and
configurations.  You will need additional directives in C<httpd.conf>
using mod_perl2:

  # replace with your auth settings
  AuthName "Subversion repository for projectX"
  AuthType Basic
  Require valid-user
  # here are the additional config required for pushmi
  PerlSetVar PushmiConfig /etc/pushmi.conf
  PerlAuthenHandler Pushmi::Apache::AuthCache

=item For public-read master repository

You can defer the auth* to the master on write.  Put the additional
config in C<httpd.conf>:

  PerlSetVar SVNPath /var/db/my-local-mirror
  PerlSetVar Pushmi /usr/local/bin/pushmi
  PerlSetVar PushmiConfig /etc/pushmi.conf

  PerlLoadModule Apache::AuthenHook # for apache 2.2

  <LimitExcept GET PROPFIND OPTIONS REPORT>
    AuthName "Subversion repository for projectX"
    AuthType Basic
    Require valid-user
    # for apache 2.0
    PerlAuthenHandler Pushmi::Apache::AuthCommit
    # for apache 2.2
    AuthBasicProvider Pushmi::Apache::RelayProvider
  </LimitExcept>

=back

=head1 CONFIG FILE

C<pushmi> looks for F</etc/pushmi.conf> or wherever C<PUSHMI_CONFIG>
in environment points to.  Available options are:

=over

=item username

The credential to use for mirroring.

=item password

The credential to use for mirroring.

=item authproxy_port

The port memcached is running on.

=item use_cached_auth

If pushmi should use the cached subversion authentication info.

=item use_shared_commit

Use the C<username> and C<password> for committing to master.

=item verify_mirror

Path to verify-mirror.

=back

Some mirror-related options are configurable in svk, in your
F<~/.subversion/config>'s C<[svk]> section:

=over

=item ra-pipeline-delta-threshold

The size in bytes that pipelined sync should leave the textdelta in a
tempfile.  Default is 2m.

=item ra-pipeline-buffer

The max number of revisions that pipelined sync should keep in memory
when it is still busy writing to local repository.

=back

=head1 LOGGING

C<pushmi> uses L<Log::Log4perl> as logging facility.  Create
F</etc/pushmi-log.conf>.  See F<t/pushmi-log.t> as exmaple.  See also
L<Log::Log4perl::Config> for complete reference.

=head1 LICENSE

Copyright 2006-2007 Best Practical Solutions, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 SUPPORT

To inquire about commercial support, please contact sales@bestpractical.com.

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@bestpractical.com<gt>

=cut
