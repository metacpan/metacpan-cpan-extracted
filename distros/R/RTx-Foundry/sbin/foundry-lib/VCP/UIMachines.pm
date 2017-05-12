package VCP::UIMachines;

=begin hackers

DO NOT EDIT!!! GENERATED FROM ui_machines/vcp_ui.tt2 by /usr/local/bin/stml AT Wed Jun  4 15:39:54 2003

=end hackers

=head1 NAME

    VCP::UIMachines - State machines for user interface

=head1 SYNOPSIS

    Called by VCP::UI

=head1 DESCRIPTION

The user interface module L<VCP::UI|VCP::UI> is a framework that bolts
the implementation of the user interface to a state machine representing
the user interface.

Each state in this state machine is a method that runs the state and
returns a result (or dies to exit the program).

=cut

use strict;

use VCP::Debug qw( :debug );

=head1 API

=over

=item new

Creates a new user interface object.

=cut

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless { @_ }, $class;
}

=item run

Executes the user interface.

=cut

sub run {
    my $self = shift;
    my ( $ui ) = @_;

    $self->{STATE} = "init";
    while ( defined $self->{STATE} ) {
        debug "UI entering state $self->{STATE}" if debugging;
        no strict "refs";
        $self->{STATE} = $self->{STATE}->( $ui );
    }

    return;
}

=back

=head2 Interactive Methods

=over

=cut

use strict;

=item init

Initialize the machine

Next state: source_prompt

=cut

sub init {
    return 'source_prompt';
}

=item source_prompt: Source SCM type

Enter the kind of repository to copy data from.

Valid answers:

    vss => source_vss_filespec_prompt
    cvs => source_cvs_cvsroot_prompt
    p4 => source_p4_run_p4d_prompt


=cut

