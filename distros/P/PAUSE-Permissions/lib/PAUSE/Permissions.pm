package PAUSE::Permissions;
$PAUSE::Permissions::VERSION = '0.17';
use strict;
use warnings;

use Moo;
use PAUSE::Permissions::Module;
use PAUSE::Permissions::ModuleIterator;
use PAUSE::Permissions::EntryIterator;
use File::HomeDir;

use File::Spec::Functions qw/ catfile  /;
use HTTP::Date            qw/ time2str / ;
use Carp                  qw/ croak    /;
use Time::Duration::Parse qw/ parse_duration /;

use HTTP::Tiny;

my $DISTNAME                        = 'PAUSE-Permissions';
my $BASENAME                        = '06perms.txt';
my $DEFAULT_PERMISSION_REQUESTED    = 'upload';

has 'url' =>
    (
     is      => 'ro',
     default => sub { return 'http://www.cpan.org/modules/06perms.txt'; },
    );

has 'path'         => (is => 'ro' );
has 'cache_path'   => (is => 'lazy' );
has 'max_age'      => (is => 'ro');
has 'preload'      => (is => 'ro', default => sub { 0 });
has 'module_cache' => (is => 'lazy');

sub _build_cache_path
{
    my $self     = shift;

    my $basename = $self->url;
       $basename =~ s!^.*[/\\]!!;
    my $classid  = ref($self);
       $classid  =~ s/::/-/g;

    return catfile(File::HomeDir->my_dist_data( $classid, { create => 1 } ), $basename);
}

sub _build_module_cache
{
    my $self     = shift;
    my $iterator = $self->module_iterator;
    my $cache    = {};

    while (my $module = $iterator->next_module) {
        $cache->{ $module->name } = $module;
    }

    return $cache;
}

sub BUILD
{
    my $self = shift;

    if ($self->path) {
        return if -f $self->path;
        croak "the file you specified with 'path' doesn't exist";
    }

    # If we already have a locally cached copy, and the max_age was specified,
    # then check if our cache has expired
    if (-f $self->cache_path && $self->max_age) {
        my $max_age_in_seconds = parse_duration($self->max_age);
        return unless time() - $max_age_in_seconds > (stat($self->cache_path))[9];
    }

    $self->_cache_file_if_needed();
}

sub _cache_file_if_needed
{
    my $self    = shift;
    my $options = {};
    my $ua      = HTTP::Tiny->new();

    if (-f $self->cache_path) {
        $options->{'If-Modified-Since'} = time2str( (stat($self->cache_path))[9]);
    }
    my $response = $ua->get($self->url, $options);

    return if $response->{status} == 304; # Not Modified

    if ($response->{status} == 200) {
        $self->_transform_and_cache($response);
        return;
    }

    croak("request for 06perms.txt failed: $response->{status} $response->{reason}");
}

sub _transform_and_cache
{
    my ($self, $response) = @_;
    my $inheader = 1;
    my @lines;

    LINE:
    while ($response->{content} =~ m!^(.*)$!gm) {
        my $line = $1;
        if ($line =~ /^$/ && $inheader) {
            $inheader = 0;
            next;
        }
        next LINE if $inheader;
        my ($package, $user, $perm) = split(/,/, $1);
        push(@lines, [lc($package), lc($user), $package, $user, $perm]);
    }

    open(my $fh, '>', $self->cache_path);
    print $fh <<'END_HEADER';
File: PAUSE Permissions data
Format: 2
Source: CPAN/modules/06perms.txt

END_HEADER

    foreach my $line (sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @lines) {
        printf $fh "%s,%s,%s\n", (@$line)[2,3,4];
    }

    close($fh);
}

sub entry_iterator
{
    my $self = shift;

    return PAUSE::Permissions::EntryIterator->new( permissions => $self );
}

sub module_iterator
{
    my $self = shift;

    return PAUSE::Permissions::ModuleIterator->new( permissions => $self );
}

sub open_file
{
    my $self     = shift;
    my $filename = defined($self->path) ? $self->path : $self->cache_path;
    open(my $fh, '<', $filename) || croak "can't open $filename: $!";
    return $fh;
}

