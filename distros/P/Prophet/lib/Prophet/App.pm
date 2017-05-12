package Prophet::App;
{
  $Prophet::App::VERSION = '0.751';
}
use Any::Moose;
use File::Spec ();
use Prophet::Config;
use Prophet::UUIDGenerator;
use Params::Validate qw/validate validate_pos/;

has handle => (
    is      => 'rw',
    isa     => 'Prophet::Replica',
    lazy    => 1,
    default => sub {
        my $self = shift;

        if ( defined $self->local_replica_url
            && $self->local_replica_url !~ /^[\w\+]{2,}\:/ )
        {
            # the reason why we need {2,} is to not match name on windows, e.g. C:\foo
            my $path = $self->local_replica_url;
            $path = File::Spec->rel2abs( glob($path) )
              unless File::Spec->file_name_is_absolute($path);
            $self->local_replica_url("file://$path");
        }

        return Prophet::Replica->get_handle(
            url        => $self->local_replica_url,
            app_handle => $self,
        );
    },
);

has config => (
    is      => 'rw',
    isa     => 'Prophet::Config',
    default => sub {
        my $self = shift;
        return Prophet::Config->new(
            app_handle => $self,
            confname   => 'prophetrc',
        );
    },
    documentation => "This is the config instance for the running application",
);

use constant DEFAULT_REPLICA_TYPE => 'prophet';


sub default_replica_type {
    my $self = shift;
    return $ENV{'PROPHET_REPLICA_TYPE'} || DEFAULT_REPLICA_TYPE;
}


sub local_replica_url {
    my $self = shift;
    if (@_) {
        $ENV{'PROPHET_REPO'} = shift;
    }

    return $ENV{'PROPHET_REPO'} || undef;
}

sub require {
    my $self  = shift;
    my $class = shift;
    $self->_require( module => $class );
}

sub try_to_require {
    my $self  = shift;
    my $class = shift;
    $self->_require( module => $class, quiet => 1 );
}

sub _require {
    my $self  = shift;
    my %args  = ( module => undef, quiet => undef, @_ );
    my $class = $args{'module'};

    # Quick hack to silence warnings.
    # Maybe some dependencies were lost.
    unless ($class) {
        warn sprintf( "no class was given at %s line %d\n", (caller)[ 1, 2 ] );
        return 0;
    }

    return 1 if $self->already_required($class);

    # .pm might already be there in a weird interaction in Module::Pluggable
    my $file = $class;
    $file .= ".pm"
      unless $file =~ /\.pm$/;

    $file =~ s/::/\//g;

    my $retval = eval {
        local $SIG{__DIE__} = 'DEFAULT';
        CORE::require "$file";
    };

    my $error = $@;
    if ( my $message = $error ) {
        $message =~ s/ at .*?\n$//;
        if ( $args{'quiet'} and $message =~ /^Can't locate \Q$file\E/ ) {
            return 0;
        } elsif ( $error !~ /^Can't locate $file/ ) {
            die $error;
        } else {
            warn sprintf( "$message at %s line %d\n", ( caller(1) )[ 1, 2 ] );
            return 0;
        }
    }

    return 1;
}


sub already_required {
    my ( $self, $class ) = @_;

    return 0 if $class =~ /::$/;    # malformed class

    my $path = join( '/', split( /::/, $class ) ) . ".pm";
    return ( $INC{$path} ? 1 : 0 );
}

sub set_db_defaults {
    my $self     = shift;
    my $settings = $self->database_settings;
    for my $name ( keys %$settings ) {
        my ( $uuid, @metadata ) = @{ $settings->{$name} };

        my $s = $self->setting(
            label   => $name,
            uuid    => $uuid,
            default => \@metadata,
        );

        $s->initialize;
    }
}

sub setting {
    my $self = shift;
    my %args = validate( @_, { uuid => 0, default => 0, label => 0 } );
    require Prophet::DatabaseSetting;

    my ( $uuid, $default );

    if ( $args{uuid} ) {
        $uuid    = $args{'uuid'};
        $default = $args{'default'};
    } elsif ( $args{'label'} ) {
        ( $uuid, $default ) =
          @{ $self->database_settings->{ $args{'label'} } };
    }
    return Prophet::DatabaseSetting->new(
        handle  => $self->handle,
        uuid    => $uuid,
        default => $default,
        label   => $args{label}
    );

}

sub database_settings { {} }    # XXX wants a better name

sub log_debug {
    my $self = shift;
    return unless ( $ENV{'PROPHET_DEBUG'} );
    $self->log(@_);
}


sub log {
    my $self = shift;
    my ($msg) = validate_pos( @_, 1 );
    print STDERR $msg . "\n";    # if ($ENV{'PROPHET_DEBUG'});
}


sub log_fatal {
    my $self = shift;

    # always skip this fatal_error function when generating a stack trace
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    $self->log(@_);
    Carp::confess(@_);
}

sub current_user_email {
    my $self = shift;
    return
         $self->config->get( key => 'user.email-address' )
      || $ENV{'PROPHET_EMAIL'}
      || $ENV{'EMAIL'};

}


# friendly names are replica subsections in the config file

use Memoize;
memoize('display_name_for_replica');

sub display_name_for_replica {
    my $self = shift;
    my $uuid = shift;

    return 'Unknown replica!' unless $uuid;
    my %possibilities =
      $self->config->get_regexp( key => '^replica\..*\.uuid$' );

    # form a hash of uuid -> name
    my %sources_by_uuid = map {
        my $uuid = $possibilities{$_};
        $_ =~ /^replica\.(.*)\.uuid$/;
        my $name = $1;
        ( $uuid => $name );
    } keys %possibilities;
    return exists $sources_by_uuid{$uuid} ? $sources_by_uuid{$uuid} : $uuid;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::App

=head1 VERSION

version 0.751

=head1 METHODS

=head2 default_replica_type

Returns a string of the the default replica type for this application.

=head2 local_replica_url

Returns the URL of the current local replica. If no URL has been provided
(usually via C<$ENV{PROPHET_REPO}>), returns undef.

=head2 already_required class

Helper function to test whether a given class has already been require'd.

=head2 log $MSG

Logs the given message to C<STDERR> (but only if the C<PROPHET_DEBUG>
environmental variable is set).

=head2 log_fatal $MSG

Logs the given message and dies with a stack trace.

=head2 display_name_for_replica UUID

Returns a "friendly" id for the replica with the given uuid. UUIDs are for
computers, friendly names are for people. If no name is found, the friendly
name is just the UUID.

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
