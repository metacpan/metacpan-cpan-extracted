package Pcore::Util::HTML;

use Pcore;
use HTML5::DOM qw[];

my $SEM = Coro::Semaphore->new( P->sys->cpus_num );
my @PARSERS;

sub tree ( $html, %args ) {
    my $guard = $SEM->guard;

    my $parser = pop @PARSERS;

    $parser //= HTML5::DOM->new( { utf8 => 1 } );

    my $cv = P->cv;

    $parser->parseAsync( $html, \%args, sub { $cv->( $_[0] ) } );

    my $tree = $cv->recv;

    push @PARSERS, $parser;

    return $tree;
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
