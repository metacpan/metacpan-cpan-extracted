package Text::Search::SQL;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Carp;
use Data::Dump qw(pp);

use Parley::Version;  our $VERSION = $Parley::VERSION;

sub new {
    my ($proto, $options) = @_;

    my $defaults = {
        search_term     => undef,
        search_type     => '=',
        search_fields   => [],
    };

    my $self = bless $defaults, ref($proto) || $proto;

    # slip in the options passed to us
    while (my ($k,$v) = each %{$options}) {
        if (exists $defaults->{$k}) {
            if (not ref($self->{$k})) {
                $self->{$k} = $v;
            }
            elsif ( ref $self->{$k} and (ref($v) eq ref($self->{$k}))) {
                $self->{$k} = $v;
            }
            else {
                Carp::carp( qq{'$k' should be of type } . ref($self->{$k}) );
            }
        }
        else {
            Carp::carp( qq{unknown option '$k'} );
        }
    }

    return $self;
}

sub set_search_term {
    my ($self, $value) = @_;

    $self->{search_term} = $value;
}
sub get_search_term {
    my ($self) = @_;
    return $self->{search_term};
}

sub set_search_type {
    my ($self, $value) = @_;

    $self->{search_type} = $value;
}
sub get_search_type {
    my ($self) = @_;
    return $self->{search_type};
}

sub set_search_fields {
    my ($self, $value) = @_;

    $self->{search_fields} = $value;
}
sub get_search_fields {
    my ($self) = @_;
    return $self->{search_fields};
}

sub set_chunks {
    my ($self, $value) = @_;

    $self->{chunks} = $value;
}
sub get_chunks {
    my ($self) = @_;
    return $self->{chunks};
}

sub set_sql_where {
    my ($self, $value) = @_;

    $self->{sql_where} = $value;
}
sub get_sql_where {
    my ($self) = @_;
    return $self->{sql_where};
}

sub parse {
    my ($self) = @_;
    my ($fields, $clauses, $search_type, $chunks);

    $search_type = $self->get_search_type();

    # split the search term into its relevant chunks
    $self->set_chunks( $self->_parse_chunks( $self->{search_term} ) );

    # can't do anything more if we don't have search_fields
    $fields = $self->get_search_fields();
    if (not @{$fields}) {
        Carp::carp( qq{no search_fields defined, cannot prepare SQL::Abstract data} );
        return;
    }

    # get the chunks
    $chunks = $self->get_chunks();
    # if we're doing a "like" match, then wrap the terms in %...%
    if ($search_type =~ m{\A(?:ilike|like)\z}xms) {
        @{ $chunks } = map (qq{%$_%}, @{ $chunks });
    }

    # build there where-clause
    foreach my $field ( @{$fields} ) {
        push @{ $clauses },
            $field => { $search_type => $chunks }
        ;
    }

    $self->{sql_where} = $clauses;

    return 1;
}

sub _parse_chunks {
    my ($self, $string) = @_;
    my (@chunks, @quotes);

    # we only group with double quotes
    @quotes = qw( " );

    # pull out quoted groups of words
    foreach my $quote (@quotes) {
        while ($string =~ s{${quote}(.+?)${quote}}{ }g) {
            push @chunks, $1;
        }
    }

    # strip leading and trailing whitespace
    $string =~ s{\A\s+}{};
    $string =~ s{\s+\z}{};

    # split on whitespace - how naive!
    push @chunks, split( m{\s+}, $string );

    return \@chunks;
}


1;

__END__

=pod

=head1 NAME

Text::Search::SQL - split search terms into something that can be used with DBIx::Class or SQL::Abstract

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=cut
