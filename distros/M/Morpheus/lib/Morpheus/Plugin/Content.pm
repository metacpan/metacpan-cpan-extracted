package Morpheus::Plugin::Content;
{
  $Morpheus::Plugin::Content::VERSION = '0.46';
}

# ABSTRACT: base class for plugins that evaluate user defined perl configs


use strict;

use Morpheus::Utils qw(normalize);
use Digest::MD5 qw(md5_hex);
use Symbol qw(delete_package);

sub _package ($$) {
    my ($self, $token) = @_;
    my $md5_self = md5_hex("$self");
    my $md5 = md5_hex($token);
    $token =~ s/[^\w]/_/g;
    $token = substr($token, 0, 64); # max identifier length is limited in perl
    return "Morpheus::Sandbox::${md5_self}::${token}_${md5}";
}

sub DESTROY {
    local $@;
    my ($self) = @_;
    my $md5_self = md5_hex("$self");
    my $sandbox = "Morpheus::Sandbox::${md5_self}";
    my $stash = do { no strict qw(refs); \%{"${sandbox}::"}; };
    for (keys %$stash) {
        /^(.*)::$/ or next;
        delete_package($sandbox."::$1");
    }
    delete_package($sandbox);
}

sub content ($$) {
    my ($self, $token) = @_;
    die;
}

sub _process ($$) {
    my ($self, $token) = @_;
    return if exists $self->{cache}->{$token};

    my $package = $self->_package($token);
    my $content = $self->content($token);
    return unless $content;

    # a partial evaluation support
    $self->{cache}->{$token} = undef; 
    # this line makes it possible to properly process config blocks like
    #############################
    # $X = 5;
    # $Y = morph("X") + 1; # 6 
    #############################
    
    my $pragma = "";
    $pragma = qq{# line 1 "$token"} if $token =~ m{^[/\w\.\-]+$}; # looks like a file name

    my @eval = eval qq{
no strict;
no warnings;
package $package;
$pragma
$content
};
    die if $@;

    $self->{cache}->{$token} = $self->_get($token);
    unless (defined $self->{cache}->{$token}) {
        if (@eval == 1) {
            ($self->{cache}->{$token}) = @eval;
        } else {
            $self->{cache}->{$token} = {@eval};
        }
        $self->{cache}->{$token} = normalize($self->{cache}->{$token});
    }
    die "'$token': config block should return or define something" unless defined $self->{cache}->{$token};
}

# get a value from the stash or from cache
sub _get ($$) {
    my ($self, $token) = @_;
    return $self->{cache}->{$token} if defined $self->{cache}->{$token};

    # maybe a partially evaluated config block
    my $package = $self->_package($token);
    my $stash = do { no strict 'refs'; \%{"${package}::"} };
    my $value;
    for (keys %$stash) {
        next unless $_;
        my $glob = \$stash->{$_};
        if (defined *{$glob}{HASH}) {
            # warn "\%$_ defined at $token\n";
            *{$glob} = normalize(*{$glob}{HASH});
            $value->{$_} = $glob;
        } elsif (defined *{$glob}{ARRAY}) {
            # warn "\@$_ defined at $token\n";
            $value->{$_} = $glob;
        } elsif (defined ${*{$glob}}) {
            $value->{$_} = normalize(${*{$glob}});
        }
    }
    return $value;
}

sub list ($$) {
    return (); # override it
}

sub get ($$) {
    my ($self, $token) = @_;
    $self->_process($token);
    return $self->_get($token);
}

sub new {
    my $class = shift;
    bless { cache => {} } => $class;
}

1;

__END__
=pod

=head1 NAME

Morpheus::Plugin::Content - base class for plugins that evaluate user defined perl configs

=head1 VERSION

version 0.46

=head1 CONFIGURATION BLOCKS

Some morpheus plugins, such as L<Morpheus::Plugin::File>, L<Morpheus::Plugin::DB> and L<Morpheus::Plugin::Env>, provide configuration data by evaluating a custom user defined pieces of a perl code. These code fragments are refered as I<Configuration blocks>. There are two styles of those blocks.

=head2 Imperative style

Example:

    $FOO = "foo";
    $BAR = 42;
    my $x = 1;
    $BAZ = { x => $x };

The blocks of this style are interpreted as follows. The code is evaluated inside of an autogenerated sandbox package, then the values stored in the stash (a hash of global variables) of this package are gathered into a hash and it is considered a return value of a block, "my" variables are ignored. So the example above provides the following configuration:

    {
        'BAZ' => {
            'x' => 1
        },
        'BAR' => 42,
        'FOO' => 'foo'
    }

Arrays (@) and hashes (%) are also currently supported and result in globrefs as configuration values. For example a block like

    $X = "x";
    @X = (1,2,3);
    %Y = ( a => "b" );

will lead to a configuration

    {
        'X' => \*GLOB1 # ${...} of this glob is "x" while @{...} of it is (1,2,3)
        'Y' => \*GLOB2 # %{...} of this glob is (a => "b")
    }

Arrays (@) and hashes (%) are wrapped into globrefs even when they do not collide with a scalar ($) value. It is done to distinguish between

    $X = [1,2,3];

and

    @X = (1,2,3);

In fact this feature about globrefs is believed to be deprecated and may be removed in the future. Try to use only scalars ($) while providing your configuration values and wrap the arrays and hashes you require into arrayrefs and hashrefs.

In case after the evaluation of a block the stash is empty or contains only subs, the block is considered to be of a second, functional style.

=head2 Functional style

Example:

    my $x = 1;
    {
        FOO => "foo",
        BAR => 42,
        BAZ => { x => $x },
    }

The blocks of this style are interpreted differently. The result of evaluation (the last statement or an argument of a "return" operator) is the result of a functional style block while the stash (containing nothing except subs) is ignored.

=head2 Comparison

The configuration values may be subs themselves. It doesn't affect the style of a block, for example

    $FOO = sub { print "foo" };

is still an imperative style block, not a functional style one. From the point of view of a stash C<$FOO> is a scalar regardless its value is a sub(ref). But

    sub FOO {
        return shift . "oo";
    }
    {
        BAR => FOO("f"),
    }

is a functional style block, as the only thing stash contains after the block evaluation is C<&FOO> which is a sub.

Imperative and functional styles both have their advantages and disadvantages, so you may pick the style that better fits your current needs. Functional style block may provide a primitive value like just a string or number, that cannot be expressed as an imperative style block. You cannot defined a variable with an empty name, so imperative blocks always return a hashref as their result. Also in functional style blocks long keys expansion is supported, that is

    {
        "x/y/z" => 1,
        ...
    }

becomes

    {
        x => { y => { z => 1 } },
        ...
    }

that makes functional blocks very suitable to provide sevaral simple but deeply nested values.

=head2 ADVANCED TECHNIQUES

You are free to use any kind of perl operators in configuration blocks. Any strings and numbers operations, branches, cycles, function definitions and calls, even imports of arbitrary perl modules. If your configuration block is a large and complex one, you may consider using strict and warnings. One of the most mysterious things your are allowed to do is the resursive calls back to the Morpheus to get some configuration variables, while your block is providing some configuration variables itself. Though there exists some protection from infinite recursion, use this feature at your own risk, it is your own responsibility to prevent cyclic dependencies between the configuration variables. No warranty etc. :)

