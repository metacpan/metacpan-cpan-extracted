package Pod::Readme::Plugin::version;

use Moo::Role;

our $VERSION = 'v1.2.1';

use ExtUtils::MakeMaker;
use Types::Standard qw/ Bool Str /;

use Pod::Readme::Types qw/ File HeadingLevel /;

=head1 NAME

Pod::Readme::Plugin::version - Include version in README

=head1 SYNOPSIS

  =for readme plugin version

=head1 DESCRIPTION

This is a plugin for L<Pod::Readme> that includes the release version.

=head1 ARGUMENTS

=head2 C<file>

  =for readme plugin version file='lib/My/App.pm'

By default, it will extract the version from the same file that the
F<README> is being extracted from.  If this is a different file, then
it should be specified.

=head2 C<title>

  =for readme plugin version title='VERSION'

This argument allows you to change the title of the heading.

=cut

requires 'parse_cmd_args';

has 'version_file' => (
    is       => 'rw',
    isa      => File,
    required => 0,
    coerce   => sub { File->coerce(@_) },
    lazy     => 1,
    default  => sub {
        my ($self) = @_;
        $self->input_file;
    },
);

has 'version_title' => (
    is      => 'rw',
    isa     => Str,
    default => 'VERSION',
    lazy    => 1,
);

has 'version_heading_level' => (
    is      => 'rw',
    isa     => HeadingLevel,
    default => 1,
    lazy    => 1,
);

has 'version_run' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    lazy    => 1,
);

around 'depends_on' => sub {
    my ($orig, $self) = @_;
    return ($self->version_file, $self->$orig);
};

sub cmd_version {
    my ( $self, @args ) = @_;

    die "The version plugin can only be used once" if $self->version_run;

    my $res = $self->parse_cmd_args( [qw/ file title heading-level /], @args );
    foreach my $key ( keys %{$res} ) {
        ( my $name = "version_${key}" ) =~ s/-/_/g;
        if ( my $method = $self->can($name) ) {
            $self->$method( $res->{$key} );
        }
        else {
            die "Invalid key: '${key}'";
        }
    }

    if ( my $file = $self->version_file ) {

        my $heading = $self->can( "write_head" . $self->version_heading_level )
          or die "Invalid heading level: " . $self->version_heading_level;

        $self->$heading( $self->version_title );
        $self->write_para( MM->parse_version($file) );

        $self->version_run(1);

    }
    else {

        die "Don't know what file to determine the version from";

    }
}

use namespace::autoclean;

1;
