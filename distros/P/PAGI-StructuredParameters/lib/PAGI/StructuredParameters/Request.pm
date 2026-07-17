package PAGI::StructuredParameters::Request;
$PAGI::StructuredParameters::Request::VERSION = '0.001001';
use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::StructuredParameters;

# A request-bound strong-parameters object. Because reading a PAGI request body
# is asynchronous, the terminal permitted/required are async: they materialize
# the source hash from the request, build a (synchronous) PAGI::StructuredParameters
# engine, and delegate. The configuration methods are synchronous and chainable,
# so the idiom reads:  await $obj->namespace(['person'])->permitted(@rules)

sub new { my ($class, %args) = @_;
    return bless {
        request         => $args{request},
        kind            => $args{kind},        # 'body' | 'query' | 'data'
        context         => $args{context},
        namespace       => undef,
        flatten         => undef,              # override of the kind default
        max_array_depth => undef,
    }, $class;
}

sub namespace { my ($self, $arg) = @_;
    $self->{namespace} = $arg if defined $arg;
    return $self;
}

sub flatten_array_value { my ($self, $arg) = @_;
    $self->{flatten} = $arg if defined $arg;
    return $self;
}

sub max_array_depth { my ($self, $arg) = @_;
    $self->{max_array_depth} = $arg if defined $arg;
    return $self;
}

async sub permitted { my ($self, @rules) = @_;
    my $engine = await $self->_engine;
    return $engine->permitted(@rules);
}

async sub required { my ($self, @rules) = @_;
    my $engine = await $self->_engine;
    return $engine->required(@rules);
}

async sub _engine { my ($self) = @_;
    my $req  = $self->{request};
    my $kind = $self->{kind};

    my $src_data =
          $kind eq 'data'  ? (await $req->json)
        : $kind eq 'query' ? $req->query_params->mixed
        :                    (await $req->form_params)->mixed;

    my %args = (
        src      => $kind,
        src_data => $src_data,
        context  => $self->{context},
    );
    $args{namespace}           = $self->{namespace}       if defined $self->{namespace};
    $args{flatten_array_value} = $self->{flatten}         if defined $self->{flatten};
    $args{max_array_depth}     = $self->{max_array_depth} if defined $self->{max_array_depth};

    return PAGI::StructuredParameters->new(%args);
}

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters::Request - Request-bound, asynchronous strong parameters

=head1 SYNOPSIS

    use PAGI::StructuredParameters;

    my $clean = await PAGI::StructuredParameters->from_body($req)
        ->permitted('username', name => ['first', 'last'], +{ email => [] });

=head1 DESCRIPTION

Binds the L<PAGI::StructuredParameters> engine to a live L<PAGI::Request>.
Because reading a PAGI request body is asynchronous, the terminal L</permitted>
and L</required> methods are asynchronous: each materializes the source hash from
the request (awaiting the body for C<body>/C<data>; the query string is read
synchronously), constructs a synchronous engine, and delegates.

You normally obtain one of these from L<PAGI::StructuredParameters/from_body>,
L<PAGI::StructuredParameters/from_query>, L<PAGI::StructuredParameters/from_data>,
or — in L<PAGI::Nano> — from C<< $c->params >>.

=head1 CONFIGURATION METHODS

These are synchronous and return the object for chaining before the terminal
call.

=head2 namespace

    $obj->namespace(['person']);

=head2 flatten_array_value

    $obj->flatten_array_value(0);

=head2 max_array_depth

    $obj->max_array_depth(50);

See L<PAGI::StructuredParameters> for the meaning of each.

=head1 TERMINAL METHODS

=head2 permitted

    my $clean = await $obj->permitted(@rules);

Asynchronously materializes the request source and applies
L<PAGI::StructuredParameters/permitted>.

=head2 required

    my $clean = await $obj->required(@rules, $on_missing);

Asynchronously materializes the request source and applies
L<PAGI::StructuredParameters/required>. A missing required key throws the
callback's return value through the C<await>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
