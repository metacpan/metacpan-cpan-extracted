package Net::isoHunt::Request;
BEGIN {
  $Net::isoHunt::Request::VERSION = '0.102770';
}

# ABSTRACT: Populates request fields and executes request

use Moose;
use Moose::Util::TypeConstraints;

use URI;
use LWP::UserAgent;
use JSON qw{ decode_json };

has 'ihq' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'start' => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has 'rows' => (
    is      => 'rw',
    isa     => 'Int',
    default => 100,
);

has 'sort' => (
    is  => 'rw',
    isa => enum( [ qw{ seeds age size } ] ),
);

has 'order' => (
    is      => 'rw',
    isa     => enum( [ qw{ asc desc } ] ),
    default => 'desc',
);

sub execute {
    my $self = shift;

    my $api_url    = 'http://isohunt.com/js/json.php';
    my %parametres = (
        'ihq'   => $self->ihq  (),
        'start' => $self->start(),
        'rows'  => $self->rows (),
        'sort'  => $self->sort (),
        'order' => $self->order(),
    );

    for my $key ( keys %parametres ) {
        !defined $parametres{$key} and delete $parametres{$key};
    }

    my $uri = URI->new($api_url);
    $uri->query_form(%parametres);

    my $ua           = LWP::UserAgent->new( 'agent' => 'Net::isoHunt' );
    my $json         = $ua->get($uri)->decoded_content();
    my $json_decoded = decode_json($json);

    my $image = Net::isoHunt::Response::Image->new( {
        'title'  => $json_decoded->{'image'}->{'title'  },
        'url'    => $json_decoded->{'image'}->{'url'    },
        'link'   => $json_decoded->{'image'}->{'link'   },
        'width'  => $json_decoded->{'image'}->{'width'  },
        'height' => $json_decoded->{'image'}->{'height' },
    } );

    my @items;
    for ( @{ $json_decoded->{'items'}->{'list'} } ) {
        my $item = Net::isoHunt::Response::Item->new( {
            'title'         => $_->{'title'        },
            'link'          => $_->{'link'         },
            'guid'          => $_->{'guid'         },
            'enclosure_url' => $_->{'enclosure_url'},
            'length'        => $_->{'length'       },
            'tracker'       => $_->{'tracker'      },
            'tracker_url'   => $_->{'tracker_url'  },
            'kws'           => $_->{'kws'          },
            'exempts'       => $_->{'exempts'      },
            'category'      => $_->{'category'     },
            'original_site' => $_->{'original_site'},
            'original_link' => $_->{'original_link'},
            'size'          => $_->{'size'         },
            'files'         => $_->{'files'        },
            'seeds'         => $_->{'Seeds'        },
            'leechers'      => $_->{'leechers'     },
            'downloads'     => $_->{'downloads'    },
            'votes'         => $_->{'votes'        },
            'comments'      => $_->{'comments'     },
            'hash'          => $_->{'hash'         },
            'pub_date'      => $_->{'pubDate'      },
        } );
        push @items, $item;
    }

    my $response = Net::isoHunt::Response->new( {
        'title'           => $json_decoded->{'title'        },
        'link'            => $json_decoded->{'link'         },
        'description'     => $json_decoded->{'description'  },
        'language'        => $json_decoded->{'language'     },
        'category'        => $json_decoded->{'category'     },
        'max_results'     => $json_decoded->{'max_results'  },
        'ttl'             => $json_decoded->{'ttl'          },
        'last_build_date' => $json_decoded->{'lastBuildDate'},
        'pubDate'         => $json_decoded->{'pubDate'      },
        'total_results'   => $json_decoded->{'total_results'},
        'censored'        => $json_decoded->{'censored'     },
        'image'           => $image,
        'items'           => \@items,
    } );

    return $response;
}

__PACKAGE__->meta()->make_immutable();

no Moose;
no Moose::Util::TypeConstraints;

1;



=pod

=head1 NAME

Net::isoHunt::Request - Populates request fields and executes request

=head1 VERSION

version 0.102770

=head1 ATTRIBUTES

=head2 C<ihq>

Takes URL encoded value as requested search query.

=head2 C<start>

Optional. Starting row number in paging through results set. First page has
C<start=1>, not C<0>. Defaults to C<1>.

=head2 C<rows>

Optional. Results to return, starting from parameter C<start>. Defaults to
C<100>.

=head2 C<sort>

Optional. Defaults to composite ranking (over all factors such as age, query
relevance, seed/leechers counts and votes). Parameter takes only values of
C<seeds>, C<age> or C<size>, where C<seeds> sorting is combination of seeds +
leechers. Sort C<order> defaults to descending.

=head2 C<order>

Optional. Can be either C<asc> or C<desc>. Defaults to descending, in
conjunction with C<sort> parameter.

=head1 METHODS

=head2 C<execute>

Returns a L<Net::isoHunt::Response> object.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

