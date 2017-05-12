package Net::StackExchange::Answers::Response;
BEGIN {
  $Net::StackExchange::Answers::Response::VERSION = '0.102740';
}

# ABSTRACT: Accessors for a set of answers

use Moose;
use Moose::Util::TypeConstraints;

with 'Net::StackExchange::Role::Response';

has 'json' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'answers' => (
    is     => 'ro',
    isa    => 'ArrayRef[Net::StackExchange::Answers]',
    writer => 'set_answers',
    reader => 'get_answers',
);

has '_json_decoded' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    trigger  => sub {
        my $self = shift;

        _populate_answers_object($self);
    },
);

has '_NSE' => (
    is       => 'rw',
    isa      => 'Net::StackExchange',
    required => 1,
);

sub _populate_answers_object {
    my $self = shift;
    my $json = $self->json();

    my $json_decoded = $self->_json_decoded();

    my @answers;
    for my $answer_ref ( @{ $json_decoded->{'answers'} } ) {
        my $owner_ref = $answer_ref->{'owner'};

        my $user = Net::StackExchange::Owner->new(
            'user_id'      => $owner_ref->{'user_id'     },
            'user_type'    => $owner_ref->{'user_type'   },
            'display_name' => $owner_ref->{'display_name'},
            'reputation'   => $owner_ref->{'reputation'  },
            'email_hash'   => $owner_ref->{'email_hash'  },
        );

        my $locked_date        = $answer_ref->{'locked_date'       };
        my $last_edit_date     = $answer_ref->{'last_edit_date'    };
        my $body               = $answer_ref->{'body'              };
        my $last_activity_date = $answer_ref->{'last_activity_date'};

        $locked_date        = defined $locked_date    ? $locked_date    : 0;
        $last_edit_date     = defined $last_edit_date ? $last_edit_date : 0;
        $body               = defined $body           ? $body           : 0;
        $last_activity_date = defined $last_activity_date ?
                                      $last_activity_date : 0;

        my $answers = Net::StackExchange::Answers->new( {
            '_NSE'                => $self->_NSE(),
            'answer_id'           => $answer_ref->{'answer_id'          },
            'accepted'            => $answer_ref->{'accepted'           },
            'answer_comments_url' => $answer_ref->{'answer_comments_url'},
            'question_id'         => $answer_ref->{'question_id'        },
            'locked_date'         => $locked_date,
            'owner'               => $user,
            'creation_date'       => $answer_ref->{'creation_date'      },
            'last_edit_date'      => $last_edit_date,
            'last_activity_date'  => $last_activity_date,
            'up_vote_count'       => $answer_ref->{'up_vote_count'      },
            'down_vote_count'     => $answer_ref->{'down_vote_count'    },
            'view_count'          => $answer_ref->{'view_count'         },
            'score'               => $answer_ref->{'score'              },
            'community_owned'     => $answer_ref->{'community_owned'    },
            'title'               => $answer_ref->{'title'              },
            'body'                => $body,
        } );

        push @answers, $answers;
    }
    $self->set_answers( \@answers );
}

sub answers {
    my ( $self, $nth ) = @_;
    my $answers = $self->get_answers();

    if ( defined $nth ) {
        return $answers->[$nth];
    }
    else {
        return $answers;
    }
}

__PACKAGE__->meta()->make_immutable();

no Moose;
no Moose::Util::TypeConstraints;

1;



=pod

=head1 NAME

Net::StackExchange::Answers::Response - Accessors for a set of answers

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

    use Net::StackExchange;

    my $se = Net::StackExchange->new( {
        'network' => 'stackoverflow.com',
        'version' => '1.0',
    } );

    my $answers_route   = $se->route('answers');
    my $answers_request = $answers_route->prepare_request( { 'id' => '1036353' } );

    my $answers_response = $answers_request->execute( );
    print "Total: ",     $answers_response->total   (), "\n";
    print "Page: ",      $answers_response->page    (), "\n";
    print "Page size: ", $answers_response->pagesize(), "\n";

=head1 ATTRIBUTES

=head2 C<json>

Returns JSON returned by the StackExchange API.

=head1 METHODS

=head2 C<answers>

Returns a list of L<Net::StackExchange::Answers> objects.

=head1 CONSUMES ROLES

L<Net::StackExchange::Role::Response>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

