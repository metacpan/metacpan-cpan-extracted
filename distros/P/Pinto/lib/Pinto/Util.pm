# ABSTRACT: Static utility functions for Pinto

package Pinto::Util;

use strict;
use warnings;
use version;
use base qw(Exporter);

use Carp;
use DateTime;
use Path::Class;
use Digest::MD5;
use Digest::SHA;
use Scalar::Util;
use UUID::Tiny;
use Readonly;

use Pinto::Globals;
use Pinto::Constants qw(:all);

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(
    author_dir
    body_text
    current_author_id
    current_utc_time
    current_time_offset
    current_username
    debug
    decamelize
    indent_text
    interpolate
    is_blank
    is_not_blank
    is_interactive
    is_remote_repo
    is_system_prop
    isa_perl
    itis
    md5
    mksymlink
    mtime
    parse_dist_path
    mask_url_passwords
    sha256
    title_text
    throw
    trim_text
    truncate_text
    user_colors
    uuid
    whine
);

Readonly our %EXPORT_TAGS => ( all => \@EXPORT_OK );

#-------------------------------------------------------------------------------


sub throw {
    my ($error) = @_;

    # Rethrowing...
    die $error if itis( $error, 'Pinto::Exception' );    ## no critic (Carping)

    require Pinto::Exception;
    Pinto::Exception->throw( message => "$error" );

    return;                                              # Should never get here
}

#-------------------------------------------------------------------------------


sub debug {
    my ($it) = @_;

    # TODO: Use Carp instead?

    return 1 if not $ENV{PINTO_DEBUG};

    $it = $it->() if ref $it eq 'CODE';
    my ( $file, $line ) = (caller)[ 1, 2 ];
    print {*STDERR} "$it in $file at line $line\n";

    return 1;
}

#-------------------------------------------------------------------------------


sub whine {
    my ($message) = @_;

    if ( $ENV{DEBUG} ) {
        Carp::cluck($message);
        return 1;
    }

    chomp $message;
    warn $message . "\n";

    return 1;
}

#-------------------------------------------------------------------------------


sub author_dir {    ## no critic (ArgUnpacking)
    my $author = uc pop;
    my @base   = @_;

    return dir( @base, substr( $author, 0, 1 ), substr( $author, 0, 2 ), $author );
}

#-------------------------------------------------------------------------------


sub itis {
    my ( $var, $class ) = @_;

    return ref $var && Scalar::Util::blessed($var) && $var->isa($class);
}

#-------------------------------------------------------------------------------


sub parse_dist_path {
    my ($path) = @_;

    # eg: /yadda/authors/id/A/AU/AUTHOR/subdir1/subdir2/Foo-1.0.tar.gz
    # or: A/AU/AUTHOR/subdir/Foo-1.0.tar.gz

    if ( $path =~ s{^ (?:.*/authors/id/)? (.*) $}{$1}mx ) {

        # $path = 'A/AU/AUTHOR/subdir/Foo-1.0.tar.gz'
        my @path_parts = split m{ / }mx, $path;
        my $author     = $path_parts[2];          # AUTHOR
        my $archive    = $path_parts[-1];         # Foo-1.0.tar.gz
        return ( $author, $archive );
    }

    throw "Unable to parse path: $path";
}

#-------------------------------------------------------------------------------


sub isa_perl {
    my ($path_or_url) = @_;

    return $path_or_url =~ m{ / perl-[\d.]+ \.tar \.(?: gz|bz2 ) $ }mx;
}

#-------------------------------------------------------------------------------


sub mtime {
    my ($file) = @_;

    throw 'Must supply a file'   if not $file;
    throw "$file does not exist" if not -e $file;

    return ( stat $file )[9];
}

#-------------------------------------------------------------------------------


sub md5 {
    my ($file) = @_;

    throw 'Must supply a file'   if not $file;
    throw "$file does not exist" if not -e $file;

    my $fh  = $file->openr();
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest();

    return $md5;
}

#-------------------------------------------------------------------------------


sub sha256 {
    my ($file) = @_;

    throw 'Must supply a file'   if not $file;
    throw "$file does not exist" if not -e $file;

    my $fh     = $file->openr();
    my $sha256 = Digest::SHA->new(256)->addfile($fh)->hexdigest();

    return $sha256;
}

#-------------------------------------------------------------------------------


sub validate_property_name {
    my ($prop_name) = @_;

    throw "Invalid property name $prop_name" if $prop_name !~ $PINTO_PROPERTY_NAME_REGEX;

    return $prop_name;
}

#-------------------------------------------------------------------------------


sub validate_stack_name {
    my ($stack_name) = @_;

    throw "Invalid stack name $stack_name" if $stack_name !~ $PINTO_STACK_NAME_REGEX;

    return $stack_name;
}

#-------------------------------------------------------------------------------


sub current_utc_time {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_utc_time
        if defined $Pinto::Globals::current_utc_time;

    return time;
}

