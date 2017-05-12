##########################################
##########################################
##					##
##	Login - a reusable Tk-widget	##
##		login screen		##
##					##
##	Version 1.4			##
##					##
##	Brent B. Powers	(B2Pi)		##
##	Merrill Lynch			##
##	powers@swaps-comm.ml.com	##
##					##
##					##
##########################################
##########################################

=head1 NAME

Sybase::Login - A highly configurable Login widget for Sybperl and Perl/Tk

=head1 Change History

=over 4

=item

I<1.0> - Initial Implementation

I<1.1> - Componentized for perl5.0021bh, handlers fixed

I<1.2> - Set up for general distribution, added Version and VERSION.
Changed funky menu generation to Optionmenus.

I<1.3> - Added presentDBMenu and presentSrvMenu options.

I<1.4> - OK, so I had troubles with PAUSE on 1.3

I<Todo:> - Subclass Optionmenu to dynamically set up the Server
selections on post (or Buttondown?)

=back

=cut

=head1 DESCRIPTION

Login is a Widget that presents a dialog box to the user so that
the user may enter his or her login name and password, as well as
select the appropriate database and server.

=head1 USAGE

One uses Login by creating a new Login widget, adding at least one
Database via the addDatabase method, configuring via the configure
method, and then getting a valid login via the getVerification method.

=over 4

=item

=head2 Sample Program

=over 8

=item

 #!/usr/local/bin/perl -w

 use Tk;
 use Sybase::DBlib;
 use Sybase::Login;
 use strict;

 my($main) = MainWindow->new;
 my($Login) = $main->Login;

 $Login->addDatabase('DB',	'SYBSRV1','SYB11');
 $Login->addDatabase('DBBACK',	'SYBSRV1','SYB11');

 $Login->configure(-User => $ENV{USER},
		   -ULabel => 'User Name:',
		   -Title => 'Please Login');

 my($msg) = $main->Message(-text => 'Ready to go')->pack;
 $main->Button(-text => 'kick me!',
	       -command => sub {
		 my($pwd, $usr, $db, $srv, $mDB);
		 if ($Login->getVerification(-Force => 1)) {
		   $pwd = $Login->cget(-Password);
		   $usr = $Login->cget(-User);
		   $db =  $Login->cget(-Database);
		   $srv = $Login->cget(-Server);
		   print "Results good:\n\tUser:\t\t$usr\n";
		   print "\tPassword:\t$pwd\n\tDatabase:\t$db\n";
		   print "\tServer:\t\t$srv\n";
		   print "Verifying Login...\n";
		   $mDB = Sybase::DBlib->dblogin("$usr","$pwd", "$srv");
		   $mDB->dbuse($db);
		   $mDB->dbclose;
		   print "Login worked!!!\n";
		 } else {
		   print "Login cancelled at User request.\n";
		 }
	       })->pack;

 $main->Button(-text => 'exit',
	       -command => sub {$main->destroy;})->pack;

 MainLoop;

 print "And I'm on my way home!\n";

 exit;

=back

=item

=head2 Operation

The user is presented with a dialog box.  The focus is on the username
entry if no user name has been configured; otherwise, it is on the
password entry.  If multiple databases have been configured, the user
may select the appropriate database from the menu button. If multiple
servers have been configured for the selected database, the user may
select the appropriate server from the menu button.

When the user has finished entering information, she may press the OK
button to attempt to login, or the cancel button to abort the process.
If the user presses the OK button, and the login succeeds, control
returns to the caller.  If the login fails, an error dialog box is
displayed, and the user may press retry, or may press cancel, in which
case control returns to the caller exactly as if the user had pressed
cancel at the main login screen.

When control returns to the caller, the return value will be 1 if the
login was successful, or 0 if not.

=head2 Notes

A caller may define a message or error handler either before or after
calling any of the methods of this object. getCurrentVerification
will restore the handlers extant when invoked.

=back

=head1 Methods

=over 4

=item

=head2 getCurrentVerification

I<$Login->>I<getCurrentVerification;>

I<(No parameters)>

return 1 if the current configuration will result
in a valid login, 0 otherwise.  No GUI is ever displayed.

=head2 getVerification

I<$Login->>I<getVerification(-Force => ?);>

