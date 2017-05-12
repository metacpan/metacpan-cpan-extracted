package Path::Dispatcher::Declarative;
use strict;
use warnings;
use 5.008001;

our $VERSION = '0.03';

use Path::Dispatcher;
use Path::Dispatcher::Declarative::Builder;
use Sub::Exporter;

use constant dispatcher_class => 'Path::Dispatcher';
use constant builder_class => 'Path::Dispatcher::Declarative::Builder';

our $CALLER; # Sub::Exporter doesn't make this available

my $exporter = Sub::Exporter::build_exporter({
    into_level => 1,
    groups => {
        default => \&build_sugar,
    },
});

sub import {
    my $self = shift;
    my $pkg  = caller;

    my @args = grep { !/^-base$/i } @_;

    # just loading the class..
    return if @args == @_;

    do {
        no strict 'refs';
        push @{ $pkg . '::ISA' }, $self;
    };

    local $CALLER = $pkg;

    $exporter->($self, @args);
}

sub build_sugar {
    my ($class, $group, $arg) = @_;

    my $into = $CALLER;

    $class->populate_defaults($arg);

    my $dispatcher = $class->dispatcher_class->new(name => $into);

    my $builder = $class->builder_class->new(
        dispatcher => $dispatcher,
        %$arg,
    );

    return {
        dispatcher    => sub { $builder->dispatcher },
        rewrite       => sub { $builder->rewrite(@_) },
        on            => sub { $builder->on(@_) },
        under         => sub { $builder->under(@_) },
        redispatch_to => sub { $builder->redispatch_to(@_) },
        enum          => sub { $builder->enum(@_) },
        next_rule     => sub { $builder->next_rule(@_) },
        last_rule     => sub { $builder->last_rule(@_) },
        complete      => sub { $builder->complete(@_) },

        then  => sub (&) { $builder->then(@_) },
        chain => sub (&) { $builder->chain(@_) },

        # NOTE on shift if $into: if caller is $into, then this function is
        # being used as sugar otherwise, it's probably a method call, so
        # discard the invocant
        dispatch => sub { shift if caller ne $into; $builder->dispatch(@_) },
        run      => sub { shift if caller ne $into; $builder->run(@_) },
    };
}

sub populate_defaults {
    my $class = shift;
    my $arg  = shift;

    for my $option ('token_delimiter', 'case_sensitive_tokens') {
        next if exists $arg->{$option};
        next unless $class->can($option);

        my $default = $class->$option;
        next unless defined $default; # use the builder's default

        $arg->{$option} = $class->$option;
    }
}


1;

__END__

=head1 NAME

Path::Dispatcher::Declarative - sugary dispatcher

=head1 SYNOPSIS

    package MyApp::Dispatcher;
    use Path::Dispatcher::Declarative -base;

    on score => sub { show_score() };

    on ['wield', qr/^\w+$/] => sub { wield_weapon($2) };

    rewrite qr/^inv/ => "display inventory";

    under display => sub {
        on inventory => sub { show_inventory() };
        on score     => sub { show_score() };
    };

    package Interpreter;
    MyApp::Dispatcher->run($input);

=head1 DESCRIPTION

L<Jifty::Dispatcher> rocks!

=head1 KEYWORDS

=head2 dispatcher -> Dispatcher

Returns the L<Path::Dispatcher> object for this class; the object that the
sugar is modifying. This is useful for adding custom rules through the regular
API, and inspection.

=head2 dispatch path -> Dispatch

Invokes the dispatcher on the given path and returns a
L<Path::Dispatcher::Dispatch> object. Acts as a keyword within the same
package; otherwise as a method (since these declarative dispatchers are
supposed to be used by other packages).

=head2 run path, args

Performs a dispatch then invokes the L<Path::Dispatcher::Dispatch/run> method
on it.

=head2 on path => sub {}

Adds a rule to the dispatcher for the given path. The path may be:

=over 4

=item a string

This is taken to mean a single token; creates an
L<Path::Dispatcher::Rule::Tokens> rule.

=item an array reference

This is creates a L<Path::Dispatcher::Rule::Tokens> rule.

=item a regular expression

This is creates a L<Path::Dispatcher::Rule::Regex> rule.

=item a code reference

This is creates a L<Path::Dispatcher::Rule::CodeRef> rule.

=back

=head2 under path => sub {}

Creates a L<Path::Dispatcher::Rule::Under> rule. The contents of the coderef
should be nothing other L</on> and C<under> calls.

=head2 then sub { }

Creates a L<Path::Dispatcher::Rule::Always> rule that will continue on to the
next rule via C<next_rule>

The only argument is a coderef that processes normally (like L<on>).

NOTE: You *can* avoid running a following rule by using C<last_rule>.

An example:

    under show => sub {
        then {
            print "Displaying ";
        };
        on inventory => sub {
            print "inventory:\n";
            ...
        };
        on score => sub {
            print "score:\n";
            ...
        };

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-path-dispatcher-declarative at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Dispatcher-Declarative>.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

