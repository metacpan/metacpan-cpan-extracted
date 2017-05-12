###########################################
package Net::SSH::AuthorizedKeysFile;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Text::ParseWords;
use Net::SSH::AuthorizedKey;
use Net::SSH::AuthorizedKey::SSH1;
use Net::SSH::AuthorizedKey::SSH2;

our $VERSION = "0.18";

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my $self = {
        default_file        => "$ENV{HOME}/.ssh/authorized_keys",
        strict              => 0,
        abort_on_error      => 0,
        append              => 0,
        ridiculous_line_len => 100_000,
        @options,
    };

    bless $self, $class;

      # We allow keys to be set in the constructor
    my $keys = $self->{keys} if exists $self->{keys};

    $self->reset();

    $self->{keys} = $keys if defined $keys;

    return $self;
}

###########################################
sub sanity_check {
###########################################
    my($self, $file) = @_;

    $self->{file} = $file if defined $file;
    $self->{file} = $self->{default_file} if !defined $self->{file};

    my $result = undef;

    my $fh;

    if(! open $fh, "<$self->{file}") {
        ERROR "Cannot open file $self->{file}";
        return undef;
    }

    while(
      defined(my $rc = 
              sysread($fh, my $chunk, $self->{ridiculous_line_len}))) {
        if($rc < $self->{ridiculous_line_len}) {
            $result = 1;
            last;
        }

        if(index( $chunk, "\n" ) >= 0) {
              # contains a newline, looks good
            next;
        }

          # we've got a line that's between ridiculous_line_len and
          # 2*ridiculous_line_len characters long. Pull the plug.
        $self->error("File $self->{file} contains insanely long lines " .
                     "(> $self->{ridiculous_line_len} chars");
        last;
    }

DONE:
    close $fh;

    if(!$result) {
        ERROR "Sanity check of file $self->{file} failed";
    }
    return $result;
}

###########################################
sub keys {
###########################################
    my($self) = @_;

    return @{$self->{keys}};
}

###########################################
sub reset {
###########################################
    my($self) = @_;

    $self->{keys}    = [];
    $self->{content} = "";
    $self->{error}   = undef;
}

###########################################
sub content {
###########################################
    my($self, $new_content) = @_;

    if( defined $new_content ) {
       $self->reset();
       $self->{content} = $new_content;
    }

    return $self->{content};
}

###########################################
sub line_parse {
###########################################
    my($self, $line, $line_number) = @_;

    chomp $line;

    DEBUG "Parsing line [$line]";

    $self->error( "" );

    my $pk = Net::SSH::AuthorizedKey->parse( $line );

    if( !$pk ) {
        my $msg = "[$line] rejected by all parsers";
        WARN $msg;
        $self->error($msg);
        return undef;
    }

    if(! $self->{strict} or $pk->sanity_check()) {
        return $pk;
    }

    WARN "Key [$line] failed sanity check";

    if($self->{strict}) {
        $self->error( $pk->error() );
        return undef;
    }

      # Key is corrupted, but ok in non-strict mode
    return $pk;
}

###########################################
sub parse {
###########################################
    my($self) = @_;

    $self->{keys}  = [];
    $self->{error} = "";

    my $line_number = 0;

    for my $line (split /\n/, $self->{content}) {
        $line_number++;

        $line =~ s/^\s+//;     # Remove leading blanks
        $line =~ s/\s+$//;     # Remove trailing blanks
        next if $line =~ /^$/; # Ignore empty lines
        next if $line =~ /^#/; # Ignore comment lines

        my $key = $self->line_parse($line, $line_number);

        if( defined $key ) {
            push @{$self->{keys}}, $key;
        } else {
            if($self->{abort_on_error}) {
                $self->error("Line $line_number: " . $self->error());
                return undef;
            }
        }
    }

    return 1;
}

###########################################
sub read {
###########################################
    my($self, $file) = @_;

    $self->reset();

    $self->{file} = $file if defined $file;
    $self->{file} = $self->{default_file} if !defined $self->{file};  
    $self->{content} = "";

    DEBUG "Reading in $self->{file}";

    open FILE, "<$self->{file}" or LOGDIE "Cannot open $self->{file}";

    while(<FILE>) {
        $self->{content} .= $_;
    }

    close FILE;

   return $self->parse();
}

###########################################
sub as_string {
###########################################
    my($self) = @_;

    my $string = "";

    for my $key ( @{ $self->{keys} } ) {
        $string .= $key->as_string . "\n";
    }

    return $string;
}

###########################################
sub save {
###########################################
    my($self, $file) = @_;

    if(!defined $file) {
        $file = $self->{file};
    }

    if(! open FILE, ">$file") {
        $self->error("Cannot open $file ($!)");
        WARN $self->error();
        return undef;
    }

    print FILE $self->as_string();
    close FILE;
}

