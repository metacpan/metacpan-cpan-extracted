package PAGI::Utils;
$PAGI::Utils::VERSION = '0.002000';
use strict;
use warnings;
use Exporter 'import';
use Future::AsyncAwait;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use PAGI::Lifespan;

our @EXPORT_OK = qw(handle_lifespan to_app);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

async sub handle_lifespan {
    my ($scope, $receive, $send, %opts) = @_;

    my $type = $scope->{type} // '';
    croak "handle_lifespan called with scope type '$type' (expected 'lifespan'). "
        . "Check scope type before calling: "
        . "return await handle_lifespan(...) if \$scope->{type} eq 'lifespan'"
        unless $type eq 'lifespan';

    my $manager = PAGI::Lifespan->for_scope($scope);
    $manager->register(%opts) if $opts{startup} || $opts{shutdown};

    return await $manager->handle($scope, $receive, $send);
}

sub to_app {
    my ($thing) = @_;

    croak "to_app() requires an app, component, or class name"
        unless defined $thing;

    return $thing if ref($thing) eq 'CODE';

    if (blessed($thing)) {
        return $thing->to_app if $thing->can('to_app');
        croak ref($thing) . " looks like middleware, not an app"
            . " - pass it to enable(), or wrap an app with ->wrap(\$app)"
            if $thing->can('wrap');
        croak "Cannot coerce " . ref($thing) . " object to a PAGI app (no to_app method)";
    }

    if (!ref($thing)) {
        croak "Cannot coerce '$thing' to a PAGI app"
            unless $thing =~ /\A\w+(?:::\w+)*\z/;
        unless ($thing->can('to_app')) {
            local $@;
            eval "require $thing; 1" or croak "Failed to load '$thing': $@";
        }
        return $thing->to_app if $thing->can('to_app');
        croak "'$thing' looks like middleware, not an app - pass it to enable()"
            if $thing->can('wrap');
        croak "'$thing' does not have a to_app() method";
    }

    croak "Cannot coerce " . ref($thing) . " reference to a PAGI app";
}

1;

__END__

=head1 NAME

PAGI::Utils - Shared utility helpers for PAGI

=head1 SYNOPSIS

    use PAGI::Utils qw(handle_lifespan);

    return await handle_lifespan($scope, $receive, $send,
        startup  => async sub { my ($state) = @_; ... },
        shutdown => async sub { my ($state) = @_; ... },
    ) if $scope->{type} eq 'lifespan';

=head1 FUNCTIONS

=head2 handle_lifespan

    return await handle_lifespan($scope, $receive, $send,
        startup  => async sub { my ($state) = @_; ... },
        shutdown => async sub { my ($state) = @_; ... },
    ) if $scope->{type} eq 'lifespan';

Consumes lifespan events, runs registered startup/shutdown hooks, and sends
the appropriate completion messages. Hooks are taken from
C<< $scope->{'pagi.lifespan.handlers'} >>, and optional C<startup> and
C<shutdown> callbacks can be passed in via C<%opts>.

B<Important:> This function will C<croak> if called with a non-lifespan scope.
Always check C<< $scope->{type} eq 'lifespan' >> before calling, as shown
in the synopsis.

=head2 to_app

    use PAGI::Utils qw(to_app);

    my $app = to_app($thing);

Coerce C<$thing> into a PAGI application (an async coderef). Accepts:

=over 4

=item * a coderef - returned unchanged

=item * an object with a C<to_app> method - compiled by calling it

=item * a class name with a C<to_app> method - auto-required if needed,
then compiled by calling C<< $class->to_app >>

=back

Anything else croaks. A middleware object or class (something with C<wrap>
but no C<to_app>) gets a croak pointing at C<enable()> instead, since
middleware belongs in middleware position, not app position.

All composition points in this distribution (builder mounts, router
targets, cascades, the test client) call this for you, so user code can
pass components and class names directly:

    mount '/static' => PAGI::App::File->new(root => $dir);
    mount '/api'    => 'MyApp::API';

=cut