#-------------------------------------------------------------------------------


sub current_time_offset {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_time_offset
        if defined $Pinto::Globals::current_time_offset;

    my $now = current_utc_time;
    my $time = DateTime->from_epoch( epoch => $now, time_zone => 'local' );

    return $time->offset;
}

#-------------------------------------------------------------------------------


sub current_username {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_username
        if defined $Pinto::Globals::current_username;

    my $username = $ENV{PINTO_USERNAME} || $ENV{USER} || $ENV{LOGIN} || $ENV{USERNAME} || $ENV{LOGNAME};

    throw "Unable to determine your username.  Set PINTO_USERNAME." if not $username;

    return $username;
}

#-------------------------------------------------------------------------------


sub current_author_id {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::current_author_id
        if defined $Pinto::Globals::current_author_id;

    my $author_id = $ENV{PINTO_AUTHOR_ID};
    return uc $author_id if $author_id;

    my $username = current_username;
    $username =~ s/[^a-zA-Z0-9]//g;

    return uc $username;
}

#-------------------------------------------------------------------------------


sub is_interactive {

    ## no critic qw(PackageVars)
    return $Pinto::Globals::is_interactive
        if defined $Pinto::Globals::is_interactive;

    return -t STDOUT;
}

#-------------------------------------------------------------------------------


sub interpolate {
    my $string = shift;

    return eval qq{"$string"};    ## no critic qw(Eval)
}

#-------------------------------------------------------------------------------


sub trim_text {
    my $string = shift;

    $string =~ s/^ \s+  //x;
    $string =~ s/  \s+ $//x;

    return $string;
}

#-------------------------------------------------------------------------------


sub title_text {
    my $string = shift;

    my $nl = index $string, "\n";
    return $nl < 0 ? $string : substr $string, 0, $nl;
}

#-------------------------------------------------------------------------------


sub body_text {
    my $string = shift;

    my $nl = index $string, "\n";
    return '' if $nl < 0 or $nl == length $string;
    return substr $string, $nl + 1;
}

#-------------------------------------------------------------------------------


sub truncate_text {
    my ( $string, $max_length, $elipses ) = @_;

    return $string if not $max_length;
    return $string if length $string <= $max_length;

    $elipses = '...' if not defined $elipses;

    my $truncated = substr $string, 0, $max_length;

    return $truncated . $elipses;
}

#-------------------------------------------------------------------------------


sub decamelize {
    my $string = shift;

    return if not defined $string;

    $string =~ s/ ([a-z]) ([A-Z]) /$1_$2/xg;

    return lc $string;
}

#-------------------------------------------------------------------------------


sub indent_text {
    my ( $string, $spaces ) = @_;

    return $string if not $spaces;
    return $string if not $string;

    my $indent = ' ' x $spaces;
    $string =~ s/^ /$indent/xmg;

    return $string;
}

#-------------------------------------------------------------------------------


sub mksymlink {
    my ( $from, $to ) = @_;

    # TODO: Try to add Win32 support here, somehow.
    debug "Linking $to to $from";
    symlink $to, $from or throw "symlink to $to from $from failed: $!";

    return 1;
}

#-------------------------------------------------------------------------------


sub is_system_prop {
    my $string = shift;

    return 0 if not $string;
    return $string =~ m/^ pinto- /x;
}

#-------------------------------------------------------------------------------


sub uuid {
    return UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V4);
}

#-------------------------------------------------------------------------------


sub user_colors {
    my $colors = $ENV{PINTO_COLORS} || $ENV{PINTO_COLOURS};

    return $PINTO_DEFAULT_COLORS if not $colors;

    return [ split m/\s* , \s*/x, $colors ];
}

#-------------------------------------------------------------------------------


sub is_blank {
    my ($string) = @_;

    return 1 if not $string;
    return 0 if $string =~ m/ \S /x;
    return 1;
}

#-------------------------------------------------------------------------------


sub is_not_blank {
    my ($string) = @_;

    return !is_blank($string);
}

#-------------------------------------------------------------------------------