sub can_upload
{
    my ($self, $pause_id, $module_name) = @_;
    my $PAUSE_ID                        = uc($pause_id);
    my $mp                              = $self->module_permissions($module_name);

    return 1 unless defined($mp);

    return !! grep { $PAUSE_ID eq $_ } $mp->all_maintainers;
}

my %known_permission_types =
(
    'upload'  => 'author can upload (either owner or comaint)',
    'owner'   => 'author is the owner of the package',
    'comaint' => 'author has comaint but is not the owner',
);

sub has_permission_for
{
    my $self    = shift;
    my $author  = shift;
    my $what    = @_ > 0 ? shift : $DEFAULT_PERMISSION_REQUESTED;
    my $cache   = $self->module_cache // croak "module cache is undef\n";
    my $AUTHOR  = uc($author);
    my $matches = [];
    local $_;

    foreach my $module (values %{ $self->module_cache }) {
        push(@$matches, $module->name) if ($what eq 'upload' && grep { $_ eq $AUTHOR } $module->all_maintainers)
                                       || ($what eq 'owner'  && defined($module->owner) && $module->owner eq $AUTHOR)
                                       || ($what eq 'comaint' && grep { $_ eq $AUTHOR } $module->co_maintainers);
    }
    return [map { $_->[1] } sort { $a->[0] cmp $b->[0] } map { [lc($_),$_] } @$matches];
}

sub module_permissions
{
    my $self   = shift;
    my $module = shift;
    my $fh;
    local $_;
    my $inheader = 1;
    my $seen_module = 0;
    my %perms;
    my ($m, $u, $p);

    if ($self->preload && $self->module_cache) {
        return $self->module_cache->{$module} // undef;
    }

    $fh = $self->open_file();
    while (<$fh>) {
        chomp;
        if ($inheader && /^\s*$/) {
            $inheader = 0;
            next;
        }
        next if $inheader;
        ($m, $u, $p) = split(/,/, $_);
        if (lc($m) eq lc($module)) {
            push(@{ $perms{$p} }, uc($u));
            $seen_module = 1;
        }
        last if $seen_module && lc($m) ne lc($module);
    }
    close($fh);

    if ($seen_module) {
        my @args;
        push(@args, name => $module);
        push(@args, m => $perms{m}->[0]) if exists $perms{m};
        push(@args, f => $perms{f}->[0]) if exists $perms{f};
        push(@args, c => $perms{c})      if exists $perms{c};
        return PAUSE::Permissions::Module->new(@args);
    }

    return undef;
}

1;

=head1 NAME

PAUSE::Permissions - interface to PAUSE's module permissions file (06perms.txt)

=head1 SYNOPSIS

  use PAUSE::Permissions 0.08;
  
  my $pp = PAUSE::Permissions->new(max_age => '1 day');
  my $mp = $pp->module_permissions('HTTP::Client');
  
  my $owner    = $mp->owner;
  my @comaints = $mp->co_maintainers;

  my $iterator = $pp->module_iterator();
  while (my $mp = $iterator->next_module) {
    print "module = ", $mp->name, "\n";
    print "  owner = ", $mp->owner // 'none', "\n";
  }

=head1 DESCRIPTION

PAUSE::Permissions provides an interface to the C<06perms.txt> file produced by
the Perl Authors Upload Server (PAUSE).
The file records who has what permissions for every module on CPAN.
The format and interpretation of this file
are covered in L</"The 06perms.txt file"> below.

By default, the module will mirror C<06perms.txt> from CPAN,
using L<HTTP::Tiny> to request it and store it locally
What gets cached locally is actually a transformed version of 06perms.txt
for easier processing.

By default it will get the file from L<http://www.cpan.org>, but you can
pass an alternate URI to the constructor:

  $perms_uri = "http://$CPAN_MIRROR/modules/06perms.txt";
  $pp = PAUSE::Permissions->new(uri => $perms_uri);

If you've already got a copy lying around, you can tell the module to use that:

  $pp = PAUSE::Permissions->new( path => '/tmp/my06perms.txt' );