If the current configuration is NOT valid, activate the login
frame. This will return 1 with a valid configuration, or 0 if the user
hit cancel.  If the -Force parameter is passed as 't', 'y', or 1,
the login frame will be activated even if the current configuration
is valid.

=head2 addDatabase

I<$Login->>I<addDatabase(Database, Server List);>

adds a database/server set.  The first parameter is
the name of the database, the second is a list of
Associated Servers.  See the code above for examples.

Note that the first server in the list is the default server for that
database.  Further note that adding a database a second time simply
alters the servers.

=head2 clearDatabase

I<$Login->>I<clearDatabase([Database[, Database,...]]);>

Clears the given Database entries, or all databases if
if none are specified.

=head2 Version

I<$Login->>I<Version>

I<(No parameters)>

Returns the current version of Login

=back

=head1 Configuration Items

Any of the following configuration items may be set via the configure
method, or retrieved via the cget method.

=over 4

=item

=head2 -User

=over 4

Set or get the username.  The default is blank.

=back

=head2 -Password

=over 4

Set or get the password.  The default is blank.

=back

=head2 -Title

=over 4

Set or get the Title of the Login Widget.  The default is 'Database Login'

=back

=head2 -Database

=over 4

Set or get the default Database.  The default is blank.  The call will
silently fail if the database is not configured via the AddDatabase
method.  If the configured server is not a valid server for the given
database, the server will be set to the default server for the
database.

=back

=head2 -Server

=over 4

Set or get the default Server.  The default is blank.  The call will
silently fail if the server is not a valid server for the currently
configured database.

=back

=head2 -OKText

=over 4

Set or get the text for the I<OK> button.  The default is OK.

=back

=head2 -CancelText

=over 4

Set or get the text for the I<Cancel> button.  The default is Cancel.


=back

=head2 -ULabel

=over 4

Set or get the label for the User name entry.  The default is 'User:'.

=back

=head2 -PLabel

=over 4

Set or get the label for the Password entry.  The default is 'Password:'.

=back

=head2 -DLabel

=over 4

Set or get the label for the Database Menu Button.  The default is 'Database:'.

=back

=head2 -SLabel

=over 4

Set or get the label for the Server Menu Button.  The default is 'Server:'.

=back

=head2 -Labelfont

=over 4

Set or get the font used for the labels.  The default is
'-Adobe-Courier-Bold-R-Normal--*-120-*'.

=back

=head2 -EDlgTitle

=over 4

Set or get the Title for the Error Dialog. The default is
'Database Login Error!'.

=back

=head2 -EDlgText

=over 4

Set or get the text displayed in the Error Dialog.  The default is
'Unable to login to $db at $srv'.  $db will be interpreted as the
Database name, $srv will be interpreted as the Server name, $usr
will be interpreted as the User name, and $pwd will be interpreted
as the password.

=back

=head2 -EDlgRetry

=over 4

Set or get the text for the Retry button in the Error Dialog. The
default is 'Retry'.

=back

=head2 -EDlgCancel

=over 4

Set or get the text for the Cancel button in the Error Dialog. The
default is 'Cancel'.

=back

=head2 -presentDBMenu

=over 4

If set False, do not display the database menu.  The database will be
as configured, or default.  Default is True.

=back

=head2 -presentSrvMenu

If set False, do not display the server menu.  The Server will be as
configured, or default for the database. Default is True.

=over 4

=back

=back

=head1 Author

B<Brent B. Powers, B2Pi>

Currently on-site at Merrill Lynch, powers@ml.com

This code may be distributed under the same conditions as perl itself.

=cut
### Gevalt.  That's the end... now the code (350 lines of docs?)
#;

package Sybase::Login;

require 5.002;

use Tk;
use Tk::Dialog;
use Sybase::DBlib;
use Carp;
use strict;

@Sybase::Login::ISA = qw (Tk::Toplevel);
Tk::Widget->Construct('Login');

$Sybase::VERSION = 1.4;

my(@topside) = (-side => 'top');
my(@leftside) = (-side => 'left');
my(@rightside) = (-side => 'right');
my(@xfill) = (-fill => 'x');
my(@expand) = (-expand => 1);
my(@wanchor) = (-anchor => 'w');
my(@eanchor) = (-anchor => 'e');
my(@raised) = (-relief => 'raised');
my(@sunken) = (-relief => 'sunken');
my(@bw2) = (-borderwidth => 2);