sub mask_url_passwords {
    my ($url) = @_;

    $url =~ s{ (https?://[^:/@]+ :) [^@/]+@}{$1*password*@}gx;

    return $url;
}

#-------------------------------------------------------------------------------


sub is_remote_repo {
    my ($url) = @_;

    return if not $url;
    return $url =~ m{^https?://}x;
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Util - Static utility functions for Pinto

=head1 VERSION

version 0.097

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).  All API documentation is purely for my own
reference.

=head1 FUNCTIONS

=head2 throw($message)

=head2 throw($exception_object)

Throws a L<Pinto::Exception> with the given message.  If given a reference
to a L<Pinto::Exception> object, then it just throws it again.

=head2 debug( $message )

=head2 debug( sub {...} )

Writes the message on STDERR if the C<PINTO_DEBUG> environment variable is true.
If the argument is a subroutine, it will be invoked and its output will be
written instead.  Always returns true.

=head2 whine( $message )

Just calls warn(), but always appends the newline so that line numbers are
suppressed.

=head2 author_dir( @base, $author )

Given the name of an C<$author>, returns the directory where the
distributions for that author belong (as a L<Path::Class::Dir>).  The
optional C<@base> can be a series of L<Path::Class:Dir> or path parts
(as strings).  If C<@base> is given, it will be prepended to the
directory that is returned.

=head2 itis( $var, $class )

Asserts whether var is a blessed reference and is an instance of the
C<$class>.

=head2 parse_dist_path( $path )

Parses a path like the ones you would see in a full URL to a
distribution in a CPAN repository, or the URL fragment you would see
in a CPAN index.  Returns the author and file name of the
distribution.  Subdirectories between the author name and the file
name are discarded.

=head2 isa_perl( $path_or_url )

Return true if C<$path_or_url> appears to point to a release of perl
itself.  This is based on some file naming patterns that I've seen in
the wild.  It may not be completely accurate.

=head2 mtime( $file )

Returns the last modification time (in epoch seconds) for the C<file>.
The argument is required and the file must exist or an exception will
be thrown.

=head2 md5( $file )

Returns the C<MD-5> digest (as a hex string) for the C<$file>.  The
argument is required and the file must exist on an exception will be
thrown.

=head2 sha256( $file )

Returns the C<SHA-256> digest (as a hex string) for the C<$file>.  The
argument is required and the file must exist on an exception will be
thrown.

=head2 validate_property_name( $prop_name )

Throws an exception if the property name is invalid.  Currently,
property names must be alphanumeric plus any underscores or hyphens.

=head2 validate_stack_name( $stack_name )

Throws an exception if the stack name is invalid.  Currently, stack
names must be alphanumeric plus underscores or hyphens.

=head2 current_utc_time()

Returns the current time (in epoch seconds) unless the current time has been
overridden by C<$Pinto::Globals::current_utc_time>.

=head2 current_time_offset()

Returns the offset between current UTC time and the local time in
seconds, unless overridden by C<$Pinto::Globals::current_time_offset>.
The C<current_time> function is used to determine the current UTC
time.

=head2 current_username()

Returns the username of the current user unless it has been overridden by
C<$Pinto::Globals::current_username>.  The username can be defined through
a number of environment variables.  Throws an exception if no username
can be determined.

=head2 current_author_id()

Returns the author id of the current user unless it has been overridden by
C<$Pinto::Globals::current_author_id>.  The author id can be defined through
environment variables.  Otherwise it defaults to the upper-case form of the
C<current_username>.  And since PAUSE only allows letters and numbers in the
author id, then we remove all of those from the C<current_username> too.

=head2 is_interactive()

Returns true if the process is connected to an interactive terminal
(i.e.  a keyboard & screen) unless it has been overridden by
C<$Pinto::Globals::is_interactive>.

=head2 interpolate($string)

Performs interpolation on a literal string.  The string should not
include anything that looks like a variable.  Only metacharacters
(like \n) will be interpolated correctly.

=head2 trim_text($string)

Returns the string with all leading and trailing whitespace removed.

=head2 title_text($string)

Returns all the characters in C<$string> before the first newline.  If
there is no newline, returns the entire C<$string>.

=head2 body_text($string)

Returns all the characters in C<$string> after the first newline.  If
there is no newline, returns an empty string.

=head2 truncate_text($string, $length, $elipses)

Truncates the C<$string> and appends C<$elipses> if the C<$string> is 
longer than C<$length> characters.  C<$elipses> defaults to '...' if 
not specified.

=head2 decamelize($string)

Returns the string forced to lower case and words separated by underscores.
For example C<FooBar> becomes C<foo_bar>.

=head2 indent_text($string, $n)

Returns a copy of C<$string> with each line indented by C<$n> spaces.
In other words, it puts C<4n> spaces immediately after each newline
in C<$string>.  The original C<$string> is not modified.

=head2 mksymlink($from => $to)

Creates a symlink between the two files.  No checks are performed to see
if either path is valid or already exists.  Throws an exception if the
operation fails or is not supported.

=head2 is_system_prop($string)

Returns true if C<$string> is the name of a system property.

=head2 uuid()

Returns a UUID as a string.  Currently, the UUID is derived from
random numbers.

=head2 user_colors()

Returns a reference to an array containing the names of the colors pinto 
can use.  This can be influenced by setting the C<PINTO_COLORS> or 
C<PINTO_COLOURS> environment variables.

=head2 is_blank($string)

Returns true if the string is undefined, empty, or contains only whitespace.

=head2 is_not_blank($string)

Returns true if the string contains any non-whitespace characters.

=head2 mask_url_passwords($string)

Masks the parts the string that look like a password embedded in an http or
https URL. For example, C<http://joe:secret@foo.com> would return 
C<http://joe:*password*@foo.com>

=head2 is_remote_repo {

Returns true if the argument looks like a URL to a remote repository

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
