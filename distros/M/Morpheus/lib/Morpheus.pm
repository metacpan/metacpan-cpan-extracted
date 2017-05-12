package Morpheus;
{
  $Morpheus::VERSION = '0.46';
}
use strict;
sub morph ($;$);
sub export ($$;$);

# ABSTRACT: the ultimate configuration engine


sub import ($;@) {
    my $class = shift;
    my ($caller) = caller;
    my $export;
    while (@_) {
        my $key = shift;
        my $value = shift;
        if ($key eq "-defaults") {
            Morpheus::Defaults->import($value);
        } elsif ($key eq "-overrides") {
            Morpheus::Overrides->import($value);
        } elsif ($key eq "-export") {
            $export = $value;
        } elsif ($key =~ /^-/) {
            die "unknown option '$key'";
        } else {
            export($caller, $value, $key);
        }
    }
    $export ||= [qw(morph)];
    no strict 'refs';
    *{"${caller}::$_"} = \&{$_} for @$export;
}

use Morpheus::Defaults;
use Morpheus::Overrides;
use Morpheus::Bootstrap;
use Morpheus::Utils;
use Morpheus::Key qw(key);

sub export ($$;$) {
    my ($package, $bindings, $root) = @_;

    # bindings format:
    # ["$X", ...]
    # ["@X", ...]
    # ["%X", ...]
    # ["x" => "X", ...]
    # ["x" => "$X", ...]
    # ["x" => "@X", ...]
    # ["x" => [<nested bindings>], ...]

    die "unexpected type $bindings" unless ref $bindings eq "ARRAY" or ref $bindings eq "SCALAR";
    $root ||= "";

    if (ref $bindings eq "SCALAR") {

        my $value = morph("$root");
        die "'$root': configuration variable is not defined" unless defined $value;

       if (ref $value eq "GLOB") {
            if (defined ${*{$value}}) {
                $$bindings = ${*{$value}};
            } else {
                die "'$root': configuration variable of type \$ is not defined";
            }
        } else {
            $$bindings = $value;
        }

        return;
    }

    $root .= "/" if $root and $root !~ m{/$};

    while (@$bindings) {
        my $ns = shift @$bindings;
        die "unexpected type $ns" if ref $ns;
        my ($var, $type, $optional);
        if ($ns =~ s/^(\??)([\$\@\%])//) {
            ($optional, $type) = ($1, $2);
            $var = $ns;
        } else {
            $var = shift @$bindings;
            if (ref $var) {
                export($package, $var, "$root$ns/");
                next;
            } else {
                $var =~ s/^(\?)// and $optional = $1;
                $type = '$';
                $var =~ s/^([\$\@\%])// and $type = $1;
            }
        }

        die "'$var': invalid variable name" unless $var =~ /^\w+$/;
        my $symbol = do { no strict 'refs'; \*{"${package}::$var"} };

        my $value = morph("$root$ns");
        die "'$root$ns': configuration variable is not defined" unless $optional or defined $value;

        if ($type eq '$') {
            if (ref $value eq "GLOB") {
                if (defined ${*{$value}} or $optional) {
                    *$symbol = \${*{$value}};
                } else {
                    die "'$root$ns': configuration variable of type \$ is not defined";
                }
            } else {
                *$symbol = \$value;
            }
        } elsif ($type eq '@') {
            if (ref $value eq "ARRAY") {
                *$symbol = \@{$value};
            } elsif (ref $value eq "GLOB") {
                if (*{$value}{ARRAY} or $optional) {
                    *$symbol = \@{*{$value}};
                } else {
                    die "'$root$ns': configuration variable of type \@ is not defined";
                }
            } elsif ($optional) {
                *$symbol = \@{*$symbol};
            } else {

                die "'$root$ns' => '$type$var': $value is not an array or glob: " . ref $value;
            }
        } elsif ($type eq '%') {
            if (ref $value eq "HASH") {
                *$symbol = \%{$value};
            } elsif (ref $value eq "GLOB") {
                if (*{$value}{HASH} or $optional) {
                    *$symbol = \%{*{$value}};
                } else {
                    die "'$root$ns': configuration variable of type \% is not defined";
                }
            } elsif ($optional) {
                *$symbol = \%{*$symbol};
            } else {
                die "'$root$ns' => '$type$var': $value is not a hash or glob";
            }
        } else {
            die "'$root$ns' => '$type$var': unsupported variable type $type";
        }
    }
}

our $stack = {};
our $bootstrapped;
our @plugins;

