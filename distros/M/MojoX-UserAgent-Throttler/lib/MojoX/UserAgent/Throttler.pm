package MojoX::UserAgent::Throttler;

use Mojo::Base -strict;

our $VERSION = 'v1.0.3';

use Mojo::UserAgent;
use Mojo::Util qw( monkey_patch );
use Sub::Util 1.40 qw( set_subname );
use Sub::Throttler 0.002000 qw( throttle_me throttle_me_sync done_cb );


# https://github.com/kraih/mojo/issues/663
# Inconsistent behavior of Mojo::UserAgent::DESTROY:
# - sync requests always executed, even when started while DESTROY
# - for all active async requests which was started before DESTROY user's
#   callback will be called with error in $tx
# - for all async requests which was started while DESTROY user's callback
#   won't be called
# To emulate this behaviour with throttling:
# - sync request: always executed, even when started while DESTROY
# - new async request while DESTROY: ignored
# - delayed async request (it was delayed before DESTROY):
#   * if it start before DESTROY: let Mojo::UserAgent handle it using
#     done_cb($done,$cb)
#   * if it start while DESTROY: do $done->(0) and call user's callback
#     with error in $tx
#   * if it still delayed after DESTROY: call user's callback with error
#     in $tx

use constant START_ARGS => 3;

my %Delayed;        # $ua => { $tx => [$tx, $cb], … }
my %IsDestroying;   # $ua => 1

my $ORIG_start  = \&Mojo::UserAgent::start;
my $ORIG_DESTROY= \&Mojo::UserAgent::DESTROY;

monkey_patch 'Mojo::UserAgent',
start => set_subname('Mojo::UserAgent::start', sub {
    # WARNING Async call return undef instead of (undocumented) connection $id.
    ## no critic (ProhibitExplicitReturnUndef)
    my ($self, $tx, $cb) = @_;
    if (START_ARGS == @_ && $cb) {
        if ($IsDestroying{ $self }) {
#             $cb->($self, $tx->client_close(1)); # to fix issue 663 or not to fix?
            return undef;
        }
        else {
            $Delayed{ $self }{ $tx } = [ $tx, $cb ];
        }
    }
    my $done = ref $_[-1] eq 'CODE' ? &throttle_me || return undef : &throttle_me_sync;
    ($self, $tx, $cb) = @_;
    if ($cb) {
        if ($IsDestroying{ $self }) {
            $done->(0);
        }
        else {
            delete $Delayed{ $self }{ $tx };
            $self->$ORIG_start($tx, done_cb($done, $cb));
        }
        return undef;
    }
    else {
        $tx = $self->$ORIG_start($tx);
        $done->();
        return $tx;
    }
}),
DESTROY => sub {
    my ($self) = @_;
    $IsDestroying{ $self } = 1;
    for (values %{ delete $Delayed{ $self } || {} }) {
        my ($tx, $cb) = @{ $_ };
        $cb->($self, _client_close($tx, 1));
    }
    $self->$ORIG_DESTROY;
    delete $IsDestroying{ $self };
    return;
};

# This is a replacement of $tx->client_close() removed in Mojolicious 6.43.
sub _client_close {
    ## no critic(ProhibitAmbiguousNames,ProhibitMagicNumbers)
    my ($self, $close) = @_;

    my $res = $self->completed->emit('finish')->res->finish;
    if ($close && !$res->code && !$res->error) {
        $res->error({message => 'Premature connection close'});
    }
    elsif ($res->is_error) {
        $res->error({message => $res->message, code => $res->code});
    }

    return $self;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

MojoX::UserAgent::Throttler - add throttling support to Mojo::UserAgent


=head1 VERSION

This document describes MojoX::UserAgent::Throttler version v1.0.3


=head1 SYNOPSIS

    use MojoX::UserAgent::Throttler;
    use Sub::Throttler::SOME_ALGORITHM;

    my $throttle = Sub::Throttler::SOME_ALGORITHM->new(...);
    $throttle->apply_to_methods('Mojo::UserAgent');

=head1 DESCRIPTION

This module helps throttle L<Mojo::UserAgent> using L<Sub::Throttler>.

While in most cases this module isn't needed and existing functionality of
Sub::Throttler is enough to throttle Mojo::UserAgent, there are two
special cases which needs extra handling - when B<Mojo::UserAgent object
is destroyed while there are delayed requests>, and when B<new async
requests start while destroying Mojo::UserAgent object>.

To handle these cases it won't be enough to just do usual:

    throttle_it('Mojo::UserAgent::start');

Instead you'll have to write L<Sub::Throttler/"custom wrapper"> plus add
wrapper for Mojo::UserAgent::DESTROY. Both are provided by this module and
activated when you load it.

So, when using this module you shouldn't manually call throttle_it() like
shown above - just use this module and then setup throttling algorithms as
you need and apply them to L<Mojo::UserAgent/"start"> - this will let you
throttle all (sync/async, GET/POST/etc.) requests.
Use L<Sub::Throttler::algo/"apply_to"> to customize throttling based on
request method, hostname, etc.

=head2 EXAMPLE

    use MojoX::UserAgent::Throttler;
    use Sub::Throttler::Limit;
    my $throttle = Sub::Throttler::Limit->new(limit=>5);
    # Example policy:
    # - don't throttle sync calls
    # - throttle async GET requests by host
    # - throttle other async requests by method, per $ua object
    # I.e. allow up to 5 parallel GET requests to each host globally for
    # all Mojo::UserAgent objects plus up to 5 parallel non-GET requests
    # per each Mojo::UserAgent object.
    $throttle->apply_to(sub {
        my ($this, $name, @params) = @_;
        if (ref $this eq 'Mojo::UserAgent') {
            my ($tx, $cb) = @params;
            if (!$cb) {
                return;
            } elsif ('GET' eq uc $tx->req->method) {
                return { $tx->req->url->host => 1 };
            } else {
                return { "$this " . uc $tx->req->method => 1 };
            }
        }
        return;
    });


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-MojoX-UserAgent-Throttler/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-MojoX-UserAgent-Throttler>

    git clone https://github.com/powerman/perl-MojoX-UserAgent-Throttler.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=MojoX-UserAgent-Throttler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/MojoX-UserAgent-Throttler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-UserAgent-Throttler>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=MojoX-UserAgent-Throttler>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/MojoX-UserAgent-Throttler>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
