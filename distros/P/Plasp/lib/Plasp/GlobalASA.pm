package Plasp::GlobalASA;

use Path::Tiny;
use File::Slurp qw(read_file);

use Moo;
use Types::Standard qw(InstanceOf Str);
use Types::Path::Tiny qw(Path);
use namespace::clean;

our @Routines = qw(
    Application_OnStart
    Application_OnEnd
    Session_OnStart
    Session_OnEnd
    Script_OnStart
    Script_OnEnd
    Script_OnParse
    Script_OnFlush
);

has 'asp' => (
    is       => 'ro',
    isa      => InstanceOf ['Plasp'],
    required => 1,
    weak_ref => 1,
);

=head1 NAME

Plasp::GlobalASA - global.asa

=head1 SYNOPSIS

  ### in global.asa
  sub Script_OnStart {
    printf STDERR "Executing script: %s\n", $Request->ServerVariables('SCRIPT_NAME');
  }

=head1 DESCRIPTION

The ASP platform allows developers to create Web Applications. In fulfillment of
real software requirements, ASP allows event-triggered actions to be taken,
which are defined in a F<global.asa> file. The global.asa file resides in the
C<Global> directory, defined as a config option, and may define the following actions:

  Action              Event
  ------              ------
  Script_OnStart *    - Beginning of Script execution
  Script_OnEnd *      - End of Script execution
  Script_OnFlush *    - Before $Response being flushed to client.
  Script_OnParse *    - Before script compilation
  Application_OnStart - Beginning of Application
  Application_OnEnd   - End of Application
  Session_OnStart     - Beginning of user Session.
  Session_OnEnd       - End of user Session.

  * These are API extensions that are not portable, but were
    added because they are incredibly useful

These actions must be defined in the C<< "$self->Global/global.asa" >> file as
subroutines, for example:

  sub Session_OnStart {
    $Application->{$Session->SessionID()} = started;
  }

Sessions are easy to understand. When visiting a page in a web application, each
user has one unique C<$Session>. This session expires, after which the user will
have a new C<$Session> upon revisiting.

A web application starts when the user visits a page in that application, and
has a new C<$Session> created. Right before the first C<$Session> is created,
the C<$Application> is created. When the last user C<$Session> expires, that
C<$Application> expires also. For some web applications that are always busy,
the C<Application_OnEnd> event may never occur.

=cut

has 'filename' => (
    is      => 'ro',
    isa     => Path,
    default => sub { shift->asp->Global->child( 'global.asa' ) },
    coerce  => Path->coercion,
);

has 'package' => (
    is  => 'lazy',
    isa => Str,
);

sub _build_package {
    my ( $self ) = @_;
    my $asp      = $self->asp;
    my $id       = $asp->file_id( $asp->Global, 1 );
    return $asp->GlobalPackage || "Plasp::Compiles::$id";
}

sub BUILD {
    my ( $self ) = @_;
    my $asp = $self->asp;

    return unless $self->exists;

    my $package      = $self->package;
    my $filename     = $self->filename->stringify;
    my $global       = $asp->Global;
    my $code         = read_file( $filename );
    my $match_events = join '|', @Routines;
    $code =~ s/\<script[^>]*\>((.*)\s+sub\s+($match_events).*)\<\/script\>/$1/isg;
    $code = join( '',
        "\n#line 1 $filename\n",
        join( ' ;; ',
            "package $package;",
            'no strict;',
            'use vars qw(' . join( ' ', map {"\$$_"} @Plasp::Objects ) . ');',
            "use lib qw($global);",
            $code,
            'sub exit { $main::Response->End(); }',
            "no lib qw($global);",
            '1;',
        )
    );
    $code =~ /^(.*)$/s;    # Realized this is for untainting
    $code = $1;

    no warnings;
    eval $code;            ## no critic (BuiltinFunctions::ProhibitStringyEval)
    if ( $@ ) {
        $self->error( "Error on compilation of global.asa: $@" );    # don't throw error, so we can throw die later
    }
}

