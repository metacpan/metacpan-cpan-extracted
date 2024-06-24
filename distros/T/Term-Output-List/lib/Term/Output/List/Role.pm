package Term::Output::List::Role;
use 5.020;
use Moo::Role;
use Term::Cap;
use Scalar::Util 'weaken';
use experimental 'signatures';

our $VERSION = '0.05';

=head1 NAME

Term::Output::List::Role - common methods to Term::Output::List implementations

=head1 SYNOPSIS

    my $printer = Term::Output::List->new(
        hook_warnings => 1,
    );
    my @ongoing_tasks = ('file1: frobnicating', 'file2: bamboozling', 'file3: frobnicating');
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

has '_last_lines' => (
    is => 'rw',
);

=head1 MEMBERS

=head2 C<< fh >>

Filehandle used for output. Default is C<< STDOUT >>.

=cut

has 'fh' => (
    is => 'lazy',
    default => sub { \*STDOUT },
);

=head2 C<< interactive >>

Whether the script is run interactively and should output intermittent
updateable information

=cut

has 'interactive' => (
    is => 'lazy',
    default => sub { -t $_[0]->fh },
);

=head2 C<< hook_warnings >>

Install a hook for sending warnings to C<< ->output_permanent >>. This
prevents ugly tearing/overwriting when your code outputs warnings.

=cut

has 'hook_warnings' => (
    is => 'ro',
    default => undef,
);

sub BUILD( $self, $args ) {
    if( $args->{hook_warnings} ) {
        if( ! $SIG{__WARN__}) {
            weaken( my $s = $self );
            $SIG{__WARN__} = sub {
                if( $self ) {
                    my $msg = "@_";
                    $self->output_permanent($msg );
                } else {
                    print STDERR "@_";
                }
            };
        }
    }
}

requires qw( width output_permanent ellipsis );

sub _trim( $self, $item, $width=$self->width ) {
    state $ell = $self->ellipsis;
    if( length($item) > $width - 1 ) {
        return substr($item,0,$width-length($ell)-1).$ell
    } else {
        return $item
    }
}

sub output_list( $self, @items ) {
    if( $self->interactive ) {
        @items = map { s/\r?\n$//r }
                 map { split /\r?\n/ }
                 @items
                 ;
        $self->output_permanent(@items);
        $self->_last_lines( 0+@items );
    }
}

=head2 C<< ->fresh_output >>

  $o->fresh_output();

Helper subroutine to make all items from the last output list remain as is.

For compatibility between output to a terminal and output without a terminal,
you should use C<< ->output_permanent >> for things that should be permanent
instead.

=cut

sub fresh_output( $self ) {
    $self->_last_lines( 0 );
}

1;
