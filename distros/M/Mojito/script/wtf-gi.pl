use strictures 1;
use 5.010;
use Getopt::Long;
use Data::Dumper::Concise;

=head1 Name

wtf-gi.pl - a script to generate dispatcher subs

=head1 Usage

    perl -Ilib script/wtf-gi.pl --name PublishPage --transform web_simple
    
=cut

my ( $name, $transform );

my $result = GetOptions(
    'name|n=s'      => \$name,
    'transform|t=s' => \$transform,
);

# prefix tranform
$transform = 'transform_' . $transform;

my $messages = [
    {
        name           => 'EPubCollection',
        request_method => 'get',
        route          => '/collection/:id/epub',
        response       => '$mojito->epub_collection($params)',
        response_type  => 'application/octet-stream',
        status_code    => 200,
    },
    {
        name           => 'DeleteCollection',
        request_method => 'get',
        route          => '/collection/:id/delete',
        response       => '$mojito->delete_collection($params)',
        response_type  => 'redirect',
        status_code    => 301,
    },
    {
        name           => 'ViewPage',
        request_method => 'get',
        route          => '/page/:id',
        response       => '$mojito->view_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'EditPage',
        request_method => 'get',
        route          => '/page/:id/edit',
        response       => '$mojito->edit_page_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'EditPage',
        request_method => 'post',
        route          => '/page/:id/edit',
        response       => '$mojito->edit_page($params)',
        response_type  => 'redirect',
        status_code    => 302,
    },
    {
        name           => 'SearchPage',
        request_method => 'get',
        route          => '/search/:word',
        response       => '$mojito->search($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'SearchPage',
        request_method => 'post',
        route          => '/search',
        response       => '$mojito->search($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'LastDiffPage',
        request_method => 'get',
        route          => '/page/:id/diff',
        response       => '$mojito->view_page_diff($params)',
        response_type  => 'html',
    },
    {
        name           => 'DiffPage',
        route          => '/page/:id/diff/:m/:n',
        request_method => 'get',
        response       => '$mojito->diff_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectPage',
        request_method => 'get',
        route          => '/collect',
        response       => '$mojito->collect_page_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectPage',
        request_method => 'post',
        route          => '/collect',
        response       => '$mojito->collect($params)',
        response_type  => 'redirect',
        status_code    => 301,
    },
    {
        name           => 'CollectionsIndex',
        route          => '/collections',
        request_method => 'get',
        response       => '$mojito->collections_index()',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectionPage',
        route          => '/collection/:id',
        request_method => 'get',
        response       => '$mojito->collection_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'PublicCollectionPage',
        route          => '/public/collection/:id',
        request_method => 'get',
        response       => '$mojito->collection_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'SortCollection',
        route          => '/collection/:id/sort',
        request_method => 'get',
        response       => '$mojito->sort_collection_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'SortCollection',
        route          => '/collection/:id/sort',
        request_method => 'post',
        response       => '$mojito->sort_collection($params)',
        response_type  => 'redirect',
        status_code    => 301,
    },
    {
        name           => 'PublishPage',
        route          => '/publish',
        request_method => 'post',
        response       => '$mojito->publish_page($params)',
        response_type  => 'json',
        status_code    => 200,
    },
    {
        name           => 'CollectedPage',
        route          => '/collection/:collection_id/page/:page_id',
        request_method => 'get',
        response       => '$mojito->view_page_collected($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'PublicCollectedPage',
        route          => '/public/collection/:collection_id/page/:page_id',
        request_method => 'get',
        response       => '$mojito->view_page_collected($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CalendarMonth',
        route          => '/calendar/year/:year/month/:month',
        request_method => 'get',
        response       => '$mojito->calendar_month_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'DefaultCalendarMonth',
        route          => '/calendar',
        request_method => 'get',
        response       => '$mojito->calendar_month_page',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'MergeCollection',
        route          => '/collection/:collection_id/merge',
        request_method => 'get',
        response       => '$mojito->merge_collection($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'Paste',
        route          => '/paste',
        request_method => 'get',
        response       => '$mojito->get_paste_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },    
    {
        name           => 'FeedPage',
        route          => '/public/feed/:feed_name/format/:feed_format',
        request_method => 'get',
        response       => '$mojito->feed_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
];

sub get_messages_by_name {
    my $name          = shift;
    
    my @pages         = grep { $_->{name} =~ m/^$name$/ } @{$messages};
    my $message_count = scalar @pages;
    die "NEED exactly one or two messages by name. Found ", $message_count
      if ( $message_count != 1 && $message_count != 2 );
      
    return \@pages;
}

my %transforms = (
    transform_web_simple => \&transform_web_simple,
    transform_dancer     => \&transform_dancer,
    transform_mojo       => \&transform_mojo,
    transform_tatsumaki  => \&transform_tatsumaki,
);

sub transform_message_by_framework {
    my ( $message, $framework ) = ( shift, shift );
    my $transformer = 'transform_' . $framework;
    say $transforms{$transformer}->($message);
}

if ($name) {
    $messages = get_messages_by_name($name);
}
if ($transform) {
    %transforms =
      map { $_, $transforms{$_} } grep { $_ eq $transform; } keys %transforms;
}
foreach my $message ( @{$messages} ) {
    foreach my $transform ( keys %transforms ) {
        say $transforms{$transform}->($message);
    }
}

sub transform_dancer {
    my $message = shift;

    my $response;
    if ( $message->{response_type} eq 'html' ) {
        $response = 'return ' . $message->{response};
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $response = 'redirect ' . $message->{response};
    }
    elsif ( $message->{response_type} =~ m/json/i ) {
      $response = 'to_json( ' . $message->{response} . ' )';
    }
    $response =~ s/\$params/scalar params/;

    my $route_body = <<"END_BODY";
$message->{request_method} '$message->{route}' => sub {
    $response;
};
END_BODY

    return $route_body;
}

sub transform_mojo {
    my $message = shift;

    my $message_response = $message->{response};
    $message_response =~ s/\$mojito->/mojito->/;
    my $response;
    if ( $message->{response_type} eq 'html' ) {
        $response = '$self->render( text => $self->' . $message_response . ' )';
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $response = '$self->redirect_to(' . $message_response . ')';
    }
    elsif ( $message->{response_type} =~ m/json/i ) {
        $response = '$self->render( json => $self' . $message_response . ' )';
    }
    my $place_holders;
    my @place_holders;
    if ( my @holders = $message->{route} =~ m/\/\:(\w+)/g ) {
        unshift @place_holders, 'my $params;';
        foreach my $holder (@holders) {
            push @place_holders, '$params->{' . $holder . '} = $self->param(\'' . $holder . q|');|;
            $place_holders = join "\n    ", @place_holders;
        }
    }
    if ($place_holders) {
        chomp($place_holders);
    }
    else {
        $place_holders = '# no place holders';
    }

    my $route_body = <<"END_BODY";
$message->{request_method} '$message->{route}' => sub {
    my (\$self) = (shift);
    $place_holders
    $response;
};
END_BODY

}

sub transform_tatsumaki {
    my $message = shift;

    my $message_response = $message->{response};
    $message_response =~ s/\$mojito/\$self->request->env->{'mojito'}/;
    my $message_route = $message->{route};
    my ( $args, $params ) = route_handler( $message->{route}, 'tatsumaki' );
    my $request_params = '';
    $request_params =
'@{$params}{ keys %{$self->request->parameters} } = values %{$self->request->parameters};'
      if ( $message->{request_method} =~ m/post/i );
    my $route_body;

    if ( $message->{response_type} eq 'redirect' ) {
        $route_body = <<"END_BODY";
package $message->{name};
use parent qw(Tatsumaki::Handler);

sub $message->{request_method} {
    my (\$self, $args) = \@_;
    $params
    $request_params
    my \$redirect_url = $message_response;
    \$self->response->redirect(\$redirect_url);
}
END_BODY
    }
    elsif ( $message->{response_type} =~ m/json/i ) {
        $route_body = <<"END_BODY";
package $message->{name};
use parent qw(Tatsumaki::Handler);

sub $message->{request_method} {
    my (\$self, $args) = \@_;
    \$self->response->content_type('application/json');
    \$self->write(
        JSON::encode_json(
           $message_response; 
        )
    );
}
END_BODY
    }
    else {
        $route_body = <<"END_BODY";
package $message->{name};
use parent qw(Tatsumaki::Handler);

sub $message->{request_method} {
    my ( \$self, $args ) = \@_;
    $params
    \$self->write($message_response);
}
END_BODY
    }
    return $route_body;
}

sub transform_web_simple {
    my $message = shift;

    my $message_response = $message->{response};
    my $content_type     = "['Content-type', ";
    $content_type .= "'text/html']" if ( $message->{response_type} eq 'html' );
    my $request_method = uc( $message->{request_method} );
    my $message_route  = $message->{route};
    my ( $args, $params ) = route_handler( $message_route, 'simple' );
    $message_route =~ s/\:\w+/*/g;
    $message_route .= ' + %*' if ( $request_method eq 'POST' );
    my $route_body;

    if ( $message->{response_type} eq 'redirect' ) {
        $route_body = <<"END_BODY";
sub ( $request_method + $message_route ) {
    my (\$self, $args) = \@_;
    $params
    my \$redirect_url = $message_response;
    [ 301, [ Location => \$redirect_url ], [] ];
},

END_BODY
    }
    else {
        $route_body = <<"END_BODY";
sub ( $request_method + $message_route ) {
    my (\$self, $args) = \@_;
    $params
    my \$output = $message_response;
    [ $message->{status_code}, $content_type, [\$output] ];
},

END_BODY
    }
    return $route_body;
}

sub route_handler {
    my ( $route, $framework ) = ( shift, shift );

    my ( $args, $params ) = ('', '');
    given ($framework) {
        when (/simple|tatsumaki/i) {

            # find placeholders
            if (my @place_holders = $route =~ m/\:(\w+)/ig) {
                my @args = map { '$' . $_ } @place_holders;
                $args = join ', ', @args;
                my @params =
                  map { '$params->{' . $_ . '} = $' . $_ . ';' } @place_holders;
                unshift @params, 'my $params;';
                $params = join "\n    ", @params;
            }
            else {
                $params = '# no place holders';
            }
        }
    }
    return ( $args, $params );
}
