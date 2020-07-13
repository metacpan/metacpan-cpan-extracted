package Path::Dispatcher; # git description: v1.07-5-ge7be931
# ABSTRACT: Flexible and extensible dispatch

our $VERSION = '1.08';

use Moo;
use 5.008001;

# VERSION
use Scalar::Util 'blessed';
use Path::Dispatcher::Rule;
use Path::Dispatcher::Dispatch;
use Path::Dispatcher::Path;

use constant dispatch_class => 'Path::Dispatcher::Dispatch';
use constant path_class     => 'Path::Dispatcher::Path';

with 'Path::Dispatcher::Role::Rules';

sub dispatch {
    my $self = shift;
    my $path = $self->_autobox_path(shift);

    my $dispatch = $self->dispatch_class->new;

    for my $rule ($self->rules) {
        $self->_dispatch_rule(
            rule     => $rule,
            dispatch => $dispatch,
            path     => $path,
        );
    }

    return $dispatch;
}

sub _dispatch_rule {
    my $self = shift;
    my %args = @_;

    my @matches = $args{rule}->match($args{path});

    $args{dispatch}->add_matches(@matches);

    return @matches;
}

sub run {
    my $self = shift;
    my $path = shift;

    my $dispatch = $self->dispatch($path);

    return $dispatch->run(@_);
}

sub complete {
    my $self = shift;
    my $path = $self->_autobox_path(shift);

    my %seen;
    return grep { !$seen{$_}++ } map { $_->complete($path) } $self->rules;
}

sub _autobox_path {
    my $self = shift;
    my $path = shift;

    unless (blessed($path) && $path->isa('Path::Dispatcher::Path')) {
        $path = $self->path_class->new(
            path => $path,
        );
    }

    return $path;
}

__PACKAGE__->meta->make_immutable;
no Moo;

# don't require others to load our subclasses explicitly
require Path::Dispatcher::Rule::Alternation;
require Path::Dispatcher::Rule::Always;
require Path::Dispatcher::Rule::Chain;
require Path::Dispatcher::Rule::CodeRef;
require Path::Dispatcher::Rule::Dispatch;
require Path::Dispatcher::Rule::Empty;
require Path::Dispatcher::Rule::Enum;
require Path::Dispatcher::Rule::Eq;
require Path::Dispatcher::Rule::Intersection;
require Path::Dispatcher::Rule::Metadata;
require Path::Dispatcher::Rule::Regex;
require Path::Dispatcher::Rule::Sequence;
require Path::Dispatcher::Rule::Tokens;
require Path::Dispatcher::Rule::Under;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher - Flexible and extensible dispatch

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Path::Dispatcher;
    my $dispatcher = Path::Dispatcher->new;

    $dispatcher->add_rule(
        Path::Dispatcher::Rule::Regex->new(
            regex => qr{^/(foo)/},
            block => sub { warn shift->pos(1); },
        )
    );

    $dispatcher->add_rule(
        Path::Dispatcher::Rule::Tokens->new(
            tokens    => ['ticket', 'delete', qr/^\d+$/],
            delimiter => '/',
            block     => sub { delete_ticket(shift->pos(3)) },
        )
    );

    my $dispatch = $dispatcher->dispatch("/foo/bar");
    die "404" unless $dispatch->has_matches;
    $dispatch->run;

=head1 DESCRIPTION

We really like L<Jifty::Dispatcher> and wanted to use it for L<Prophet>'s
command line.

The basic operation is that of dispatch. Dispatch takes a path and a list of
rules, and it returns a list of matches. From there you can "run" the rules
that matched. These phases are distinct so that, if you need to, you can
inspect which rules were matched without ever running their codeblocks.

Tab completion support is also available (see in particular
L<Path::Dispatcher::Cookbook/How can I configure tab completion for shells?>)
for the dispatchers you write.

Each rule may take a variety of different forms (which I think justifies the
"flexible" adjective in the module's description). Some of the rule types are:

=over 4

=item L<Path::Dispatcher::Rule::Regex>

Matches the path against a regular expression.

=item L<Path::Dispatcher::Rule::Enum>

Match one of a set of strings.

=item L<Path::Dispatcher::Rule::CodeRef>

Execute a coderef to determine whether the path matches the rule. So you can
do anything you like. Though writing a domain-specific rule (see below) will
enable better introspection and encoding intent.

=item L<Path::Dispatcher::Rule::Dispatch>

Use another L<Path::Dispatcher> to match the path. This facilitates both
extending dispatchers (a bit like subclassing) and delegating to plugins.

=back

Since L<Path::Dispatcher> is designed with good object-oriented programming
practices, you can also write your own domain-specific rule classes (which
earns it the "extensible" adjective). For example, in L<Prophet>, we have a
custom rule for matching, and tab completing, record IDs.

You may want to use L<Path::Dispatcher::Declarative> which gives you some sugar
inspired by L<Jifty::Dispatcher>.

=head1 ATTRIBUTES

=head2 rules

A list of L<Path::Dispatcher::Rule> objects.

=head1 METHODS

=head2 add_rule

Adds a L<Path::Dispatcher::Rule> to the end of this dispatcher's rule set.

=head2 dispatch path -> dispatch

Takes a string (the path) and returns a L<Path::Dispatcher::Dispatch> object
representing a list of matches (L<Path::Dispatcher::Match> objects).

=head2 run path, args

Dispatches on the path and then invokes the C<run> method on the
L<Path::Dispatcher::Dispatch> object, for when you don't need to inspect the
dispatch.

The args are passed down directly into each rule codeblock. No other args are
given to the codeblock.

=head2 complete path -> strings

Given a path, consult each rule for possible completions for the path. This is
intended for tab completion. You can use it with L<Term::ReadLine> like so:

    $term->Attribs->{completion_function} = sub {
        my ($last_word, $line, $start) = @_;
        my @matches = map { s/^.* //; $_ } $dispatcher->complete($line);
        return @matches;
    };

This API is experimental and subject to change. In particular I think I want to
return an object that resembles L<Path::Dispatcher::Dispatch>.

=head1 SEE ALSO

=over 4

=item L<http://sartak.org/talks/yapc-na-2010/path-dispatcher/>

=item L<http://sartak.org/talks/yapc-asia-2010/evolution-of-path-dispatcher/>

=item L<http://github.com/miyagawa/plack-dispatching-samples>

=item L<Jifty::Dispatcher>

=item L<Catalyst::Dispatcher>

=item L<Mojolicious::Dispatcher>

=item L<Path::Router>

=item L<Router::Simple>

=item L<http://github.com/bestpractical/path-dispatcher-debugger> - Not quite ready for release

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Dispatcher>
(or L<bug-Path-Dispatcher@rt.cpan.org|mailto:bug-Path-Dispatcher@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 CONTRIBUTORS

=for stopwords sartak Shawn M Moore Karen Etheridge robertkrimen Aaron Trevena David Pottage Florian Ragwitz clkao

=over 4

=item *

sartak <sartak@e417ac7c-1bcc-0310-8ffa-8f5827389a85>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

Aaron Trevena <aaron@aarontrevena.co.uk>

=item *

David Pottage <david@chrestomanci.org>

=item *

Shawn M Moore <code@sartak.org>

=item *

Shawn M Moore <shawn.moore@iinteractive.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Shawn M Moore <shawn@bestpractical.com>

=item *

clkao <clkao@e417ac7c-1bcc-0310-8ffa-8f5827389a85>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
