package Pod::Readme::Plugin::changes;

use Moo::Role;

our $VERSION = 'v1.2.1';

use CPAN::Changes 0.30;
use Path::Tiny;
use Types::Standard qw/ Bool Str /;

use Pod::Readme::Types qw/ File HeadingLevel /;

=head1 NAME

Pod::Readme::Plugin::changes - Include latest Changes in README

=head1 SYNOPSIS

  =for readme plugin changes

=head1 DESCRIPTION

This is a plugin for L<Pod::Readme> that includes the latest release
of a F<Changes> file that conforms to the L<CPAN::Changes::Spec>.

=head1 ARGUMENTS

Defaults can be overridden with optional arguments.

Note that changing arguments may change later calls to this plugin.

=head2 C<file>

  =for readme plugin changes file='Changes'

If the F<Changes> file has a non-standard name or location in the
distribution, you can specify an alternative name.  But note that it
I<must> conform the the L<CPAN::Changes::Spec>.

=head2 C<heading-level>

  =for readme plugin changes heading-level=1

This changes the heading level. (The default is 1.)

=head2 C<title>

  =for readme plugin changes title='RECENT CHANGES'

This option allows you to change the title of the heading.

=head2 C<verbatim>

  =for readme plugin changes verbatim

If you prefer, you can display a verbatim section of the F<Changes>
file.

By default, the F<Changes> file will be parsed and reformatted as POD
(equivalent to the C<no-verbatim> option).

=cut

requires 'parse_cmd_args';

has 'changes_file' => (
    is      => 'rw',
    isa     => File,
    coerce  => sub { File->coerce(@_) },
    default => 'Changes',
    lazy    => 1,
);

has 'changes_title' => (
    is      => 'rw',
    isa     => Str,
    default => 'RECENT CHANGES',
    lazy    => 1,
);

has 'changes_verbatim' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    lazy    => 1,
);

has 'changes_heading_level' => (
    is      => 'rw',
    isa     => HeadingLevel,
    default => 1,
    lazy    => 1,
);

has 'changes_run' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    lazy    => 1,
);

around 'depends_on' => sub {
    my ($orig, $self) = @_;
    return ($self->changes_file, $self->$orig);
};

sub cmd_changes {
    my ( $self, @args ) = @_;

    die "The changes plugin can only be used once" if $self->changes_run;

    my $res = $self->parse_cmd_args(
        [qw/ file title verbatim no-verbatim heading-level /], @args );
    foreach my $key ( keys %{$res} ) {
        ( my $name = "changes_${key}" ) =~ s/-/_/g;
        if ( my $method = $self->can($name) ) {
            $self->$method( $res->{$key} );
        }
        else {
            die "Invalid key: '${key}'";
        }
    }

    my $file = path( $self->base_dir, $self->changes_file );

    my %opts;
    if ($self->zilla) {
      $opts{next_token} = qr/\{\{\$NEXT}}/;
    }

    my $changes = CPAN::Changes->load($file, %opts);
    my $latest  = ( $changes->releases )[-1];

    my $heading = $self->can( "write_head" . $self->changes_heading_level )
      or die "Invalid heading level: " . $self->changes_heading_level;

    $self->$heading( $self->changes_title );

    if ( $self->changes_verbatim ) {

        $self->write_verbatim( $latest->serialize );

    }
    else {

        foreach my $group ( $latest->groups ) {

            $self->write_head2($group)
              if ( $group ne '' );

            $self->write_over(4);
            foreach my $items ( $latest->get_group($group)->changes ) {
                foreach my $item ( @{$items} ) {
                    $self->write_item('* ');
                    $self->write_para($item);
                }
            }
            $self->write_back();

        }

    }

    $self->write_para(
        sprintf( 'See the F<%s> file for a longer revision history.',
            $file->basename )
    );

    $self->changes_run(1);
}

use namespace::autoclean;

1;
