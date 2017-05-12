package RADIUS::UserFile;


=head1 NAME

RADIUS::UserFile - Perl extension for manipulating a RADIUS users file.

=head1 SYNOPSIS

  use RADIUS::UserFile;

  my $users = new RADIUS::UserFile 
                  File => '/etc/raddb/users',
                  Check_Items => [ qw(Password Calling-Station-Id) ];

  $users->load('/usr/local/etc/radius/users');
  
  $users->add(Who        => 'joeuser',
              Attributes => { key1 => 'val1', key2 => 'val2' },
              Comment    => 'Created on '. scalar localtime);
    
  $users->update(File => '/etc/raddb/users',
                 Who => qw(joeuser janeuser));

  print $users->format('joeuser');

=head1 REQUIRES

Perl5.004, Fcntl, File::Copy, Tie::IxHash

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

This module provides methods for reading information from and modifying
a RADIUS users text file.

=head2 PACKAGE METHODS

=over 4

=item new RADIUS::UserFile

=item new RADIUS::UserFile(File => I<$USERS_FILE>, Who => I<$USER>,
      Check_Items => [ I<@CHECK_ITEMS> ])

=item new RADIUS::UserFile(File => I<$USERS_FILE>, Who => [ I<@USERS> ],
      Check_Items => [ I<@CHECK_ITEMS> ])

Creates and returns a new C<RADIUS::UserFile> object.

C<File> specifies the RADIUS users file to load (e.g. "/etc/raddb/users").
If no file is specified, one isn't loaded; in this case, the C<load()>
method can be used to retrieve any user data.  If an error occurred while
reading C<File>, 0 is returned instead.

C<Who> limits the retrieval of user information to the list of users
specified.  A single user can be named using a string, or a set of users
can be passed as a reference to an array.  If Who is left undefined, all
users will be loaded.

C<Check_Items> is a reference to a list of attributes that should be
included in the first line of the record.  By default, this list includes:
"Password", "Auth-Type", "Called-Station-Id", "Calling-Station-Id",
"Client-Port-DNIS", and "Expiration".

=back

=head2 OBJECT METHODS

=over 4

=item ->add(Who => I<$USER>, Attributes => I<\%ATTRS>, Comment => I<$TEXT>, Debug => I<level>)

Adds information about the named user.  This information will henceforth
be available through C<users>, C<attributes>, C<comment>, etc.  Any
comments are automatically prefixed with "# ".  C<Attributes> should be
specified as a reference to a hash; each value should either be an array
ref or a string.  On success, 1 is returned.  On error, 0 is returned
and STDERR gets an appropriate message.  The debug level is used by the
C<debug> function described below.

=item ->attributes(I<$USER>)

Returns a list of defined attributes for the specified user.  If the
user doesn't exist, undef is returned.

=item ->comment(I<$USER>)

Returns a string representing the comments that would prefix the given
user's entry in the users file.  If the user doesn't exist, undef is
returned.

=item ->debug(I<level>, I<@messages>)

Prints out the list of strings in I<@messages> if the debug level is >=
I<level>.

=item ->dump(I<$USER>)

Prints out the attributes of the named user, in alphabetical order.
$self is returned.

=item ->files

Returns a list of files from which we have read user attributes.  The list
is sorted according to the order in which the files were read.  If no
files have yet been read successfully, an empty array is returned.

=item ->format(I<$USER>)

Returns a string containing the attributes of the named user, prefixed by
any comments, according to the format required for the RADIUS users file.
If the user doesn't exist, an empty string is returned.

=item ->load(File => I<$USERS_FILE>, Who => I<$USER>)

=item ->load(File => I<$USERS_FILE>, Who => I<\@USERS>)

Loads the contents of the specified RADIUS users file.  The name of the
file is stored in a first-in, last-out stack enumerating which "databases"
have been loaded (see C<files()>).  The C<RADIUS::UserFile> object is
returned.  The options are the same as described in C<new()>.  If a
user already exists and further info is read about that user from the
specified file, the new information is just added to what is already
known.  On success, 1 is returned; on failure, 0 is returned and an
appropriate message is sent to STDERR.

=item ->read_users(I<$USERS_FILE>, I<$USER>)

=item ->read_users(I<$USERS_FILE>, I<\@USERS>)

