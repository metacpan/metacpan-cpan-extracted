package Plack::Middleware::EnvTracer;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw/methods callback/;

our $VERSION = '0.03';

my $ENABLE = +{};

sub prepare_app {
    my $self = shift;

    if ( ref $self->methods eq 'ARRAY' && scalar(@{$self->methods}) > 0 ) {
        map { $ENABLE->{lc($_)} = 1; } @{$self->methods};
    }
    else {
        map { $ENABLE->{$_} = 1; } qw/
            fetch store exists delete clear scalar firstkey nextkey
        /;
    }

    if (!$self->callback || ref $self->callback ne 'CODE') {
        $self->callback(sub {
            my ($summary, $trace) = @_;
            print "$summary\n$trace\n";
        });
    }

    tie %ENV, __PACKAGE__;
}

my @TRACE_LOG;
my %COUNT;

sub call {
    my($self, $env, $panel) = @_;

    @TRACE_LOG = ();
    %COUNT     = ();

    my $res = $self->app->($env);

    my @summary;
    for my $i (qw/ fetch store exists delete clear scalar firstkey nextkey /) {
        my $j = uc $i;
        push @summary, sprintf(
            "$j:%s",
            $ENABLE->{$i} ? ($COUNT{$j} || 0) : '-'
        );
    }

    $self->callback->(
        join(", ", @summary),
        join("\n", @TRACE_LOG),
    );

    return $res;
}

sub TIEHASH {
    return bless +{ %ENV }, shift;
}

sub FETCH {
    _tracer('FETCH', $_[1], undef,  caller() );
    $_[0]->{$_[1]};
}

sub STORE {
    _tracer('STORE', $_[1], $_[2],  caller() );
    $_[0]->{$_[1]} = $_[2];
}

sub EXISTS {
    _tracer('EXISTS', $_[1], undef,  caller() );
    return exists($_[0]->{$_[1]});
}

sub DELETE {
    _tracer('DELETE', $_[1], undef,  caller() );
    delete $_[0]->{$_[1]};
}

sub CLEAR {
    _tracer('CLEAR', undef, undef,  caller() );
    %{$_[0]} = ();
}

sub SCALAR {
    _tracer('SCALAR', undef, undef,  caller() );
    scalar %{$_[0]};
}

sub FIRSTKEY {
    _tracer('FIRSTKEY', undef, undef,  caller() );
    my $a = scalar keys %{$_[0]};
    each %{$_[0]};
}

sub NEXTKEY {
    _tracer('NEXTKEY', undef, undef,  caller() );
    each %{$_[0]};
}

sub _tracer {
    my ($method, $key, $value,
            $package, $filename, $line) = @_;

    return unless $ENABLE->{lc($method)};

    $key = !defined $key ? '' : defined $value ? "$key=$value" : $key;
    push @TRACE_LOG, "PID:$$\t$method\t$key\t[$filename#$line]";

    $COUNT{$method}++;
}

1;

__END__

=head1 NAME

Plack::Middleware::EnvTracer - The Plack middleware for tracing %ENV


=head1 SYNOPSIS

    use Plack::Builder;
    builder {
      enable 'EnvTracer';
      $app;
    };


=head1 DESCRIPTION

Plack::Middleware::EnvTracer is the Plack middleware for tracing %ENV.
If you enable this module, you can see the traced log of %ENV in STDOUT as default.

=head2 OPTIONS

If you use C<methods> option, you can enable methods only which you want(fetch, store, exists, delete, clear, scalar, firstkey or nextkey).

    enable 'EnvTracer',
      methods => [qw/store delete/]; # just enable STORE and DELETE methods

And you can set the C<callback> option.

    enable 'EnvTracer',
        callback => sub {
            my ($summary, $trace) = @_;
            warn "$summary\n$trace\n";
        };


=head1 METHODS

=over

=item prepare_app

=item call

=back


=head1 REPOSITORY

Plack::Middleware::EnvTracer is hosted on github
L<http://github.com/bayashi/Plack-Middleware-EnvTracer>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware::Debug::TraceENV>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