sub source_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Source SCM type
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ 'vss', 'vss', 'source_vss_filespec_prompt',
            undef,
        
        ],
        [ 'cvs', 'cvs', 'source_cvs_cvsroot_prompt',
            undef,
        
        ],
        [ 'p4', 'p4', 'source_p4_run_p4d_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                require VCP::Source::p4;
                $ui->{Source} = VCP::Source::p4->new;
                $ui->{Source}->repo_scheme( 'p4' );
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the kind of repository to copy data from.
    
    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_prompt: Destination SCM type

Enter the kind of repository to copy data to.

Valid answers:

    vss => dest_vss_filespec_prompt
    p4 => dest_p4_run_p4d_prompt
    cvs => dest_cvs_cvsroot_prompt


=cut

sub dest_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Destination SCM type
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ 'vss', 'vss', 'dest_vss_filespec_prompt',
            undef,
        
        ],
        [ 'p4', 'p4', 'dest_p4_run_p4d_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                require VCP::Dest::p4;
                $ui->{Dest} = VCP::Dest::p4->new;
                $ui->{Dest}->repo_scheme( 'p4' );
            },
        
        ],
        [ 'cvs', 'cvs', 'dest_cvs_cvsroot_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the kind of repository to copy data to.
    
    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item convert

Run VCP with the options entered

=cut

sub convert {
    return undef;
}

=item dest_p4_run_p4d_prompt: Launch a private p4d in a local directory

If you are working with an offline repository in a local directory,
vcp can launch a p4d in that directory on a random high numbered TCP
port for you.

Valid answers:

    yes => dest_p4_p4d_dir_prompt
    no => dest_p4_host_prompt


=cut

sub dest_p4_run_p4d_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Launch a private p4d in a local directory
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ 'yes', qr/\Ay(es)?\z/i, 'dest_p4_p4d_dir_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->{P4_RUN_P4D} = 1;            },
        
        ],
        [ 'no', qr/\Ano?\z/i, 'dest_p4_host_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );

    
If you are working with an offline repository in a local directory,
vcp can launch a p4d in that directory on a random high numbered TCP
port for you.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_p4d_dir_prompt: Directory to run p4d in

Enter the directory to launch the p4d in.  VCP will then check that
this is a valid directory.

Valid answers:

     => dest_p4_user_prompt


=cut

sub dest_p4_p4d_dir_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Directory to run p4d in
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', sub { -d $_ ? 1 : die qw{'$_' is not a valid directory} }, 'dest_p4_user_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->repo_server( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the directory to launch the p4d in.  VCP will then check that
this is a valid directory.
    
    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_host_prompt: P4 Host name, including port

Enter the name and port of the p4d to read from, separated by
a colon.  Leave empty to use the p4's default of the P4HOST
environment variable if set or "perforce:1666" if not.

Valid answers:

     => dest_p4_user_prompt


=cut

sub dest_p4_host_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
P4 Host name, including port
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_p4_user_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->repo_server( $answer );
                $ui->{Dest}->repo_id( "p4:" . $answer );
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the name and port of the p4d to read from, separated by
a colon.  Leave empty to use the p4's default of the P4HOST
environment variable if set or "perforce:1666" if not.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_user_prompt: P4 user id

Enter the user_id (P4USER) value needed to access the server.  Leave
empty to the P4USER environemnt variable, if present; or the login
user if not.

Valid answers:

     => dest_p4_password_prompt


=cut

sub dest_p4_user_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
P4 user id
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_p4_password_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->repo_user( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the user_id (P4USER) value needed to access the server.  Leave
empty to the P4USER environemnt variable, if present; or the login
user if not.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_password_prompt: Password

If a password (P4PASSWD) is needed to access the server, enter it here.

WARNING: password will be echoed in plain text to the terminal.

Valid answers:

     => dest_p4_filespec_prompt


=cut

sub dest_p4_password_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Password
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_p4_filespec_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->repo_password( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


If a password (P4PASSWD) is needed to access the server, enter it here.

WARNING: password will be echoed in plain text to the terminal.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_filespec_prompt: Files to copy

The destination spec is a perforce repository spec and must begin with
// and a depot name ("//depot"), not a local filesystem spec or a
client spec.  There should be a trailing "/..." specified.

Valid answers:

    //... => dest_p4_change_branch_rev_prompt


=cut

sub dest_p4_filespec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Files to copy
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '//...', qr#\A//[^.]*\.{3}\z#, 'dest_p4_change_branch_rev_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->repo_filespec( $answer );
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


The destination spec is a perforce repository spec and must begin with
// and a depot name ("//depot"), not a local filesystem spec or a
client spec.  There should be a trailing "/..." specified.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_p4_change_branch_rev_prompt: Change branch rev #1

Forces VCP to do a p4 integrate, add, submit sequence to branch files,
thus capturing the branch and the file alterations in one change.

Valid answers:

     => convert


=cut

sub dest_p4_change_branch_rev_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Change branch rev #1
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/\A(y(es)?|no?)\z/i, 'convert',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Dest}->{P4_CHANGE_BRANCH_REV_1} = 1;
                $ui->{Dest}->init;
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Forces VCP to do a p4 integrate, add, submit sequence to branch files,
thus capturing the branch and the file alterations in one change.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_cvs_cvsroot_prompt: cvsroot

Enter the cvsroot spec.  Leave empty to use the CVSROOT environment
variable if set.

Valid answers:

     => dest_cvs_module_prompt


=cut

sub dest_cvs_cvsroot_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvsroot
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_cvs_module_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the cvsroot spec.  Leave empty to use the CVSROOT environment
variable if set.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_cvs_module_prompt: cvs module

Enter the cvs module name.

Valid answers:

     => dest_cvs_init_cvsroot_prompt


=cut

sub dest_cvs_module_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvs module
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/./, 'dest_cvs_init_cvsroot_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the cvs module name.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_cvs_init_cvsroot_prompt: Change branch rev #1

Initializes a cvs repository in the directory indicated in the cvs
CVSROOT spec. Refuses to init a non-empty directory.

Valid answers:

     => convert


=cut

sub dest_cvs_init_cvsroot_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Change branch rev #1
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/\A(y(es)?|no?)\z/i, 'convert',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Initializes a cvs repository in the directory indicated in the cvs
CVSROOT spec. Refuses to init a non-empty directory.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item dest_vss_filespec_prompt: vss filespec

Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

Valid answers:

     => convert


=cut

sub dest_vss_filespec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
vss filespec
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/./, 'convert',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_run_p4d_prompt: Launch a private p4d in a local directory

If you are working with an offline repository in a local directory, vcp
can launch a p4d in that directory on a random hi-numbered TCP port for
you.

Valid answers:

    yes => source_p4_p4d_dir_prompt
    no => source_p4_host_prompt


=cut

sub source_p4_run_p4d_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Launch a private p4d in a local directory
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ 'yes', qr/\Ay(es)?\z/i, 'source_p4_p4d_dir_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->{P4_RUN_P4D} = 1;            },
        
        ],
        [ 'no', qr/\Ano?\z/i, 'source_p4_host_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );

    
If you are working with an offline repository in a local directory, vcp
can launch a p4d in that directory on a random hi-numbered TCP port for
you.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_p4d_dir_prompt: Directory to run p4d in

Enter the directory to launch the p4d in.  VCP will then check that
this is a valid directory.

Valid answers:

     => source_p4_user_prompt


=cut

sub source_p4_p4d_dir_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Directory to run p4d in
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', sub { -d $_ ? 1 : die qw{'$_' is not a valid directory} }, 'source_p4_user_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->repo_server( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the directory to launch the p4d in.  VCP will then check that
this is a valid directory.
    
    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_host_prompt: P4 Host name, including port

Enter the name and port of the p4d to read from, separated by
a colon.  Leave empty to use the p4's default of the P4HOST
environment variable if set or "perforce:1666" if not.

Valid answers:

     => source_p4_user_prompt


=cut

sub source_p4_host_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
P4 Host name, including port
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_p4_user_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->repo_server( $answer );
                $ui->{Source}->repo_id( "p4:" . $answer );
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the name and port of the p4d to read from, separated by
a colon.  Leave empty to use the p4's default of the P4HOST
environment variable if set or "perforce:1666" if not.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_user_prompt: P4 user id

Enter the user_id (P4USER) value needed to access the server.  Leave
empty to the P4USER environment variable, if present; or the login
user if not.

Valid answers:

     => source_p4_password_prompt


=cut

sub source_p4_user_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
P4 user id
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_p4_password_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->repo_user( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the user_id (P4USER) value needed to access the server.  Leave
empty to the P4USER environment variable, if present; or the login
user if not.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_password_prompt: Password

If a password (P4PASSWD) is needed to access the server, enter it here.

WARNING: password will be echoed in plain text to the terminal.

Valid answers:

     => source_p4_filespec_prompt


=cut

sub source_p4_password_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Password
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_p4_filespec_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->repo_password( $answer );            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


If a password (P4PASSWD) is needed to access the server, enter it here.

WARNING: password will be echoed in plain text to the terminal.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_p4_filespec_prompt: Files to copy

If you want to copy a portion of the source repository, enter a p4
filespec starting with the depot name.  Do not enter any revision or
change number information.

Valid answers:

    //... => dest_prompt


=cut

sub source_p4_filespec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Files to copy
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '//...', qr{\A//.+}, 'dest_prompt',
            sub {
                my ( $ui, $answer, $answer_record ) = @_;
                $ui->{Source}->repo_filespec( $answer );
                $ui->{Source}->init;
            },
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


If you want to copy a portion of the source repository, enter a p4
filespec starting with the depot name.  Do not enter any revision or
change number information.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_cvsroot_prompt: cvsroot

Enter the cvsroot spec.  Leave empty to use the CVSROOT environment
variable if set.

Valid answers:

     => source_cvs_module_prompt


=cut

sub source_cvs_cvsroot_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvsroot
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_cvs_module_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the cvsroot spec.  Leave empty to use the CVSROOT environment
variable if set.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_module_prompt: cvs module

Enter the cvs module name.

Valid answers:

     => source_cvs_filespec_prompt


=cut

sub source_cvs_module_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvs module
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/./, 'source_cvs_filespec_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the cvs module name.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_filespec_prompt: cvs filespec

Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

Valid answers:

     => source_cvs_working_directory_prompt


=cut

sub source_cvs_filespec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvs filespec
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/./, 'source_cvs_working_directory_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_working_directory_prompt: Enter CVS working directory

Used to set the CVS working directory. VCP::Source::cvs will cd to
this directory before calling cvs, and won't initialize a CVS
workspace of it's own (normally, VCP::Source::cvs does a "cvs
checkout" in a temporary directory).

Valid answers:

     => source_cvs_binary_checkout_prompt


=cut

sub source_cvs_working_directory_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Enter CVS working directory
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_cvs_binary_checkout_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Used to set the CVS working directory. VCP::Source::cvs will cd to
this directory before calling cvs, and won't initialize a CVS
workspace of it's own (normally, VCP::Source::cvs does a "cvs
checkout" in a temporary directory).

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_binary_checkout_prompt: Force binary checkout

Pass the -kb option to cvs, to force a binary checkout. This is useful
when you want a text file to be checked out with Unix linends, or if
you know that some files in the repository are not flagged as binary
files and should be.

Valid answers:

     => source_cvs_use_cvs_prompt


=cut

sub source_cvs_binary_checkout_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Force binary checkout
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/\A(y(es)?|no?)\z/i, 'source_cvs_use_cvs_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Pass the -kb option to cvs, to force a binary checkout. This is useful
when you want a text file to be checked out with Unix linends, or if
you know that some files in the repository are not flagged as binary
files and should be.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_use_cvs_prompt: Use cvs (rather than reading local repositories directly)

Use cvs rather than a direct read of local repositories.  This is
slower, but the option is present in case there are repositories
vcp has trouble reading directly.

Valid answers:

     => source_cvs_revision_prompt


=cut

sub source_cvs_use_cvs_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Use cvs (rather than reading local repositories directly)
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/\A(y(es)?|no?)\z/i, 'source_cvs_revision_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Use cvs rather than a direct read of local repositories.  This is
slower, but the option is present in case there are repositories
vcp has trouble reading directly.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_revision_prompt: cvs log revision specification

Passed to "cvs log" as a "-r" revision specification. This corresponds
to the "-r" option for the rlog command, not either of the "-r"
options for the cvs command.  See rlog(1) man page for the format.

Valid answers:

     => source_cvs_date_spec_prompt


=cut

sub source_cvs_revision_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvs log revision specification
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'source_cvs_date_spec_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Passed to "cvs log" as a "-r" revision specification. This corresponds
to the "-r" option for the rlog command, not either of the "-r"
options for the cvs command.  See rlog(1) man page for the format.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_cvs_date_spec_prompt: cvs log date specification

Passed to 'cvs log' as a "-d" date specification.  See rlog(1) man
page for the format.

Valid answers:

     => dest_prompt


=cut

sub source_cvs_date_spec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
cvs log date specification
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Passed to 'cvs log' as a "-d" date specification.  See rlog(1) man
page for the format.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_vss_filespec_prompt: vss filespec

Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

Valid answers:

     => source_vss_working_directory_prompt


=cut

sub source_vss_filespec_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
vss filespec
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', qr/./, 'source_vss_working_directory_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Enter the filespec which may contain trailing wildcards, like "a/b/..."
to extract an entire directory tree.

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=item source_vss_working_directory_prompt: Enter VSS working directory

Used to set the VSS working directory. VCP::Source::vss will cd to
this directory before calling vss, and won't initialize a VSS
workspace of it's own (normally, VCP::Source::vss does a "vss
checkout" in a temporary directory).

Valid answers:

     => dest_prompt


=cut

sub source_vss_working_directory_prompt {
    my ( $ui ) = @_;

    ## Use single-quotish HERE docs as the most robust form of quoting
    ## so we don't have to mess with escaping.
    my $prompt = <<'END_PROMPT';
Enter VSS working directory
END_PROMPT

    chomp $prompt;

    my @valid_answers = (
        [ '', '', 'dest_prompt',
            undef,
        
        ],
    );

    my ( $answer, $answer_record ) =
        $ui->ask( <<'END_DESCRIPTION', $prompt, \@valid_answers );


Used to set the VSS working directory. VCP::Source::vss will cd to
this directory before calling vss, and won't initialize a VSS
workspace of it's own (normally, VCP::Source::vss does a "vss
checkout" in a temporary directory).

    
END_DESCRIPTION

    ## Run handlers for this arc
    $answer_record->[-1]->( $ui, $answer, $answer_record )
        if defined $answer_record->[-1];

    return $answer_record->[-2];  ## The next state
}

=back

=head1 WARNING: AUTOGENERATED

This module is autogenerated in the pre-distribution build process, so
to change it, you need the master repository files in ui_machines/...,
not a CPAN/PPM/tarball/.zip/etc. distribution.

=head1 COPYRIGHT

Copyright 2003, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