Note that the file you provide this way must be in the post-processed
format, and not a raw copy of C<06perms.txt>.

Having created an instance of C<PAUSE::Permissions>,
you can then call the C<module_permissions> method
to get the permissions for a particular module.
The SYNOPSIS gives the basic usage.

B<Note>: you should make sure you're using version 0.08 or later.
PAUSE now treats package names case insensitively with respect to
permissions, so this module does now as well.

=head2 Getting permissions for multiple modules

Sometimes you might want to use the C<module_permissions()> method
to get permissions for multiple modules, for example if you've built
up a list of modules from elsewhere. If you're doing this, then you
should set the C<preload> attribute to a true value:

 use PAUSE::Permissions 0.12;

 my $pp = PAUSE::Permissions->new(preload => 1);
 foreach my $module_name (@long_list_of_modules) {
    my $mp = $pp->module_permissions($module_name);
    # do something with $mp (instance of PAUSE::Permissions::Module)
 }

With the C<preload> option enabled, the permissions data for I<all>
modules will be pre-loaded into memory, making the above code much
quicker, trading that off against the memory used.

This attribute was introduced in version 0.12, so you should
specify the minimum version when C<use>'ing C<PAUSE::Permission>.

=head1 METHODS

There are only four methods you need to know:
the constructor (C<new>),
getting an iterator over individual entries (C<entry_iterator>),
getting an iterator over modules (C<module_iterator>),
and C<module_permissions()>.

=head2 new

The constructor takes a hash of options:

=over 4

=item *

B<cache_path>: the full path to the location where you'd like
C<PAUSE::Permissions> to cache the transformed version of 06perms.txt.

=item *

B<path>: your own local copy of the file, to use instead of the
version in the C<cache_path>.
Note that this must be in the post-processed format for the local cache,
and not the original raw format of C<06perms.txt>.

The constructor will C<die()> if the file doesn't exist, or isn't readable.

=item *

B<url>: the URL for 06perms.txt;
defaults to L<http://www.cpan.org/modules/06perms.txt>

=item *

B<max_age>: the expiration time for cached data, once C<06perms.txt> has been grabbed.
The age can be specified using any format supported by L<Time::Duration::Parse>,
such '1 day', '2 minutes and 30 seconds', or '02:30:00'.

=item *

B<preload>: load all module permissions data into memory,
to speed up repeated calls to C<module_permissions()>.
This currently (0.12 onwards) doesn't currently affect any
other methods, though it might in a future release.

=back

So you might use the following,
to get C<06perms.txt> from your 'local' CPAN mirror and store it somewhere
of your choosing:

  $pp = PAUSE::Permissions->new(
                uri     => 'http://cpan.inode.at/modules/06perms.txt',
                cachdir => '/tmp/pause',
            );

=head2 module_iterator

This is a method that returns an instance of L<PAUSE::Permissions::ModuleIterator>,
which provides a simple mechanism for iterating over the whole permissions file,
module by module:

  $pp       = PAUSE::Permissions->new();
  $iterator = $pp->module_iterator();
  
  while (my $module = $iterator->next_module) {
    print "module    = ", $module->name,           "\n";
    print "owner     = ", $module->owner,          "\n";
    print "co-maints = ", $module->co_maintainers, "\n";
  }

The C<next_module()> method returns either an instance of L<PAUSE::Permissions::Module>,
or C<undef> when the end of the file is reached.

=head2 entry_iterator

This is a method that returns an instance of L<PAUSE::Permissions::EntryIterator>,
which provides a simple mechanism for iterating over the whole permissions file,
line by line:

  $pp       = PAUSE::Permissions->new();
  $iterator = $pp->entry_iterator();
  while (my $entry = $iterator->next) {
    print "module = ", $entry->module,     "\n";
    print "user   = ", $entry->user,       "\n";
    print "perm   = ", $entry->permission, "\n";
  }

The C<module> method returns a module name;
C<user> returns the PAUSE id of a PAUSE user;
C<perm> is one of the three permission identifiers ('m', 'f', or 'c').

