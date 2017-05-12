package OzDB;

use 5.008006;
use strict;
use warnings;
use Benchmark;

# Start the benchmark timer
 my $t0 = new Benchmark;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OzDB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

          ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.02';
# 5/20/2005, NeXeN:  Yet another versioning scheme.  Altho PAUSE/CPAN
# allows for x.y.z versioning schema, we'll move to x.yz so it'll show
# the minor version number correctly, with the revision point as the
# last digit.
#
#

# 5/19/2005, NeXeN: The new versioning scheme has been reset back to
# 0.0.1 for distribution with cpan.  Please see the
# Changes file for more information.
#
# our $VERSION = '0.1.3';
#


# methods.
sub new {
# my $t0 = new Benchmark;
    my $package = shift;
    return bless( {}, $package );
# my $t1 = new Benchmark;
# my $td = timediff($t1, $t0);
# print "Your OzDB Request took aproximately ", timestr($td),"\n\nThe results of your request are as follows:\n\n\n";

}

sub verbose {
    my $self = shift;
    if (@_) {
        $self->{'verbose'} = shift;
    }
    return $self->{'verbose'};
}

sub add_user {

# add_user method allows for 4 arguments exactly like authenticate.  The only
# difference is the second argument is ignored, and the third and forth must
# be string and integer respectively.  First argument is the name of the db file
#
# This is a cumulative database.  No remove functionality is implemented.
#
# format, add_user("userfile", "ignored", "user", "authlevel")
# authlevel being numeric value, ignored meaning the arg is not used
     my $self = shift;
     open( USRDB, "<$_[0]" ) or die "error opening user file: $_[0]\n";
    my @lines = <USRDB>;    # Read it into an array
    close(USRDB);
# check for correct syntax
# if ($_[3] !~ /^\d+$/ or $_[2] !~ /^[A-Za-z]+$/)
if (not defined $_[3] or not defined $_[2] or $_[3] !~ /^\d+$/)
  {
   print "The <username> must be letters only and the <auth_lvl> must be a number between 1 and 500\n";
   return "0 $_[2] $_[3]";

  }
  else
     {
     my $test;
        for $test (@lines)
        {
        # skip lines that are comments or blank lines
          if ($test =~ /^s*#/)
          {
            next;
          }
          if ($test =~ /^$/)
          {
            next;
          }
          # still in the for loop
# split the line up into into it's seporate values, delimited by space
          my (@words) = split(/ /, $test);
          # evaluate if the entry exists, if it does, exit the loop and give 'already exists' message
              if ($words[0] eq $_[2])
              {
                  print "The user, $words[0], already exists.\n";
                  return "1 $_[2] $_[3]";

              }
            # ok, the user didn't match, so what do we do now?
            next;
            # go to the next one, duh
            # still looping
           }
        # no longer in loop, but still else
        
        # the entry doesnt exist, lets make one
          print "Adding user $_[2] at authlevel $_[3].\n";

          # re-opening of the file, this time in append mode
          # doesn't seem to be too much of an IO drain, I get 0 ms execution
          # times tested up to 25mb file.  Until sockets are implemented,
          # this should be fine.
          open(USRDB, ">>$_[0]") or die "could not open $_[0] for append!\n";
          # print our data to the file
          print USRDB "$_[2] $_[3]\n";
          # close the file
          close(USRDB);
          return "2 $_[2] $_[3]";

        # still in the else meaning valid syntax with data left to handle
        # open(USRDB, ">>authuser.db");
     }
         # still in the sub, outside the else

 }
 sub add_command {
 return 0;
 }
sub authenticate {

    # format, authenticate("userfile", "commandfile", "user", "command")
    # authlevel being numeric value
    my $self = shift;
    open( USRDB, "<$_[0]" ) or die "error opening user file: $_[0]\n";
    my @users = <USRDB>;    # Read it into an array
    open( CMDDB, "<$_[1]" ) or die "error opening command file: $_[1]\n";
    my @commands = <CMDDB>;
    close(USRDB);
    close(CMDDB);
    my $userset;
    if (not defined $ARGV[0] or not defined $ARGV[1])
    {
    print "Wrong Syntax\n";
    return "0 $_[2] $_[3]";

    }
    for $userset (@users)
    {
        if ( $userset =~ /^s*#/ )
        {
            next;
        }

        if ( $userset =~ /^$/ )
        {
            next;
        }

        my (@userlist) = split( / /, $userset );

        if ( $userlist[0] eq $_[2] )
        {
            my $command;
            for $command (@commands)
            {

                chomp($command);

                if ( $command =~ /^s*#/ )
                {
                    next;
                }
                if ( $command =~ /^$/ )
                {
                    next;
                }
                my (@cmmd) = split( / /, $command );

                if ( $cmmd[0] eq $_[3] )
                {

                    # command exists

                    if ( $userlist[1] >= $cmmd[1] )
                    {
                        if ( defined $cmmd[2] )
                        {
                        # authenticated, but what type of command?
                        if ( $cmmd[2] eq "." )
                        {
                            print "$userlist[0] authenticated for $cmmd[0] which does: @cmmd[3..$#cmmd]\n";
                            return "1.0 $_[2] $_[3] @cmmd[3..$#cmmd]";

                        }

                        else
                        {
                            if ( $cmmd[2] eq "]" )
                           {
                                print "$userlist[0] authenticated for $cmmd[0] which does: @cmmd[3..$#cmmd]\n";
                                 for ( @cmmd[ 3 .. $#cmmd ], $_[2] ) { s/[\x0A\x0D]//g; s/[\r\n]//; }
                                 return "1.1 $_[2] $_[3] @cmmd[3..$#cmmd]";

                                #print "second time @cmmd[3..$#cmmd] test\n";

                            }

                           }
                            }
                            else
                           {
                           {
                             print "$userlist[0] authenticated for $cmmd[0]\n";
                             return "1.2 $_[2] $_[3]";

                            }
                        }
                        # I'm too lazy to track down the iteration of this loop
                        # therefore, I will add this print statement...
                        # If anyone sees the following message, please report
                        # it to the author's email address.
                        print "why did this happen?\n";
                        return "0 $_[2] $_[3]";

                    }
                    print "User $_[2] Not Authenticated\n";
                    return "2 $_[2] $_[3]";

                }

                # looping through the commands
                #print "why did this happen3?\n";
            }
            print "Command $_[3] doesn't exist\n";
            return "3 $_[2] $_[3]";

        }
        next;
        return "0 $_[2] $_[3]";
    }
    print "User $_[2] doesn't exist\n";
    return "4 $_[2] $_[3]";


    #end of sub
}
# see if we can get a different timer result
print "OzDB Driver version $VERSION\n";
# set a stop timer
 my $t1 = new Benchmark;
# calculate time difference
 my $td = timediff($t1, $t0);
 print "Your OzDB Request took aproximately ", timestr($td),"\nThe results of your request are as follows:\n";

1;
__END__

# Below is stub documentation for the module.

=head1 NAME

OzDB - database interface module for OzBot

=head1 SYNOPSIS

use OzDB;


=head1 DESCRIPTION

The OzDB Perl module handles authentication and access control for the OzBot
based utility bots.  The basic database format is the authentication schema.
This is based on a numerical ordering authentication system.  If the user's
Authentication level is higher than that of the command's authentication level
then the user is authenticated for the command and the command's special
arguments will be returned to the function.  This is useful for BACKEND
authentication only, where the usernames are entered by an already physically
or password authorized connection.  This is for information purposes, and is
not to be used as an actual database such as MySQL or PgSQL.  This is written
to faciliate developers with rudimentary information storage and any protected
information, including passwords, should not be stored in this database.  It
is simply a method to allow applications to store and retrieve data in an
arbitrary and extensible format with special delimiters.


=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item *
$obj->authenticate("authuser.db", "authcmd.db", "$name", "$command");

=item *
$obj->add_user("$authuserdb", "$authcmddb", "$name", "$authlevel");

=back

=head1 SEE ALSO

http://support.linuxops.net

=head1 AUTHOR

NeXeN, aka Osbourne nexen@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Daniel Remsburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