sub Populate {

    ## Constructor for Login (password verification) widget.  Inherits
    ## new from base class

    my($self, @args) = @_;

    $self->SUPER::Populate(@args);

    $self->withdraw;

    ## This is a good chance to initialize some values
    $self->{Verified} = 0;
    $self->{DBList} = undef;

    $self->BuildBox;

    $self->ConfigSpecs(-User  =>	['PASSIVE', undef, undef, ''],
		       -Password =>	['PASSIVE', undef, undef, ''],
		       -Title =>	['PASSIVE', undef, undef, 'Database Login'],
		       -Database =>	['METHOD', undef, undef, ''],
		       -Server =>	['METHOD', undef, undef, ''],
		       -presentDBMenu =>['PASSIVE', undef, undef, 1],
		       -presentSrvMenu=>['PASSIVE', undef, undef, 1],
		       -OKText =>	['PASSIVE', undef, undef, 'OK'],
		       -CancelText =>	['PASSIVE', undef, undef, 'Cancel'],
		       -ULabel =>	['PASSIVE', undef, undef, 'User:'],
		       -PLabel =>	['PASSIVE', undef, undef, 'Password:'],
		       -DLabel =>	['PASSIVE', undef, undef, 'Database:'],
		       -SLabel =>	['PASSIVE', undef, undef, 'Server:'],
		       -Labelfont =>	['PASSIVE', undef, undef,
					 '-Adobe-Courier-Bold-R-Normal--*-120-*'],
		       -EDlgTitle =>	['PASSIVE', undef, undef,
					 'Database Login Error!'],
		       -EDlgText =>	['PASSIVE', undef, undef,
					 'Unable to login to $db at $srv'],
		       -EDlgRetry =>	['PASSIVE', undef, undef,'Retry'],
		       -EDlgCancel =>	['PASSIVE', undef, undef,'Cancel'],
		      );
}

sub Version {return $Sybase::Login::VERSION;}

sub addDatabase {
    my($self,$db,@srvlist) = @_;
    ### $db is the Database being added,
    ### @srvlist is the list of servers

    if (defined($db)) {
	$db =~ s/^\s+|\s+$//g;
    } else {
	$db = '';
    }
    if ($db eq '') {
	carp "Use Login->addDatabase(database, server [, server ...])";
	return;
    }

    ## Kvetch if somebody's trying to add a blank database
    if (!defined(@srvlist)) {
	carp "No servers defined for $db";
	return;
    }

    ### The user may either be modifying a current entry,
    ### implicitly deleting a current entry, or
    ### creating a new entry
    $self->{DBList}{$db} = \@srvlist;

    my($db1,$srv1);

    ### If the current Database is that just modified, check that the
    ### current server is still valid.  If not, set it to the default.
    if ($self->{Configure}{-Database} eq $db) {
	foreach (@srvlist) {
	    if ($self->{Configure}{'-Server'} eq $_) {
		# Found it, so we're OK
		return;
	    }
	}
	# Didn't find it, so set it to the default
	$self->{Configure}{'-Server'} = @srvlist[0];
    }
}

sub clearDatabase {
    #	Parameters:	([Database[, Database, ...]])

    my($self) = shift;
    my($firstdeldb) = @_;
    if (defined($firstdeldb) and ($firstdeldb ne "")) {
	### Parameters given
	foreach (@_) {
	    delete $self->{DBList}{$_};

	    if ($self->{Configure}{'-Database'} eq $_ ) {
		$self->{Configure}{'-Database'} = '';
		$self->{Configure}{'-Server'} = '';
	    }
	}
    } else {
	### No parameters given, delete all databases
	undef $self->{DBList};
	$self->{Configure}{'-Database'} = '';
	$self->{Configure}{'-Server'} = '';
    }
}

sub Server {
    my($self, $server) = @_;

    my($db);

    # Verify that the server is correct before setting

    ## Note that the database must be configured first,
    ## and the given server valid for the configured database
    if (defined($server) &&
	($server ne '') &&
	($self->{Configure}{-Database} ne '')) {

	foreach (@{$self->{DBList}{$self->{Configure}{'-Database'}}}) {
	    if ($server eq $_) {
		## Found it... save it
		$self->{Configure}{'-Server'} = $server;
		last;
	    }
	}
    }
    return $self->{Configure}{'-Server'};
}