require Data::Dump if $ENV{MORPHEUS_VERBOSE};
our $indent = "";
our $source = "";

sub morph ($;$) {
    my ($main_ns, $type) = @_;
    $main_ns = key($main_ns);

    local $indent = "$indent  ";
    print "$indent morph($main_ns)\n" if $ENV{MORPHEUS_VERBOSE};



    unless (defined $bootstrapped) { 
        #FIXME: we just need a proper caching and its invalidation
        # then we could always call morph("/morpheus/plugins") and omit tracking if we are boostrapped or not

        my $plugins = { 
            Bootstrap => {
                priority => 200,
                object => Morpheus::Bootstrap->new(),
            },
        };

        my $plugins_prev_set;
        my $plugins_set = "";
        for my $iteration (0 .. 42) {
            die "bootstrap hangs" if $iteration == 42;
            local $bootstrapped = 0;

            @plugins = 
                map { { %{$plugins->{$_}}, name => $_ } } 
                sort { $plugins->{$b}->{priority} <=> $plugins->{$a}->{priority} } 
                grep { $plugins->{$_}->{priority} } keys %$plugins;

            $plugins_prev_set = $plugins_set;
            $plugins_set = join ",", map { "$_->{object}:$_->{priority}" } @plugins;
            last if $plugins_set eq $plugins_prev_set;
            #FIXME: check if we hang

            $plugins = morph("/morpheus/plugins");
        }
        print "plugins: ", join (", ", map { "$_->{name}:$_->{priority}" } @plugins), "\n" if $ENV{MORPHEUS_VERBOSE};
        $bootstrapped = 1;
    }

    $main_ns ||= "";
    my $value;

    OUTER:
    #for my $plugin (@plugins) {
    my $prev_priority = 1000; 
    for (@plugins) {
        my ($plugin, $plugin_name, $priority) = @{$_}{qw(object name priority)};
        last if $priority <= 100 and $main_ns ge "/morpheus/plugins";

        my $priority_equal = $prev_priority == $priority;
        $prev_priority = $priority;

        print "  $indent * ${plugin_name}->list($main_ns)\n" if $ENV{MORPHEUS_VERBOSE};
        my @list = do {
            if ($stack->{"$plugin\0$main_ns"}) {
                print "  $indent - skipped\n" if $ENV{MORPHEUS_VERBOSE};
                next;
            }
            local $stack->{"$plugin\0$main_ns"} = 1;
            $plugin->list($main_ns);
        };
        print "  $indent - done\n" if $ENV{MORPHEUS_VERBOSE};

        while (@list) {
            my ($ns, $token) = splice @list, 0, 2;
            $ns = key($ns);

            print "  $indent * ${plugin_name}->get($token)\n" if $ENV{MORPHEUS_VERBOSE};
            my $patch = do {
                if ($stack->{"$plugin\0$source\0$main_ns\0$token"}) {
                    print "  $indent - skipped\n" if $ENV{MORPHEUS_VERBOSE};
                    next;
                }
                local $stack->{"$plugin\0$source\0$main_ns\0$token"} = 1;
                local $source = $main_ns;
                $plugin->get($token);
            };
            print "  $indent - done\n" if $ENV{MORPHEUS_VERBOSE};

            if ($main_ns gt $ns) {
                my $delta = substr($main_ns, length $ns);
                $delta =~ s{^/}{};
                $patch = adjust($patch, $delta);
            } elsif ($main_ns le $ns) {
                my $delta = substr($ns, length $main_ns);
                $delta =~ s{^/}{};
                $patch = normalize({ $delta => $patch }) if $delta;
            } else {
                die "$plugin: list('$main_ns'): '$ns' => '$token'"
            }

            $value = merge($value, $patch, $priority_equal);
            # last OUTER if defined $value and ref $value ne 'HASH' and ref $value ne 'GLOB'; 
            # FIXME: actually merge now merges ARRAY and SCALAR into a GLOB. uncomment this when we get rid of globs completely
        }
    }

    $type ||= "*";
    if ($type eq '$') {
        if (ref $value eq "GLOB") {
            $value = ${*{$value}};
        }
    } elsif ($type eq '@') {
        if (ref $value eq "GLOB") {
            $value = *{$value}{ARRAY};
        } elsif (ref $value ne "ARRAY") {
            $value = undef;
        }
    } elsif ($type eq '%') {
        if (ref $value eq "GLOB") {
            $value = *{$value}{HASH};
        } elsif (ref $value ne "HASH") {
            $value = undef;
        }
    } elsif ($type ne '*') {
        die "invalid type value '$type'"
    }

    print "$indent returns ", Data::Dump::pp($value), "\n" if $ENV{MORPHEUS_VERBOSE};    
    return $value;
}