There are several typical applications of the recursive Morpheus calls. Do not forget to C<use Morpheus> in a configuration block to make recursive calls possible.

=head2 Links and dependencies

Links are like symlinks in a file system. You may configure some variable to get its value from some other variable:

    use Morpheus;
    $VAR2 = morph("/FOO/BAR/VAR1");

It is especially useful when you are refactoring your configuration tree structure but still want your legacy programs to work properly.

Not only equality but more complex dependencies between variables may also be expressed, for example:

    use Morpheus;
    $LOG_NAME = morph("/LOG_DIR") . "/my.log";
    $LIST2 = [ @{morph("/LIST1")}, "some", "more", "items" ];
    $LIST3 = [ grep { $_ !~ /some|filter/ } @{"/LIST1"} ];

=head2 High level configuration

Technically this is a particular case of configuration variables dependency, but ideologically it is a bit different thing. You may define some high level configuration variables like debug/release or dev/testing/production and make other configuration variables depend on them. The choice of those high level configuration values would also be made by Morpheus at some other point of configuration.

    use Morpheus;
    my $debug = morph("/debug");
    $THREADS = 50;
    $THREADS = 1 if $debug; # fewer theads when running in debug mode
    $LOG_LEVEL = "INFO";
    $LOG_LEVEL = "DEBUG" if $debug; # more verbose logging in debug mode

    $SOME_SERVICE_URL = {
        dev => "http://some-service-dev:12345/",
        testing => "http://some-service-dev/",
        production => "http://some-service/",
        # pick up a proper some-service url depending on the /environment value
    }->{morph("/environment")} or die "unexpected /environment";

=head2 Super calls

Morpheus plugins are arranged with respect to their priority. Sometimes there exists the same mechanism within a single plugin too, for example a configuration file example.20.cfg has a priority over example.10.cfg, though they are both interpreted by the same C<Morpheus::Plugin::File>. A higher priority config overrides the value provided by a lower proirity one. There are cases when a higher priority config wants to adjust the lower priority value rather then simply replace it. In OOP it is achieved using the "super" call ("super" keyword in java for example). Morpheus provides the similar opportunity: just access the same configuration variable you are now trying to provide and you will make a super call. Do not worry about the infinite recursion, Morpheus engine keeps track of the plugins and even particular configuration blocks that are currently being evaluated so it skips them upon a recursive call.

Consider an example:

    # example.10.cfg:
    $X = 1;
    $Y = 2;

    # example.20.cfg:
    use Morpheus;
    $X = morph("/example/X") + 3;

This leads to the configuration of "/example/"

    {
      'X' => 4,
      'Y' => 2
    }

as the higher priority config example.20.cfg has accessed a value of X provided by the lower proirity config example.10.cfg.

=head2 Partial block evaluation support

Morpheus supports a partial evaluation of the imperative style configuration blocks. That is already defined stash variables are visible through resursive calls though configuration block may be not fully evaluated yet.

    # example.cfg:
    use Morpheus;
    $X = 1;
    $Y = morph("/example/X") + 2;

results in configuration

    {
        'X' => 1,
        'Y' => 3
    }

Please pay attention that a simplier config

    $X = 1;
    $Y = $X + 2;

is not the same as in the example above, because the value of /example/X may be overriden by a higher priority config. This simplyfied version will not be affected, but the original config will modify the value of /example/Y accordingly.

Functional style blocks do not support partial evaluation feature. Config

    # example.cfg:
    use Morpheus;
    {
        X => 1,
        Y => morph("/example/X") + 2,
    }

will (wrongly) return a configuration

    {
        'X' => 1,
        'Y' => 2
    }

as morph("/example/X") will return undef at the moment it is called.

=head2 Caution

Though the recursive calls to Morpheus from the configuration blocks (that are evaluated by Morpheus plugins) is allowed, we highly recommend not to make calls to Morpheus within the code of Morpheus plugins initialization. Neither directly nor indirectly by using modules that are using Morpheus. When Morpheus starts compiling its plugins and it brings perl interpreter back to compiling Morpheus and calling its methods, it leads to a complete mess. Calling Morpheus from the configuration blocks is a big difference, all the plugins are fully initialized at that moment.

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