sub Database {
    #	Parameters:	(Database)
    my ($self, $db) = @_;

    if (defined($db) and ($db ne '')) {
	## Only set a database that is configured
	if (defined($self->{DBList}{$db})) {
	    $self->{Configure}{'-Database'} = $db;

	    ##  Now check that the server is still valid
	    foreach (@{$self->{DBList}{$db}}) {
		if ($self->{Configure}{'-Server'} eq $_) {
		    #  It matches, and we're done
		    return $db;
		}
	    }
	    ## Hmmm, no match, use default
	    $self->{Configure}{'-Server'} = $self->{DBList}{$db}[0];
	}
    }
    return $self->{Configure}{'-Database'};
}

sub BuildBox {

    my($self) = shift;

    ############ Create the User name frame #############
    my($tFrame) = $self->Frame
	    ->pack(@topside, @xfill);

    $self->{ULabel} = $tFrame->Label(@wanchor)
	    ->pack(@leftside);

    $self->{userEntry} =
	    $tFrame->Entry(-textvariable => \$self->{Configure}{-User},
			   @sunken)
		    ->pack(@rightside, @expand, @xfill, @wanchor);

    ############ Create the Password Frame #############
    $self->{PFrame} = $tFrame = $self->Frame
	    ->pack(@topside, @xfill);

    $self->{PLabel} = $tFrame->Label(@wanchor)
	    ->pack(@leftside);

    $self->{passEntry} =
	    $tFrame->Entry(-textvariable => \$self->{Configure}{-Password},
			   -show => '#',
			   @sunken)
		    ->pack(@rightside, @expand, @xfill, @wanchor);

    ############ Create the Button Frame #############
    $tFrame = $self->Frame(@bw2)
	    ->pack(@topside);

    $self->{OKButton} = $tFrame->Button(-command => sub {
					    $self->TestLogin($self);
					})
	    ->pack(@leftside, @expand);

    $self->{OKButton}->bind('<Return>' => [sub {$self->{OKButton}->invoke}]);

    $self->{CancelButton} = $tFrame->Button(-command => sub {
						$self->Exit(0);
					    })
	    ->pack(@leftside, @expand);

    $self->{CancelButton}->bind('<Return>' => sub {
				    $self->{CancelButton}->invoke});
    $self->bind('<Escape>' => [sub {$self->{CancelButton}->invoke}]);

    $self->{passEntry}->bind('<Return>'=> sub { $self->{OKButton}->focus; });
    $self->{passEntry}->bind('<Control-u>' => sub {
				 $self->{Configure}{-Password} = '';
			       });
    $self->{userEntry}->bind('<Control-u>' => sub {
				   $self->{Configure}{-User} = '';
			       });
    $self->{userEntry}->bind('<Return>'=> sub {
				   \$self->{passEntry}->focus; } );
}

sub getCurrentVerification {
    my($self) = shift;

    ### The caller wants to find out if the current user, password
    ### database and server are OK.
    &TestDatabase($self);
}

sub CvtBool {
    my($a) = shift;
    return 1 if defined($a) && $a =~ m/[ytYT1]/;
    return 0;
}