###########################################
sub append {
###########################################
    my($self, $key) = @_;

    $self->{append} = 1;
}

###########################################
sub error {
###########################################
    my($self, $text) = @_;


    if(defined $text) {
        $self->{error} = $text;

        if(length $text) {
            ERROR "$text";
        }
    }

    return $self->{error};
}

###########################################
sub ssh_dir {
###########################################
    my($self, $user) = @_;

    if(!defined $user) {
        my $uid = $>;
        $user = getpwuid($uid);
        if(!defined $user) {
            ERROR "getpwuid of $uid failed ($!)";
            return undef;
        }
    }

    my @pwent = getpwnam($user);

    if(! defined $pwent[0]) {
        ERROR "getpwnam of $user failed ($!)";
        return undef;
    }

    my $home = $pwent[7];

    return File::Spec->catfile($home, ".ssh");
}

###########################################
sub path_locate {
###########################################
    my($self, $user) = @_;

    my $ssh_dir = $self->ssh_dir($user);

    return undef if !defined $ssh_dir;

    return File::Spec->catfile($ssh_dir, "authorized_keys");
}

1;

__END__

=head1 NAME

Net::SSH::AuthorizedKeysFile - Read and modify ssh's authorized_keys files

=head1 SYNOPSIS

    use Net::SSH::AuthorizedKeysFile;

        # Reads $HOME/.ssh/authorized_keys by default
    my $akf = Net::SSH::AuthorizedKeysFile->new();

    $akf->read("authorized_keys");

        # Iterate over entries
    for my $key ($akf->keys()) {
        print $key->as_string(), "\n";
    }

        # Modify entries:
    for my $key ($akf->keys()) {
        $key->option("from", 'quack@quack.com');
        $key->keylen(1025);
    }
        # Save changes back to $HOME/.ssh/authorized_keys
    $akf->save() or die "Cannot save";

=head1 DESCRIPTION

Net::SSH::AuthorizedKeysFile reads and modifies C<authorized_keys> files.
C<authorized_keys> files contain public keys and meta information to
be used by C<ssh> on the remote host to let users in without 
having to type their password.

=head1 METHODS

=over 4

=item C<new>

Creates a new Net::SSH::AuthorizedKeysFile object and reads in the 
authorized_keys file. The filename 
defaults to C<$HOME/.ssh/authorized_keys> unless
overridden with

    Net::SSH::AuthorizedKeysFile->new( file => "/path/other_authkeys_file" );

Normally, the C<read> method described below will just silently ignore 
faulty lines and only gobble up keys that either one of the two parsers
accepts. If you want it to be stricter, set

    Net::SSH::AuthorizedKeysFile->new( file   => "authkeys_file",
                                       abort_on_error => 1 );

and read will immediately abort after the first faulty line. Also, 
the key parsers are fairly lenient in default mode. Adding

    strict => 1

adds sanity checks before a key is accepted.

=item C<read>

Reads in the file defined by new(). By default, strict mode is off and 
read() will silently ignore faulty lines. If it's on (see new() above),
read() will immediately abort after the first faulty line. A textual
description of the last error will be available via error().

=item C<content>

Contains the original file content, read by C<read()> earlier. Can be
used to set arbitrary content:

    $keysfile->content( "some\nrandom\nlines\n" );

and have C<parse()> operate on a string instead of an actual file 
this way.

=item C<keys>

Returns a list of Net::SSH::AuthorizedKey objects. Methods are described in
L<Net::SSH::AuthorizedKey>.

=item C<as_string>

String representation of all keys, ultimately the content that gets
written out when calling the C<save()> method. 
Note that comments from the original file are lost.

=item C<save>

Write changes back to the authorized_keys file using the as_string()
method described above. Note that comments from the original file are lost.
Optionally takes a file
name parameter, so calling C<$akf-E<gt>save("foo.txt")> will save the data
in the file "foo.txt" instead of the file the data was read from originally.
Returns 1 if successful, and undef on error. In case of an error, error()
contains a textual error description.

=item C<sanity_check>

Run a sanity check on the currently selected authorized_keys file. If
it contains insanely long lines, then parsing with read() (and potential
crashes because of out-of-memory errors) should be avoided.

=item C<ssh_dir( [$user] )>

Locate the .ssh dir of a given user. If no user name is given, ssh_dir will
look up the .ssh dir of the effective user. Typically returns something like
"/home/gonzo/.ssh".

=item C<path_locate( [$user] )>

Locate the authorized_keys file of a given user. Typically returns something 
like "/home/gonzo/.ssh/authorized_keys". See C<ssh_dir()> for how the 
containing directory is located with and without a given user name.

=item C<error>

Description of last error that occurred.

=back

=head1 LEGALESE

Copyright 2005-2009 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <m@perlmeister.com>
