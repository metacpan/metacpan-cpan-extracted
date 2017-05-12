package MooseX::Runnable::Util::ArgParser;
# ABSTRACT: parse @ARGV for C<mx-run>

our $VERSION = '0.10';

use Moose;
use MooseX::Types::Moose qw(HashRef ArrayRef Str Bool);
use MooseX::Types::Path::Tiny qw(Path);
use Path::Tiny; # exports path()
use List::SomeUtils qw(first_index);
use FindBin;

use namespace::autoclean -also => ['_look_for_dash_something', '_delete_first'];

has 'argv' => (
    is         => 'ro',
    isa        => ArrayRef,
    required   => 1,
    auto_deref => 1,
);

has 'class_name' => (
    is         => 'ro',
    isa        => Str,
    lazy       => 1,
    builder    => '_build_class_name',
);

has 'modules' => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    lazy       => 1,
    builder    => '_build_modules',
    auto_deref => 1,
);

has 'include_paths' => (
    is         => 'ro',
    isa        => ArrayRef[Path],
    lazy       => 1,
    builder    => '_build_include_paths',
    auto_deref => 1,
);

has 'plugins' => (
    is         => 'ro',
    isa        => HashRef[ArrayRef[Str]],
    lazy       => 1,
    builder    => '_build_plugins',
);

has 'app_args' => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    lazy       => 1,
    builder    => '_build_app_args',
    auto_deref => 1,
);

has 'is_help' => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    builder  => '_build_is_help',
);


sub _build_class_name {
    my $self = shift;
    my @args = $self->argv;

    my $next_is_it = 0;
    my $need_dash_dash = 0;

  ARG:
    for my $arg (@args) {
        if($next_is_it){
            return $arg;
        }

        if($arg eq '--'){
            $next_is_it = 1;
            next ARG;
        }

        next ARG if $arg =~ /^-[A-Za-z]/;

        if($arg =~ /^[+]/){
            $need_dash_dash = 1;
            next ARG;
        }

        return $arg unless $need_dash_dash;
    }

    if($next_is_it){
        confess 'Parse error: expecting ClassName, got EOF';
    }
    if($need_dash_dash){
        confess 'Parse error: expecting --, got EOF';
    }

    confess "Parse error: looking for ClassName, but can't find it; perhaps you meant '--help' ?";
}

sub _look_for_dash_something($@) {
    my ($something, @args) = @_;
    my @result;

    my $rx = qr/^-$something(.*)$/;
  ARG:
    for my $arg (@args) {
        last ARG if $arg eq '--';
        last ARG unless $arg =~ /^-/;
        if($arg =~ /$rx/){
            push @result, $1;
        }
    }

    return @result;
}

sub _build_modules {
    my $self = shift;
    my @args = $self->argv;
    return [ _look_for_dash_something 'M', @args ];
}

sub _build_include_paths {
    my $self = shift;
    my @args = $self->argv;
    return [ map { path($_) } _look_for_dash_something 'I', @args ];
}

sub _build_is_help {
    my $self = shift;
    my @args = $self->argv;
    return
      (_look_for_dash_something 'h', @args) ||
      (_look_for_dash_something '\\?', @args) ||
      (_look_for_dash_something '-help', @args) ;;
}

sub _build_plugins {
    my $self = shift;
    my @args = $self->argv;
    $self->class_name; # causes death when plugin syntax is wrong

    my %plugins;
    my @accumulator;
    my $in_plugin = undef;

  ARG:
    for my $arg (@args) {
        if(defined $in_plugin){
            if($arg eq '--'){
                $plugins{$in_plugin} = [@accumulator];
                @accumulator = ();
                return \%plugins;
            }
            elsif($arg =~ /^[+](.+)$/){
                $plugins{$in_plugin} = [@accumulator];
                @accumulator = ();
                $in_plugin = $1;
                next ARG;
            }
            else {
                push @accumulator, $arg;
            }
        }
        else { # once we are $in_plugin, we can never be out again
            if($arg eq '--'){
                return {};
            }
            elsif($arg =~ /^[+](.+)$/){
                $in_plugin = $1;
                next ARG;
            }
        }
    }

    if($in_plugin){
        confess "Parse error: expecting arguments for plugin $in_plugin, but got EOF. ".
          "Perhaps you forgot '--' ?";
    }

    return {};
}

sub _delete_first($\@) {
    my ($to_delete, $list) = @_;
    my $idx = first_index { $_ eq $to_delete } @$list;
    splice @$list, $idx, 1;
    return;
}

# this is a dumb way to do it, but i forgot about it until just now,
# and don't want to rewrite the whole class ;) ;)
sub _build_app_args {
    my $self = shift;
    my @args = $self->argv;

    return [] if $self->is_help; # LIES!!11!, but who cares

    # functional programmers may wish to avert their eyes
    _delete_first $_, @args for map { "-M$_" } $self->modules;
    _delete_first $_, @args for map { "-I$_" } $self->include_paths;

    my %plugins = %{ $self->plugins };

  PLUGIN:
    for my $p (keys %plugins){
        my $vl = scalar @{ $plugins{$p} };
        my $idx = first_index { $_ eq "+$p" } @args;
        next PLUGIN if $idx == -1; # HORRIBLE API!

        splice @args, $idx, $vl + 1;
    }

    if($args[0] eq '--'){
        shift @args;
    }

    if($args[0] eq $self->class_name){
        shift @args;
    }
    else {
        confess 'Parse error: Some residual crud was found before the app name: '.
          join ', ', @args;
    }

    return [@args];
}

# XXX: bad
sub guess_cmdline {
    my ($self, %opts) = @_;

    confess 'Parser is help' if $self->is_help;

    my @perl_flags = @{$opts{perl_flags} || []};
    my @without_plugins = @{$opts{without_plugins} || []};

    # invoke mx-run
    my @cmdline = (
        $^X,
        (map { "-I$_" } @INC),
        @perl_flags,
        $FindBin::Bin.'/'.$FindBin::Script,
    );
    push @cmdline, map { "-I$_" } $self->include_paths;
    push @cmdline, map { "-M$_" } $self->modules;

  p:
    for my $plugin (keys %{$self->plugins}){
        for my $without (@without_plugins) {
            next p if $without eq $plugin;
        }
        push @cmdline, "+$plugin", @{$self->plugins->{$plugin} || []};
    }
    push @cmdline, '--';
    push @cmdline, $self->class_name;
    push @cmdline, $self->app_args;

    return @cmdline;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Runnable::Util::ArgParser - parse @ARGV for C<mx-run>

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    my $parser = MooseX::Runnable::Util::ArgParser->new(
        argv => \@ARGV,
    );

    $parser->class_name;
    $parser->modules;
    $parser->include_paths;
    $parser->plugins;
    $parser->is_help;
    $parser->app_args;

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Runnable>
(or L<bug-MooseX-Runnable@rt.cpan.org|mailto:bug-MooseX-Runnable@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
