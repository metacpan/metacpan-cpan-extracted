package Pg::CLI::Role::Connects;
{
  $Pg::CLI::Role::Connects::VERSION = '0.11';
}

use Moose::Role;

use namespace::autoclean;

use IPC::Run3 qw( run3 );
use MooseX::Params::Validate qw( validated_hash validated_list );
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( ArrayRef Bool Defined Str );

with 'Pg::CLI::Role::HasVersion';

for my $attr (qw( username password host port )) {
    has $attr => (
        is        => 'rw',
        isa       => Str,
        predicate => '_has_' . $attr,
    );
}

has require_ssl => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub run {
    my $self = shift;
    my ( $database, $options, $stdin, $stdout, $stderr ) = validated_list(
        \@_,
        database => { isa => Str, optional => 1 },
        options  => {
            isa => ArrayRef [Str], default => [],
        },
        stdin  => { isa => Defined, optional => 1 },
        stdout => { isa => Defined, optional => 1 },
        stderr => { isa => Defined, optional => 1 },
    );

    $self->_execute_command(
        [
            $self->executable(),
            $self->_connect_options(),
            $self->_run_options($database),
            @{$options},
            ( $database && $self->_database_at_end() ? $database : () ),
        ],
        $stdin, $stdout, $stderr,
    );
}

sub _database_at_end {
    return 1;
}

sub _run_options {
    return;
}

sub _execute_command {
    my $self = shift;

    local $ENV{PGPASSWORD} = $self->password()
        if $self->_has_password();

    local $ENV{PGSSLMODE} = 'require'
        if $self->require_ssl();

    $self->_call_run3(@_);
}

# This is a separate sub to provide something we can override in testing
sub _call_run3 {
    shift;
    my $cmd    = shift;
    my $stdin  = shift || \undef;
    my $stdout = shift || \undef;
    my $stderr = shift || \undef;

    run3(
        $cmd,
        $stdin,
        $stdout,
        $stderr,
    );
}

sub _connect_options {
    my $self = shift;

    my @options;

    push @options, '-U', $self->username()
        if $self->_has_username();

    push @options, '-h', $self->host()
        if $self->_has_host();

    push @options, '-p', $self->port()
        if $self->_has_port();

    push @options, '-w'
        if $self->two_part_version >= 8.4;

    return @options;
}

1;