Reads in the contents of the specified RADIUS users file, and returns
a pair of hashes:  one indexed by user name, with each element containing
a hash of (attribute name => [ values ]) pairs; and another also indexed
by user name, containing the comments that immediately preceded that
user's file entry.  The options are the same as in C<new()>.  Each
comment value is a string.  Each user attribute value is a ref to an
array of strings.  This is mainly designed as a utility function to be
used by C<new()> and C<load()>, and doesn't affect the calling object.
On failure, 0 is returned.

=item ->remove(I<$USER> ...)

Deletes the specified users from the object.  The list of users
successfully deleted is returned.

=item ->removed()

Returns a list of users that have been removed from the object.

=item ->update(File => I<$USERS_FILE>, Who => I<\@USERS>)

Updates user attributes in a RADIUS users file.  If the file is
specified, its contents are updated; otherwise, the last file read is
modified.  If a list of users is provided, only their entries are
updated; otherwise, all known users are.  All users to be "updated"
are printed using the results of C<format>.  Other users are printed
as found.  It should be noted that some extra newlines can be left
in a file with this method:  if an empty line follows a given record
that has been C<remove()>d, then it will still be there in the file
being updated.  On success, non-zero is returned.  On failure, 0 is
returned and STDERR gets an appropriate message.

=item ->user(I<$USER>)

Returns a ref to a hash representing the attributes of the named user.
If the user doesn't exist, undef is returned.

=item ->usernames

Returns a ref to an anonymous array of strings representing the users
about which we have attributes defined.  If no users are defined, a ref
to an empty anonymous array is returned.

=item ->users

Returns a ref to a hash of user hashes, where each user hash is a set of
(attribute name => value) pairs.  This is the actual data stored in the
object, so use with caution.

=item ->values(I<$USER>, I<$ATTRIBUTE>)

Returns an array of strings representing the values for the named
attribute of the given user.  If the user or attribute doesn't exist,
undef is returned.

=back

=head1 AUTHOR

