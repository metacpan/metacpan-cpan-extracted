package Net::IMAP::Server::Command::List;

use warnings;
use strict;

use base qw/Net::IMAP::Server::Command/;

use Encode;
use Encode::IMAPUTF7;

sub validate {
    my $self = shift;

    return $self->bad_command("Log in first") if $self->connection->is_unauth;

    my @options = $self->parsed_options;
    return $self->bad_command("Not enough options") if @options < 2;
    return $self->bad_command("Too many options") if @options > 2;

    return 1;
}

sub run {
    my $self = shift;

    my ( $root, $search ) = $self->parsed_options;

    # In the special case of a query for the delimiter, give them our delimiter
    if ( $search eq "" ) {
        my $sep = (defined $self->connection->model->root->separator)
            ? q{"}.$self->connection->model->root->separator.q{"} : "NIL";
        $self->tagged_response( qq|(\\Noselect) $sep ""| );
    } else {
        my $sep = $self->connection->model->root->separator;
        $search = quotemeta($search);
        $search =~ s/\\\*/.*/g;
        if (defined $sep) {
            $search =~ s/\\%/[^$sep]*/g;
        } else {
            $search =~ s/\\%/.*/g;
        }
        my $regex = qr{^\Q$root\E$search$};
        $self->connection->model->root->update_tree;
        $self->traverse( $self->connection->model->root, $regex );
    }

    $self->ok_completed;
}

sub list_out {
    my $self = shift;
    my $node = shift;
    my @props = @_;

    my $str = $self->data_out([map {\$_} @props]) . " "
        . $self->data_out($self->connection->model->root->separator) . " "
        . $self->data_out(Encode::encode('IMAP-UTF-7',$node->full_path));
    $self->tagged_response($str);
}

sub traverse {
    my $self  = shift;
    my $node  = shift;
    my $regex = shift;

    my @props;
    push @props, @{$node->children} ? '\HasChildren' : '\HasNoChildren';
    push @props, '\Noinferiors' unless defined $self->connection->model->root->separator;
    push @props, '\Noselect' unless $node->is_selectable;

    $self->list_out($node, @props) if $node->parent and 
        Encode::encode('IMAP-UTF-7',$node->full_path) =~ $regex;
    $self->traverse( $_, $regex ) for @{ $node->children };
}

1;