=head2 module_permissions

The C<module_permissions> method takes a single module name,
and returns an instance of L<PAUSE::Permissions::Module>:

  $mp = $pp->module_permissions( $module_name );

Refer to the documentation for L<PAUSE::Permissions::Module>,
but the key methods are:

=over 4

=item *

C<owner()>
returns the PAUSE id of the owner (see L</"The 06perms.txt file"> below),
or C<undef> if there isn't a defined owner.

=item *

C<co_maintainers()>
returns a list of PAUSE ids, or an empty list if the module has no co-maintainers.

=back

C<module_permissions()> returns C<undef>
if the module wasn't found in the permissions list.
If you've only just registered your new module,
or only just uploaded the first release,
then it might not have made it into the file yet.


=head2 can_upload

This method takes a PAUSE id and a module name, and returns true (specifically C<1>)
if the specified user has permission to upload the specified module,
otherwise false (0).

 use PAUSE::Permissions 0.13;
 my $pp = PAUSE::Permissions->new(preload => 1);
 if ($pp->can_upload('NEILB', 'Foo::Bar')) {
     # User can upload package
 }

Having permission to upload a module means that either
(a) the module appears in 06perms.txt and the specified user is one of the entries, or
(b) the module doesn't appear, so we assume it's not on CPAN.

There are some things you should be aware of, when interpreting this:

=over 4

=item * the username is handled case insensitively.

=item * the module name is handled case-insensitively.

=item * if the module is not in C<06perms.txt> then this returns true,
but there is a delay between permissions being assigned by PAUSE and their
appearing in C<06perms.txt>. Also, if you're running with a long C<max_age>
parameter, it might be a while before you see the change anyway.

=item * a user might theoretically have permission to upload a module,
but a specific upload might fail if the distribution doesn't have an
appropriately named I<main module>. If you're not familiar with that restriction,
read this L<blog post|http://www.dagolden.com/index.php/2414/this-distribution-name-can-only-be-used-by-users-with-permission/>.

=back

Note: this method was introduced in version 0.13, so you should specify
this as a minimum version number if you're using the method.

=head2 has_permission_for

This method takes an author's PAUSE id and an optional string which specifies what type of permission
you're interested in. It will return an array ref with all package names for which the
author has the specified permission.

The following example takes a PAUSE id C<NEILB> and determines all modules that NEILB
can upload:

 use PAUSE::Permissions 0.14;
 my $pp = PAUSE::Permissions->new(preload => 1);
 my $ref = $pp->has_permission_for('NEILB', 'upload');
 print "NEILB has upload permission on:\n";
 foreach my $module_name (@$ref) {
    print "  $module_name\n";
 }

There are three different permission types you can request:

=over 4

=item * 'upload' - ability to upload, which means co-maint or owner.

=item * 'owner' - author is the owner of the package.

=item * 'comaint' - author is comaint of the package but not owner.

=back

The package names are returned in case-insensitive alphabetic order.

Note: this method was introduced in version 0.14, so you should specify
this as a minimum version number if you're using the method.


=head1 The 06perms.txt file

You can find the file on CPAN:

=over 4

L<http://www.cpan.org/modules/06perms.txt>

=back

As of October 2012 this file is 8.4M in size.

The file starts with a header, followed by one blank line, then the body.
The body contains one line per module per user:

  Config::Properties,CMANLEY,c
  Config::Properties,RANDY,f
  Config::Properties,SALVA,m

Each line has three values, separated by commas:

=over 4

=item *

The name of a module.

=item *

A PAUSE user id, which by convention is always given in upper case.

=item *

A single character that specifies what permissions the user has with
respect to the module. See below.

=back

Note that this file lists I<modules>, not distributions.
Every module in a CPAN distribution will be listed separately in this file.
Modules are listed in alphabetical order, and for a given module,
the PAUSE ids are listed in alphabetical order.

There are three characters that can appear in the permissions column:

=over 4

=item *

B<C<'m'>> identifies the user as the registered I<maintainer> of the module.
A module can only ever have zero or one user listed with the 'm' permission.
For more details on registering a module,
see L<04pause.html|http://www.cpan.org/modules/04pause.html#namespace>.