sub exists { shift->filename->exists }

=head1 METHODS

=over

=item $self->execute_event($event);

Execute the event defined in F<global.asa>

=cut

sub execute_event {
    my ( $self, $event ) = @_;
    my $asp = $self->asp;
    $asp->execute( $event ) if "$self->package"->can( $event );
}

=item Application_OnStart

This event marks the beginning of an ASP application, and is run just before the
C<Session_OnStart> of the first Session of an application. This event is useful
to load up C<$Application> with data that will be used in all user sessions.

=cut

sub Application_OnStart {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Application_OnStart' ) );
}

=item Application_OnEnd

The end of the application is marked by this event, which is run after the last
user session has timed out for a given ASP application.

=cut

sub Application_OnEnd {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Application_OnEnd' ) );
}

=item Session_OnStart

Triggered by the beginning of a user's session, C<Session_OnStart> gets run
before the user's executing script, and if the same session recently timed out,
after the session's triggered C<Session_OnEnd>.

The C<Session_OnStart> is particularly useful for caching database data, and
avoids having the caching handled by clumsy code inserted into each script being
executed.

=cut

sub Session_OnStart {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Session_OnStart' ) );
}

=item Session_OnEnd

Triggered by a user session ending, C<Session_OnEnd> can be useful for cleaning
up and analyzing user data accumulated during a session.

Sessions end when the session timeout expires, and the C<StateManager> performs
session cleanup. The timing of the C<Session_OnEnd> does not occur immediately
after the session times out, but when the first script runs after the session
expires, and the C<StateManager> allows for that session to be cleaned up.

So on a busy site with default C<SessionTimeout> (20 minutes) and
C<StateManager> (10 times) settings, the C<Session_OnEnd> for a particular
session should be run near 22 minutes past the last activity that Session saw.
A site infrequently visited will only have the C<Session_OnEnd> run when a
subsequent visit occurs, and theoretically the last session of an application
ever run will never have its C<Session_OnEnd> run.

Thus I would not put anything mission-critical in the C<Session_OnEnd>, just
stuff that would be nice to run whenever it gets run.

=cut

sub Session_OnEnd {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Session_OnEnd' ) );
}

=item Script_OnStart

The script events are used to run any code for all scripts in an application
defined by a F<global.asa>. Often, you would like to run the same code for every
script, which you would otherwise have to add by hand, or add with a file
include, but with these events, just add your code to the F<global.asa>, and it
will be run. This runs before a script is executed.

=cut

sub Script_OnStart {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Script_OnStart' ) );
}

=item Script_OnEnd

Like C<Script_OnStart> except at the end.

There is one caveat. Code in C<Script_OnEnd> is not guaranteed to be run when
C<< $Response->End() >> is called, since the program execution ends immediately
at this event. To always run critical code, use the API extension:

  $Server->RegisterCleanup()

=cut

sub Script_OnEnd {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Script_OnEnd' ) );
}

=item Script_OnParse

This event allows one to set up a source filter on the script text, allowing one
to change the script on the fly before the compilation stage occurs. The script
text is available in the C<< $Server->{ScriptRef} >> scalar reference, and can
be accessed like so:

 sub Script_OnParse {
   my $code = $Server->{ScriptRef}
   $$code .= " ADDED SOMETHING ";
 }

=cut

sub Script_OnParse {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Script_OnParse' ) );
}

=item Script_OnFlush

API extension. This event will be called prior to flushing the C<$Response>
buffer to the web client. At this time, the C<< $Response->{BinaryRef} >> buffer
reference may be used to modify the buffered output at runtime to apply global
changes to scripts output without having to modify all the scripts.

  sub Script_OnFlush {
    my $ref = $Response->{BinaryRef};
    $$ref =~ s/\s+/ /sg; # to strip extra white space
  }

=cut

sub Script_OnFlush {
    my ( $self ) = @_;
    $self->execute_event( join( '::', $self->package, 'Script_OnFlush' ) );
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp>

=back