sub getVerification {

    my($self, $force, $forceval) = @_;
    if (!defined($self->{DBList}) ||
	(keys %{$self->{DBList}}) == 0) {
	carp "No Databases defined";
	return 0;
    }

    if ((defined($force) &&
	 &CvtBool($forceval) &&
	 lc($force) eq '-force') ||
	!getCurrentVerification($self)) {

	## OK, do it
	$self->{Verified} = -1;

	$self->{Configure}{-presentDBMenu} =
		&CvtBool($self->{Configure}{-presentDBMenu});

	$self->{Configure}{-presentSrvMenu} =
		&CvtBool($self->{Configure}{-presentSrvMenu});

	$self->title($self->{Configure}{-Title});
	my($ParentState) = $self->parent->state;

	if ($ParentState ne 'withdrawn') {
	    $self->parent->withdraw;
	}

	## Set up the labels for the entries and menus
	$self->{ULabel}->configure(-text => $self->{Configure}{-ULabel},
				   -font => $self->{Configure}{-Labelfont});
	$self->{PLabel}->configure(-text => $self->{Configure}{-PLabel},
				   -font => $self->{Configure}{-Labelfont});


	############ Create the Database Frame, label, etc  #############
	$self->{dbFrame}->destroy if defined($self->{dbFrame});
	if ($self->{Configure}{-presentDBMenu}) {
	    $self->{dbFrame} = $self->Frame
		    ->pack(-after => $self->{PFrame}, @xfill);
	    $self->{DLabel} = $self->{dbFrame}->Label(@wanchor)
		    ->pack(@leftside);
	    $self->{DLabel}->
		    configure(-text => $self->{Configure}{-DLabel},
			      -font => $self->{Configure}{-Labelfont});
	}

	############ Create the Server Frame, label, etc  #############
	$self->{srvFrame}->destroy if defined($self->{srvFrame});
	if ($self->{Configure}{-presentSrvMenu}) {
	    my($f);
	    $f = $self->{srvFrame} = $self->Frame;
	    if ($self->{Configure}{-presentDBMenu}) {
		$f->pack(-after => $self->{dbFrame}, @xfill)
	    } else {
		$f->pack(-after => $self->{PFrame}, @xfill)
	    }

	    $self->{SLabel} = $self->{srvFrame}->Label(@wanchor)
		    ->pack(@leftside);
	    $self->{SLabel}->
		    configure(-text => $self->{Configure}{-SLabel},
			      -font => $self->{Configure}{-Labelfont});
	}

	$self->update;

	## Get the widest label...
	my($maxWidth) = $self->{ULabel}->reqwidth;
	my($max) = '-ULabel';

	if ($self->{PLabel}->reqwidth > $maxWidth) {
	    $max = $self->{PLabel}->reqwidth;
	    $max = '-PLabel';
	}

	if ($self->{Configure}{-presentDBMenu} &&
	    $self->{DLabel}->reqwidth > $maxWidth) {
	    $maxWidth = $self->{DLabel}->reqwidth;
	    $max = '-DLabel';
	}

	if ($self->{Configure}{-presentSrvMenu} &&
	    $self->{SLabel}->reqwidth > $maxWidth) {
	    $maxWidth = $self->{SLabel}->reqwidth;
	    $max = '-SLabel';
	}
	$max = length($self->{Configure}{$max});

	$self->{ULabel}->configure(-width => $max);
	$self->{PLabel}->configure(-width => $max);
	$self->{DLabel}->configure(-width => $max)
		if $self->{Configure}{-presentDBMenu};
	$self->{SLabel}->configure(-width => $max)
		if $self->{Configure}{-presentSrvMenu};
	$self->update;

	# Make sure that the Database is set
	if (!defined($self->{Configure}{'-Database'}) ||
	    ($self->{Configure}{'-Database'} eq '')) {
	    $self->{Configure}{'-Database'} = (keys %{$self->{DBList}})[0];
	    print "Set database to \"",(keys %{$self->{DBList}})[0],"\"\n";
	}

	## Set up the buttons
	$self->{OKButton}->configure(-text =>
				     $self->{Configure}{-OKText});
	$self->{CancelButton}->configure(-text =>
					 $self->{Configure}{-CancelText});

	$self->{databaseMB}->destroy if defined($self->{databaseMB});
	if ($self->{Configure}{-presentDBMenu}) {
	    $self->{databaseMB} = $self->{dbFrame}->Optionmenu
		    (-textvariable => \$self->{Configure}{'-Database'},
		     -command => sub {
			 &CreateSrvMenu($self);
		     },
		     @raised)
			    ->pack(@rightside, @eanchor, @expand, @xfill);

	    my(@opts);
	    foreach (sort keys(%{$self->{DBList}})) {
		push(@opts,$_);
	    }

	    $self->{databaseMB}->configure(-options => [@opts]);

	    $self->{databaseMB}->configure(-state => 'disabled') if 1 == @opts;
	}

	&CreateSrvMenu($self);


        # Set the focus to the user if it hasn't been set, or
        # to the password frame
        my ($oldFocus) = $self->focusCurrent;
        if ($self->{Configure}{-User} eq "") {
            $self->{userEntry}->focusForce;
        } else {
            $self->{passEntry}->focusForce;
        }

	# Take care of the window position
	my($x) = int(($self->screenwidth - $self->reqwidth)/2)
		- $self->parent->vrootx;
	my($y) = int(($self->screenheight - $self->reqheight)/2)
		- $self->parent->vrooty;

	$self->geometry("+$x+$y");

	$self->deiconify;

	## And do a grab
	$self->grab;

	## Wait for verification or cancel
	$self->tkwait('variable'=>\$self->{Verified});

	$self->grab('release');
        $oldFocus->focus if defined($oldFocus);

	$self->withdraw;
	if ($ParentState eq 'normal') {
	    $self->parent->deiconify;
	} elsif ($ParentState eq 'iconic') {
	    $self->parent->iconify;
	}

	return $self->{Verified};

    }
    return 1;
}

