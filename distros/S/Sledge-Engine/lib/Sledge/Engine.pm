package Sledge::Engine;

use strict;
use base qw(Class::Data::Inheritable);
use Scalar::Util qw(blessed);
use File::Basename ();
use Class::Inspector;
use UNIVERSAL::require;
use Module::Pluggable::Object;
use Carp ();
use String::CamelCase qw(camelize);
use Sledge::Utils;


our $VERSION = '0.04';
our $StaticExtension = '.html';

sub import {
    my $pkg = shift;

    return unless $pkg eq 'Sledge::Engine';

    my $caller = caller(0);
    no strict 'refs';
    my $engine = 'Sledge::Engine::CGI';
    if ($ENV{MOD_PERL}) {
        my($software, $version) = 
            $ENV{MOD_PERL} =~ /^(\S+)\/(\d+(?:[\.\_]\d+)+)/;
        if ($version >= 1.24 && $version < 1.90) {
            $engine = 'Sledge::Engine::Apache::MP13';
            *handler = sub ($$) { shift->run(@_); };
        } 
        else {
            Carp::croak("Unsupported mod_perl version: $ENV{MOD_PERL}");
        }
    }
    $engine->require;
    push @{"$caller\::ISA"}, $engine;

    $caller->mk_classdata('ActionMap' => {});
    $caller->mk_classdata('ActionMapKeys' => []);
    $caller->mk_classdata('components' => []);

}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}

sub setup {
    my $pkg = shift;

    my $pages_class = join '::', $pkg, 'Pages';
    $pages_class->use or die $@;
    my $finder = Module::Pluggable::Object->new(
        search_path => [$pages_class],
        require => 1,
    );
    $pkg->components([$finder->plugins]);
    for my $subclass(@{$pkg->components}) {
        my $methods = Class::Inspector->methods($subclass, 'public');
        for my $method(@{$methods}) {
            if ($method =~ s/^dispatch_//) {
                $pkg->register($subclass, $method);
            }
        }
    }
    $pkg->ActionMapKeys([
        sort { length($a) <=> length($b) } keys %{$pkg->ActionMap}
    ]);
}

sub register {
    my($pkg, $class, $page) = @_;
    my $prefix = Sledge::Utils::class2prefix($class);
    my $path = $prefix eq '/' ? "/$page" : "$prefix/$page";
    $path =~ s{/index$}{/};
    $pkg->ActionMap->{$path} = {
        class => $class,
        page => $page,
    };
}

sub lookup {
    my($self, $path) = @_;
    $path ||= '/';
    $path =~ s{/index$}{/};
    my $action;
    if ($action = $self->ActionMap->{$path}) {
        return $action;
    }
    elsif ($action = $self->lookup_static($path)) {
        return $action;
    }
    # XXX handle arguments.
#     my $match;
#     for my $key(@{$self->ActionMapKeys}) {
#         next unless index($path, $key) >= 0;
#         if ($path =~ m{^$key}) {
#             $match = $key;
#         }
#     }
#     return unless $match;
#     my %action = %{$self->ActionMap->{$match}};
#     if (length($path) > length($match)) {
#         my $args = $path;
#         $args =~ s{^$match/?}{};
#         $action{args} = [split '/', $args];
#     }
#     return \%action;
}

sub lookup_static {
    my($self, $path) = @_;
    my($page, $dir, $suf) = 
        File::Basename::fileparse($path, $StaticExtension);
    return if index($page, '.') >= 0;
    $page ||= 'index';
    my $class;
    if ($dir eq '/') {
        my $appname = ref $self;
        for my $subclass(qw(Root Index)) {
            $class = join '::', $appname, 'Pages', $subclass;
            last if $class->require;
        }
    }
    else {
        $dir =~ s{^/}{};
        $dir =~ s{/$}{};
        $class = join '::', 
            ref($self), 'Pages', map { camelize($_) } split '/', $dir;
    }
    if ((Class::Inspector->loaded($class) || $class->require) && 
            -e $class->guess_filename($page)) {
        no strict 'refs';
        *{"$class\::dispatch_$page"} = sub {} 
            unless $class->can("dispatch_$page");
        my %action = (class => $class, page => $page);
        $self->ActionMap->{$path} = \%action;
        return \%action;
    }
}

sub run {
    my $self = shift;
    unless (blessed $self) {
        $self = $self->new;
    }
    $self->handle_request(@_);
}

sub handle_request {
    die "ABSTRACT METHOD!";
}

1;

__END__

=head1 NAME

Sledge::Engine - run Sledge based application (EXPERIMENTAL).

=head1 SYNOPSIS

 # MyApp.pm
 package MyApp;
 use Sledge::Engine;

 __PACKAGE__->setup;

 # mod_perl configuration.
 <Location />
     SetHandler perl-script
     PerlHandler MyApp 
 </Location>

 # CGI mode.
 #!/usr/bin/perl
 use strict;
 use MyApp;
 MyApp->run;


=head1 AUTHOR

Tomohiro IKEBE, C<< <ikebe@shebang.jp> >>

=head1 LICENSE

Copyright 2006 Tomohiro IKEBE, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

