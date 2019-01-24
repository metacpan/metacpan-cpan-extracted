package Pcore::Util::HTML;

use Pcore;
use Pcore::Util::Scalar qw[is_callback];
use Coro::Signal qw[];
use HTML5::DOM qw[];

our $MAX_THREADS = P->sys->cpus_num;

my @QUEUE;
my $THREADS = 0;
my $SIGNAL  = Coro::Signal->new;

sub tree ( $html, @args ) {
    my $cv;

    my $cb = is_callback $args[-1] ? pop @args : undef;

    if ( defined wantarray ) {
        $cv = P->cv;

        push @QUEUE, [
            $html,
            {@args},
            sub ($tree) {
                $tree = $cb->($tree) if $cb;

                $cv->($tree);

                return;
            }
        ];
    }
    else {
        push @QUEUE, [ $html, {@args}, $cb ];
    }

    if ( $SIGNAL->awaited ) {
        $SIGNAL->send;
    }
    elsif ( $THREADS < $MAX_THREADS ) {
        _run_parse_thread();
    }

    return defined $cv ? $cv->recv : ();
}

sub _run_parse_thread {
    $THREADS++;

    Coro::async_pool {
        my $parser = HTML5::DOM->new( { utf8 => 1 } );

        while () {
            if ( my $task = shift @QUEUE ) {
                my $cv = P->cv;

                $parser->parseAsync( $task->[0], $task->[1], sub { $cv->send( $_[0] ) } );

                $task->[2]->( $cv->recv );

                next;
            }

            $SIGNAL->wait;
        }

        $THREADS--;

        return;
    };

    return;
}

# TODO remove
# sub _build_tree_xpath ($self) {
#     return if !$self->{data};

#     return if !is_plain_scalarref $self->{data};

#     require HTML::TreeBuilder::LibXML;

#     my $tree = HTML::TreeBuilder::LibXML->new;

#     $tree->parse( $self->decoded_data );

#     $tree->eof;

#     return $tree;
# }

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::HTML

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