sub CreateSrvMenu {
    my($self) = @_;

    $self->{serverMB}->destroy if (defined($self->{serverMB}));

    $self->{Configure}{'-Server'} =
	    $self->{DBList}{$self->{Configure}{'-Database'}}[0];

    return if !$self->{Configure}{-presentSrvMenu};

    my(@opts);
    foreach (@{$self->{DBList}{$self->{Configure}{'-Database'}}}) {
	push(@opts, $_);
    }

    $self->{serverMB} = $self->{srvFrame}->
	    Optionmenu(-textvariable => \$self->{Configure}{'-Server'},
		       -options => [@opts],
		       @raised)
		    ->pack(@rightside, @eanchor, @expand, @xfill);

    $self->{Configure}{'-Server'} =
	    $self->{DBList}{$self->{Configure}{'-Database'}}[0];

    $self->{serverMB}->configure(-state => 'disabled') if 1 == @opts;
}

################################
## Password Screen Subroutines
################################

sub TestDatabase {
    ## Validate the current variables.

    my($self) = shift;

    $self->configure(-cursor => 'watch');
    $self->update;

    my($rslt,$mh, $eh);

    my($usr, $pwd, $srv, $db);
    $usr = $self->{Configure}{-User};
    $pwd = $self->{Configure}{-Password};
    $srv = $self->{Configure}{'-Server'};
    $db = $self->{Configure}{'-Database'};

    $mh = &dbmsghandle(undef);
    $eh = &dberrhandle(undef);
    $rslt = eval {
	&dbmsghandle(sub {return 1});
	&dberrhandle(sub {die;});

	my($MasterDB) = Sybase::DBlib->dblogin("$usr","$pwd", "$srv");
	$MasterDB->dbuse($db);
	$MasterDB->dbclose;
	return 1;
    };

    $rslt = $1 if !defined($rslt);

    if (defined($mh)) {
	&dbmsghandle($mh);
    } else {
	&dbmsghandle(undef);
    }
    if (defined($eh)) {
	&dberrhandle($eh);
    } else {
	&dberrhandle(undef);
    }

    $self->configure(-cursor => 'top_left_arrow');
    $self->update;
    return $rslt;
}

sub TestLogin {

    my($self) = @_;

    ## Validate the current set of login variables.
    ## If there's a failure, inform the user via a dialog
    if ($self->getCurrentVerification) {
	$self->Exit(1);
    } else {
	my($db) = $self->{Configure}{'-Database'};
	my($srv) = $self->{Configure}{'-Server'};
	my($usr) = $self->{Configure}{-User};
	my($pwd) = $self->{Configure}{-Password};

	eval "\$db = \"$self->{Configure}{-EDlgText}\"";

	if ($self->Dialog(-title => $self->{Configure}{-EDlgTitle},
			  -text => $db,
			  -bitmap => 'error',
			  -default_button => $self->{Configure}{-EDlgRetry},
			  -justify => 'center',
			  -buttons => [$self->{Configure}{-EDlgRetry},
				       $self->{Configure}{-EDlgCancel}])
	    ->Show eq $self->{Configure}{-EDlgCancel}) {
	    $self->Exit(0);
	}
    }
}

sub Exit {
    my($self, $arg) = @_;
    ## Trigger the change to the value Verified, enabling an exit
    ## from the tkwait.
    $self->{Verified} = $arg;
    return $self->{Verified};
}

### Return 1 to the calling  use statement ###
1;
### End of file Login.pm ###