=item *

B<C<'f'>> identifies the user as the I<first> person to upload the module to CPAN.
You don't have to register a module before uploading it, and ownership
in this case is first-come-first-served.
A module can only ever have zero or one user listed with the 'f' permission.

=item *

B<C<'c'>> identifies the user as a I<co-maintainer> of the module.
A module can have any number of co-maintainers.

=back

If you first upload a module, you'll get an 'f' against you in the file.
If you subsequently register the module, you'll get an 'm' against you.
Internally PAUSE will have you recorded with both an 'm' and an 'f',
but C<06perms.txt> only lists the highest precedence permission for each user.

=head2 What do the permissions mean?

=over 4

=item *

Various places refer to the 'owner' of the module.
This will be either the 'm' or 'f' permission, with 'm' taking precedence.
If a module has both an 'm' and an 'f' user listed, then the 'm' user
is considered the owner, and the 'f' user isn't.
If a module has a user with 'f' listed, but no 'm', then the 'f' user is
considered the owner.

=item *

If a module is listed in C<06perms.txt>,
then only the people listed (m, f, or c)
are allowed to upload (new) versions of the module.
If anyone else uploads a version of the module,
then the offending I<distribution> will not be indexed:
it will appear in the uploader's directory on CPAN,
but won't be indexed under the module.

=item *

Only the owner for a module can grant co-maintainer status for a module.
I.e. if you have the 'm' permission, you can always do it.
If you have the 'f' permission, you can only do it if no-one else has
the 'm' permission.
You can grant co-maintainer status using the PAUSE web interface.

=item *

Regardless of your permissions, you can only remove things from CPAN that
you uploaded. If you're the owner, you can't delete a version uploaded
by a co-maintainer. If you weren't happy with it, you could revoke their
co-maintainer status and then upload a superseding version. But we'd
recommend you talk to them (first).

=item *

If you upload a distribution containing a number of previously unseen modules,
and haven't pre-registered them,
then you'll get an 'f' permission for all of the modules.
Let's say you upload a second release of the distribution,
which doesn't include one of the modules,
and then delete the first release from CPAN (via the PAUSE web interface).
After some time the module will no longer be on CPAN,
but you'll still have the 'f' permission in 06perms.txt.
You can free up the namespace using the PAUSE interface ("Change Permissions").

=item *

If your first upload of a module is a
L<Developer Release|http://www.cpan.org/modules/04pause.html#developerreleases>,
then you won't get permissions for the module.
You don't get permissions for a module until you've uploaded a non-developer
release containing the module,
that was accepted for indexing.

=item *

If you L<take over|http://www.cpan.org/modules/04pause.html#takeover> maintenance
of a module, then you'll generally be given the permissions of the previous maintainer.
So if the previous maintainer had 'm', then you'll get 'm', and (s)he will be
downgraded to 'c'.
If the previous maintainer had 'f', then you'll get 'f', and the previous owner
will be downgraded to 'c'.

=back

=head1 SEE ALSO

L<App::PAUSE::CheckPerms> checks whether all modules in (your)
CPAN distributions have the same permissions.

C<tmpdir()> in L<File::Spec::Functions> is used to get a local directory for
caching 06perms.txt.

L<HTTP::Tiny> is used to mirror 06perms.txt from CPAN.

=head1 TODO

=over 4

=item *

Request the file gzip'd, if we've got an appropriate module that can be used
to gunzip it.

=item *

At construct time we currently mirror the file;
should do this lazily, triggering it the first time you want a module's perms.

=item *

Every time you ask for a module, I scan the file from the start, then close it
once I've got the details for the requested module. Would be a lot more efficient
to keep the file open and start the search from there, as the file is sorted.
A binary chop on the file would be much more efficient as well.


=item *

A command-line script.

=back

=head1 REPOSITORY

L<https://github.com/neilbowers/PAUSE-Permissions>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

Thanks to Andreas KE<ouml>nig, for patiently answering many questions
on how this stuff all works.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