1;

__END__
=pod

=head1 NAME

Morpheus - the ultimate configuration engine

=head1 VERSION

version 0.46

=head1 SYNOPSIS

  use Morpheus "/foo/bar" => [
      qw($V1 $V2 $V3),
      "v5" => '$V5', "v6/a" => '$A',
      "v7" => [ '$C', '$D', "e" => '$E' ],
  ]; 

  use Morpheus -defaults => {
      "/foo/bar" => { x => 1, y => 2},
  };

  use Morpheus -overrides => {
      "/foo/bar" => { "x/y" => 3 },
  };

  use Morpheus -export => [
      qw( morph merge normalize )
  ];

  use Morpheus; # only 'morph' function is exported by default

  $bar = morph("/foo/bar");

=head1 DESCRIPTION

Morpheus is a configuration engine that completely separates config consumers from config providers.

Consumers can obtain configuration values by using this module or L<morph> script.
Configuration values are binded to various nodes in the global config tree, similar to virtual file system. Consumers can ask for any node or for any subtree.

Providers are plugins which can populate configuration tree from any sources: local configuration files, configuration database, environment, etc.
The overall program configuration is merged together from all data provided by plugins.

=head1 CONFIGURATION TREE

Every config value is binded to a key inside the global configuration tree. Keys use C</> as a separator of their parts, similar to usual filesystem conventions.

Any value which is a hashref will become the subtree in the configuration tree and will be merged with other values if possible. For example, if one plugin provides C<< { foo => 5 } >> for C</blah> key, and another plugin provides C<< { bar => 6 } >> for C</blah> key, then C<morph("/blah")> will return C<< { foo => 5, bar => 6 } >>.

Leading C</> in key name is optional, and C<morph("/foo")> and C<morph("foo")> are the same by now, but in the future some analog of C<chdir> may be implemented. So leading C</> is probably more compatible with future releases.

=head1 IMPORT SYNTAX

There are a lot of things which you can pass to C<use Morpheus>:

=head2 Import to global variables

This code will set your package's C<$X> variable to the value binded to C</foo/bar/X> key:

  use Morpheus "/foo/bar" => [
    '$X'
  ];

You can pass several variables in the list:

  use Morpheus "/foo/bar" => [
    qw( $X $Y $Z )
  ];

Import value to variable with the name different from key's last part:

  use Morpheus "/foo/bar" => [
    "X" => '$FOO_BAR_X',
  ];

Or go to the next level in configuration tree:

  use Morpheus "/foo" => [
    blah => '$FOO_BLAH',
    bar => [ "X" => '$FOO_BAR_X' ],
  ];

=head2 Set defaults and override already defined values

This code will set default values for C</foo/bar/x> and C</foo/bar/y>:

  use Morpheus -defaults => {
    "/foo/bar" => { x => 1, y => 2 },
  };

Since hashrefs and tree nodes are always equivalent in Morpheus, these following versions of code do the same thing too:

  use Morpheus -defaults => {
    "/foo" => { bar => { x => 1, y => 2 } },
  };

Or:

  use Morpheus -defaults => {
    "/foo/bar/x" => 1,
    "/foo/bar/y" => 2,
  };

Values which are set in this fashion are only defaults and will be B<overriden> if any other plugins provide them too.

If you'll say C<-overrides> instead of C<-defaults>, on the contrary, your values will B<override> any values provided by plugins.

=head2 Import helper functions

This module provides several helper functions. They can be imported into your code like this:

  use Morpheus -export => [
      qw( morph merge normalize )
  ];

If this C<-export> option is not specified, then only C<morph()> function will be imported.

More about these functions L<below|/"FUNCTIONS">

=head1 FUNCTIONS

These functions can be imported via C<-export> option.

=over

=item B<morph($key)>

Get value by given key. This function is imported by default.

=item B<normalize($data)>

Expand data by replacing all keys containing C</> in their names with nested hashrefs.

For example, C<< normalize({ "a/b/c" => "d" }) >> will return C<< { a => { b => { c => "d" } } } >>.

=item B<< merge($value, $patch) >>

Merge two configuration subtrees together, including all deeply nested substructures.

=back

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