Copyright (c) 2001 O'Shaughnessy Evans <oevans@cpan.org>.
All rights reserved.  This version is distributed under the same
terms as Perl itself (i.e. it's free), so enjoy.

Thanks to Burkhard Weeber, James Golovich, Peter Bannis, and others
for contributions and comments that have improved this software.

=head1 SEE ALSO

L<RADIUS::Packet>, L<RADIUS::Dictionary>, L<Authen::Radius>.

=cut

require 5.004;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::File;
use File::Copy;
use Fcntl qw(:flock);
use Tie::IxHash;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(add attributes comment dump files format load new read_users
                update user usernames users values);

$VERSION = '1.01';

#my $RADIUS_USERS = '/etc/raddb/users';  # default users info file
my $ATTR_MAX = 31;                      # max char len of any attribute name

my %fields = (
    users       => undef,
    removed     => undef,              # cheap hack for remove()
    files       => undef,
    comments    => undef,
    check_items => undef,
    ERROR       => undef,
    DEBUG       => undef
);

# Create, initialize, and return a new RADIUS::UserFile object.
#
sub new
{
    my $me = shift;
    my $class = ref($me) || $me;
    my $self = { %fields };
    bless $self, $class;

    my %args = @_;
    return $self->_initialize(\%args);
}


# Do initial object-creation setup stuff.
# 
sub _initialize
{
    my ($self, $args) = @_;

    if ($args->{Debug}) {
        $self->{DEBUG} = $args->{Debug};
        $| = 1;
    }

    if ($args->{Check_Items}) {
        $self->{check_items} = [ @{$args->{Check_Items}} ];
    }
    else {
	    $self->{check_items} = [ "Password", "Auth-Type",
	                             "Called-Station-Id", "Calling-Station-Id",
                                 "Client-Port-DNIS", "Expiration" ];
    }

    if ($args->{File}) {
        $self->debug(7, "init - loading $args->{File}");
        my ($users, $comments) = $self->read_users($args->{File}, $args->{Who});
        return 0 unless defined $comments and defined $users;

        if ($users) {
            @{$self->{users}}{keys %$users} = values %$users;
            @{$self->{comments}}{keys %$comments} = values %$comments;
            push @{$self->{files}}, $args->{File};
        }
    }

    return $self;
}


# Adds the specified user to the collection.  The arguments provided should
# form a hash with the following structure:
#  'Who' => "user_name"
#  'Attributes' => { key1 => val1, key2 => [ val2 val3 val4 ], ... }
#  'Comment' => "optional text to prefix the user's file entry"
#
# If there is some type of failure, 0 is returned.  Otherwise, 1.
sub add
{
    my ($self, %args) = @_;

    unless ($args{Who} and ref $args{Attributes} eq 'HASH') {
        carp('Insufficient parameters:  missing Who or hash of Attributes.');
        return 0;
    }
    $self->debug(6, "add - adding $args{Who}");

    # Add quotes to each attrib value if it has whitespace and isn't already
    # quoted.
    foreach my $k (keys %{$args{Attributes}}) {
        if (ref $args{Attributes}->{$k} eq 'ARRAY') {
            for (my $i=0; $i <= $#{$args{Attributes}->{$k}}; $i++) {
                $args{Attributes}->{$k}[$i] =~ s/^([^"].*[\s,].*)$/"$1"/;
            }
        }
        else {
            $args{Attributes}->{$k} =~ s/^([^"].*\s.*)$/"$1"/;
        }
    }

    tie %{$self->{'users'}{$args{Who}}}, 'Tie::IxHash'
     unless tied %{$self->{'users'}{$args{Who}}};

    foreach my $k (keys %{$args{Attributes}}) {
        push @{$self->{'users'}{$args{Who}}{$k}},
             ref $args{Attributes}->{$k} eq 'ARRAY'
               ? @{$args{Attributes}->{$k}}
               : $args{Attributes}->{$k}
    }

    if (exists $args{Comment}) {
        $args{Comment} =~ s/^/# /mg;
        $self->{comments}{$args{Who}} .= $args{Comment}. "\n";
    }

    return 1;
}


# Return a list of defined RADIUS attributes for the specified user.
#
sub attributes
{
    my ($self, $who) = @_;
    my @a = eval { local $^W = undef; keys %{$self->{'users'}{$who}} };
    return $@ ? undef : @a;
}


# Return the comment text associated with a user.
#
sub comment
{
    my ($self, $who) = @_;
    my $text = eval { local $^W = undef; $self->{comments}{$who} };
    return $@ ? undef : $text;
}


# Print the attributes of the specified user.
#
sub dump
{
    my ($self, $who) = @_;

    return $self unless defined $self->user($who);
    my @attribs = $self->attributes($who);

    print "RADIUS user $who:\n";

    if (@attribs) {
        foreach my $a (@attribs) {
            foreach my $v ($self->values($who, $a)) {
                printf "  %-${ATTR_MAX}s => %s\n", $a, $v;
            }
        }
    }
    else {
        print "  no attributes defined.\n";
    }

    return $self;
}


# Return a ref to a list of files that we have read user info from.
#
sub files
{
    my $self = shift;
    my @files = eval { local $^W = undef; @{$self->{files}} };
    return $@ ? () : @files;
}


# Return a string containing the attributes for the given user, in the
# format acceptable to a RADIUS users file.  If the user doesn't exist,
# an empty string is returned.
sub format
{
    my ($self, $who) = @_;

    return '' unless defined $self->user($who);
    my $str = $self->comment($who);

    my @attribs = $self->attributes($who);

    # figure out a good way to indent each record
    my $indent = length($who) + 1;
    if ($indent < 24) { $indent = 24 }

    if (@attribs) {
        my (@attrib_strs);
        my @checks = ();

        foreach my $a (@attribs) {
            foreach my $v ($self->values($who, $a)) {
                if ($self->_is_check_item($a)) {
                    $self->debug(8, "format - check item $a = $v");
                    push @checks, "$a = $v";
                }
                else {
                    push @attrib_strs,
                     sprintf("%s%s = %s", ' 'x$indent, $a, $v);
                }
            }
        }
        $str .= $who. (' 'x($indent - length $who)). join(', ', @checks). "\n";
        $str .= join(",\n", @attrib_strs). "\n";
    }

    return $str;
}


# Read user attributes from the specified file.  If a set of users is
# specified using "Who", the information is limited to those users.
#
sub load
{
    my ($self, %args) = @_;
    my $file = $args{File};
    my $who  = $args{Who};

    my ($users, $comments) = $self->read_users($file, $who);
    return 0 unless defined $comments and defined $users;

    foreach my $u (keys %$users) {
        tie(%{$self->{'users'}{$u}}, 'Tie::IxHash');
        foreach my $a (keys %{$users->{$u}}) {
            push @{$self->{'users'}{$u}{$a}}, @{$users->{$u}{$a}};
        }
    }
    foreach my $user (keys %$comments) {
        $self->{comments}{$user} .= $comments->{$user};
    }
    push @{$self->{'files'}}, $file;

    return 1;
}


# Read in a radius users file, according to the EBNF provided in
# "users-file-syntax.1", distributed w/the Ascend radius server software.
# Returns a ref to a hash of user names, where each user element is a hash
# of (attribute_name => value) pairs.  If a second argument is supplied
# ($who), it specifies the set of users to read in... all others in the
# file will be ignored.  If $who is a string, it is interpreted as a single
# user name; if it's a reference to an array, it's interpreted as a set
# of user names.
#
sub read_users
{
    my ($self, $users_file, $who) = @_;
    my (@fields, $user, %users, $attrib_set, $attrib_input, @who_we_want,
        %comments, $comment, $attr, $val);
    local (*USERS);

    $self->debug(2, "read_users - loading $users_file");
    open(USERS, $users_file)
     or carp("Error opening $users_file: $!"), return 0;
    seek USERS, 0, 0;

    @who_we_want = ref $who eq 'ARRAY' ? @$who : $who  if defined $who;

    while (<USERS>) {
        chomp;
        $self->debug(9, "read_users - in=``$_''");
        ($comment = '', next) unless $_;    # Skip if there's nothing useful,
        ($comment .= "$_\n", next) if /^#/; # or if it's just a comment.

        if (/(^[^#,\s]+)\s+(.+)/) {                         # first line
            $user = $1;
            $attrib_input = $2;
            $comments{$user} = $comment if $comment;
            tie(%{$users{$user}}, 'Tie::IxHash');
            $self->debug(5, "read_users - new record $user");
        }
        else {                                              # secondary line
            $attrib_input = $_;
        }

        next if @who_we_want and !grep($_ eq $user, @who_we_want);

        $attrib_set = _parse_attribs($attrib_input, $users_file);
        while (($attr, $val) = splice @$attrib_set, 0, 2) {
            push @{$users{$user}{$attr}}, $val;
        }
    }

    close USERS;

    return (\%users, \%comments);
}

# Return a ref to a hash of RADIUS users attributes.  We assume that
# comments have already been stripped from the input string.
#
sub _parse_attribs
{
    my ($raw, $file) = @_;
    my @attribs;

    $raw =~ s/^\s+//;                           # remove leading whitespace.

    while ($raw =~ s/^(\S+)\s*=\s*(("[^"]*")|[^",\s]+)\s*,?//) {
        if (defined $2) {
            push @attribs, $1, $2;
        }
        else {
            carp("Couldn't understand line $. in `$file'.");
            last;
        }

        $raw =~ s/^\s+//;
    }

    return \@attribs;
}


# Remove the specified users from $self.
sub remove
{
    my ($self, @users) = @_;

    foreach (@users) {
        delete $self->{'users'}{$_} and push @{$self->{removed}}, $_;
        delete $self->{comments}{$_};
    }

    my @removed = eval { local $^W = undef; @{$self->{removed}} };
    return $@ ? () : @removed;
}

sub removed
{
    my $self = shift;
    my @removed = eval { local $^W = undef; @{$self->{removed}} };
    return $@ ? () : @removed;
}


# Update user attributes in a RADIUS users file.  The arguments should be
# specified as a hash.  If the 'File' element is provided, that filename
# is used; otherwise, the last file read is used.  If the 'Who' element is
# provided, only the specified users are updated; otherwise, all known
# users are updated.
sub update
{
    my ($self, %args) = @_;
    my $file = exists $args{File} ? $args{File} : $self->{'files'}->[-1];
    my @who  = exists $args{Who}
               ? (ref $args{Who} eq 'ARRAY' ? @{$args{Who}} : $args{Who})
               : eval { local $^W = undef; keys %{$self->{users}} };
    my $temp = "$file.new";
    local (*IN, *TMP);
    my $oldsep = $/;
    local ($/) = '';        # we'll lose multiple blank lines this way

    carp('No users found'), return 0 unless (@who);
    _setup_files($file, \*IN, $temp, \*TMP) or return 0;
     
    my (%who, @recs, $name, $in);
    @who{@who} = (0) x @who;

    while (<IN>) {
        undef @recs;
        $in = $_;
        while (/^(
                 (?: \#.*\n)*           # pre-record comment lines
                 [^\#\s]+.*\n           # start of record
                 (?:                    # rest of record:
                   (?: \s+\S.*\n)|      #   attribute settings, or
                   ((?: \#.*\n)         #   comments not followed by another
                    (?! [^\#\s]))       #    start of record.
                 )*
              )/goxm) {
            push @recs, $1;
        }

        print(TMP $in), next unless @recs;
        foreach my $r (@recs) {
            ($name) = $r =~ /^([^#\s]+)/m;

            if (!$name) {
                print TMP $r;
            }
            elsif (exists $who{$name}) {
                $self->debug(6, "update - existing record $name");
                print TMP $self->format($name) if $who{$name} == 0;
                $who{$name}++;
            }
            elsif (!grep($name eq $_, $self->removed)) {
                print TMP $r;
            }
        }
        print TMP "\n";                 # since the input sep is "\n\n"
    }

    # Print out records for anyone we didn't find in $file.
    foreach (grep($who{$_} == 0, keys %who)) {
        $self->debug(6, "update - new record $_");
        print TMP $self->format($_), "\n";
    }

    $/ = $oldsep;

    # Close out input and output files (original and temporary, respectively)
    _cleanup_files($file, \*IN, $temp, \*TMP) or return 0;

    return 1;
}

# Organizational routine for update().  Sets up file handles for reading
# from the RADIUS users file.  The entire algorithm is like this:
#   open users file for read/write, creating if necessary
#   flock file exclusively
#   compare file opened to file locked, and re-open/lock while not equal
#   read from file, write to temp (handled in update())
#   close temp                    (handled by _cleanup_files)
#   rename temp to file
#   close file
sub _setup_files
{
    my ($file, $IN, $temp, $TMP) = @_;
    my $backup = "$file.bak";
    my $existed = -f $file;
    my ($dev1, $ino1, $dev2, $ino2);

    while (1) {
        open($IN, "+>>$file")
         or carp("Error opening $file: $!"), return 0;
        ($dev1, $ino1) = (stat $IN)[0,1];

        flock($IN, LOCK_EX)
         or carp("Error locking $file: $!"), close $IN, return 0;
        ($dev2, $ino2) = (stat $IN)[0,1];

        last if $dev1 == $dev2 and $ino1 == $ino2;
        close $IN;
    }

    seek $IN, 0, 0;
    open($TMP, ">$temp")
     or carp("Error creating $temp: $!"), close $IN, return 0;

    return 1;
}

# We should have new content in $TMP, and old content in $IN.
# So rename $TMP to $IN and close, releasing the flock on $IN established
# in _setup_files().
sub _cleanup_files
{
    my ($file, $IN, $temp, $TMP) = @_;

    close $TMP           or carp("Error closing $temp: $!"),           return 0;
    rename($temp, $file) or carp("Error renaming $file to $temp: $!"), return 0;
    close $IN            or carp("Error closing $file: $!"),           return 0;

    return 1;
}


# See if attribute is a checkable item (Lucent Radius fix -- Peter Bannis)
sub _is_check_item
{
    my ($self, $attribute) = @_;

    if ($attribute) {
        return grep(/^$attribute$/i, @{$self->{check_items}});
    }
    else {
        return 0;
    }
}


# Return a ref to a hash representing the attributes of the specified user.
#
sub user
{
    my ($self, $who) = @_;
    my %hash = eval { local $^W = undef; %{$self->{'users'}{$who}} };
    return $@ ? undef : \%hash;
}


# Return a ref to a list of users we have RADIUS info for, or a ref to an
# empty anonymous array if no users are defined.
#
sub usernames
{
    my $self = shift;
    my $users = eval { local $^W = undef; [ keys %{$self->{'users'}} ] };
    return $@ ? [] : $users;
}


# Return a ref to a hash of RADIUS users, indexed by user name, each
# containing a hash of attributes.  This is a ref to the actual data
# in the object, so the user information can be changed here.
#
sub users
{
    my $self = shift; return $self->{'users'};
}


# Return an array with the values of the given attribute for the named user.
#
sub values
{
    my ($self, $who, $attr) = @_;    
    my @vals = eval { local $^W = undef; @{$self->{'users'}{$who}{$attr}} };
    return $@ ? undef : @vals;
}

sub debug
{
    my ($self, $level, @msg) = @_;
    if ($level <= $self->{DEBUG}) {
        print STDERR join("\n", @msg), "\n";
    }
}


1;

__END__
