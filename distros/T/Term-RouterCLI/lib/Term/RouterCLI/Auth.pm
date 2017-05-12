#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Auth                                                 #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-27                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Auth;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Debugger;
use Log::Log4perl;
use Term::ReadKey;
use Digest::SHA qw(hmac_sha512_hex);

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();


sub new
{
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;  

    my $self = {};
    $self->{'_sName'}               = $pkg;         # Lets set the object name so we can use it in debugging
    bless ($self, $class);
    
    # Lets send any passed in arguments to the _init method
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;
    my %hParameters = @_;

    # Lets overwrite any defaults with values that are passed in
    if (%hParameters)
    {
        foreach (keys (%hParameters)) { $self->{$_} = $hParameters{$_}; }
    }
}

sub DESTROY
{
    my $self = shift;
    $self = {};
} 



# ----------------------------------------
# Public Methods
# ----------------------------------------
sub PromptForUsername
{
    # This method will prompt for the username to be entered on the command line
    # Return:
    # string_ref (password entered)
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $sUsername = "";

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    while(ord(my $key = ReadKey(0)) != 10) 
    {
        # This will continue until the Enter key is pressed (decimal value of 10)
        # For all value of ord($key) see http://www.asciitable.com/
        if (ord($key) == 127 || ord($key) == 8) 
        {
            # DEL/Backspace was pressed
            # Lets not allow backspace or del if there is not password characters to delete
            unless ($sUsername eq "")
            { 
                #1. Remove the last char from the password
                chop($sUsername);
                #2 move the cursor back by one, print a blank character, move the cursor back by one 
                print "\b \b";
            }
        }
        elsif (ord($key) <= 32 || ord($key) > 127) 
        { 
            # Do nothing with these control characters 
        }

        else { $sUsername = $sUsername.$key; }
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return \$sUsername;
}

sub PromptForPassword
{
    # This method will prompt for the password to be entered on the command line
    # Return:
    # string_ref (password entered)
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $sPassword = "";
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    # The following will hide all typeing, the while statement below will print * characters
    ReadMode(4);
    while(ord(my $key = ReadKey(0)) != 10) 
    {
        # This will continue until the Enter key is pressed (decimal value of 10)
        # For all value of ord($key) see http://www.asciitable.com/
        if (ord($key) == 127 || ord($key) == 8) 
        {
            # DEL/Backspace was pressed
            # Lets not allow backspace or del if there is not password characters to delete
            unless ($sPassword eq "")
            { 
                #1. Remove the last char from the password
                chop($sPassword);
                #2 move the cursor back by one, print a blank character, move the cursor back by one 
                print "\b \b";
            }
        }
        elsif (ord($key) <= 32 || ord($key) > 127) 
        { 
            # Do nothing with these control characters 
        }

        else 
        {
            $sPassword = $sPassword.$key;
            print "*";
        }
    }
    # Reset the terminal 
    ReadMode(0);
    # Since the Term::ReadKey method above strips out the carriage return, lets add it back
    print "\n";
    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return \$sPassword;
}

sub EncryptPassword
{
    # This method will encrypt a password with some salt
    # Required:
    #   int_ref    (type)
    #   string_ref (password)
    #   string_ref (salt)
    # Return:
    #   string_ref (encrypted password)
    my $self = shift;
    my $iCryptIDType = shift;
    my $sPassword = shift;
    my $sSalt = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $sCryptPassword = "";

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    # If Crypt ID Type == 0, then there is no encryption
    if    ( $$iCryptIDType == 0 && defined $$sPassword) { $sCryptPassword = $$sPassword; }
    elsif ( $$iCryptIDType == 6 && defined $$sPassword && defined $$sSalt) { $sCryptPassword = hmac_sha512_hex($$sPassword, $$sSalt); }

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return \$sCryptPassword;
}

sub SplitPasswordString
{
    # This method will split a password string of $id$salt$password in to the relevant parts
    # Required
    #   string_ref (password string)
    # Return:
    #   int_ref    (crypt id)
    #   string_ref (salt)
    #   string_ref (password)
    my $self = shift;
    my $sPasswordString = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $iID;
    my $sSalt = "";
    my $sPassword = "";

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    $logger->debug("$self->{'_sName'} - sPasswordString: $$sPasswordString");

    # Split key from password
    ($iID, $sSalt, $sPassword) = (split /\$/, $$sPasswordString)[1..3];


    $logger->debug("$self->{'_sName'} - iID: $iID");
    $logger->debug("$self->{'_sName'} - sSalt: $sSalt");
    $logger->debug("$self->{'_sName'} - sPassword: $sPassword");  
    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return (\$iID, \$sSalt, \$sPassword);
}



return 1;
