package Prancer::Config;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use File::Spec;
use Config::Any;
use Storable qw(dclone);
use Try::Tiny;
use Carp;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub load {
    my ($class, $path) = @_;
    my $self = bless({}, $class);

    # find config files, load them
    my $files = $self->_build_file_list($path);
    $self->{'_config'} = $self->_load_config_files($files);

    return $self;
}

sub has {
    my ($self, $key) = @_;
    return exists($self->{'_config'}->{$key});
}

sub get {
    my ($self, $key, $default) = @_;

    # only return things if the are running in a non-void context
    if (defined(wantarray())) {
        my $value = undef;

        # if ->get is called without any arguments then this will return all
        # config values as either a hash or a hashref. used by template engines
        # to merge config values into the template vars.
        if (!defined($key)) {
            return wantarray ? %{$self->{'_config'}} : $self->{'_config'};
        }

        if (exists($self->{'_config'}->{$key})) {
            $value = $self->{'_config'}->{$key};
        } else {
            $value = $default;
        }

        # nothing to return
        return unless defined($value);

        # make a clone to avoid changing things
        # through inadvertent references.
        $value = dclone($value) if ref($value);

        if (wantarray() && ref($value)) {
            # return a value rather than a reference
            if (ref($value) eq "HASH") {
                return %{$value};
            }
            if (ref($value) eq "ARRAY") {
                return @{$value};
            }
        }

        # return a reference
        return $value;
    }

    return;
}

sub set {
    my ($self, $key, $value) = @_;

    my $old = undef;
    $old = $self->get($key) if defined(wantarray());

    if (ref($value)) {
        # make a copy of the original value to avoid inadvertently changing
        # things through inadvertent references
        $self->{'_config'}->{$key} = dclone($value);
    } else {
        # can't clone non-references
        $self->{'_config'}->{$key} = $value;
    }

    if (wantarray() && ref($old)) {
        # return a value rather than a reference
        if (ref($old) eq "HASH") {
            return %{$old};
        }
        if (ref($old) eq "ARRAY") {
            return @{$old};
        }
    }

    return $old;
}

sub remove {
    my ($self, $key) = @_;

    my $old = undef;
    $old = $self->get($key) if defined(wantarray());

    delete($self->{'_config'}->{$key});

    if (wantarray() && ref($old)) {
        # return a value rather than a reference
        if (ref($old) eq "HASH") {
            return %{$old};
        }
        if (ref($old) eq "ARRAY") {
            return @{$old};
        }
    }

    return $old;
}

sub _build_file_list {
    my ($self, $path) = @_;

    # an undef location means no config files for the caller
    return [] unless defined($path);

    # if the path is a file or a link then there is only one config file
    return [ $path ] if (-e $path && (-f $path || -l $path));

    # since we already handled files/symlinks then if the path is not a
    # directory then there is very little we can do
    return [] unless (-d $path);

    # figure out what environment we are operating in by looking in several
    # well known (to the PSGI world) environment variables. if none of them
    # exist then we are probably in dev.
    my $env = $ENV{'ENVIRONMENT'} || $ENV{'PLACK_ENV'} || "development";

    my @files = ();
    for my $ext (Config::Any->extensions()) {
        for my $file (
            [ $path, "config.${ext}" ],
            [ $path, "${env}.${ext}" ]
        ) {
            my $file_path = _normalize_file_path(@{$file});
            push(@files, $file_path) if (-r $file_path);
        }
    }

    return \@files;
}

sub _load_config_files {
    my ($self, $files) = @_;

    return _merge(
        map { $self->_load_config_file($_) } @{$files}
    );
}

sub _load_config_file {
    my ($self, $file) = @_;
    my $config = {};

    try {
        my @files = ($file);
        my $tmp = Config::Any->load_files({
            'files' => \@files,
            'use_ext' => 1,
        })->[0];
        ($file, $config) = %{$tmp} if defined($tmp);
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "unable to parse ${file}: ${error}";
    };

    return $config;
}

sub _normalize_file_path {
    my $path = File::Spec->catfile(@_);

    # this is a revised version of what is described in
    # http://www.linuxjournal.com/content/normalizing-path-names-bash
    # by Mitch Frazier
    my $seqregex = qr{
        [^/]*       # anything without a slash
        /\.\.(/|\z) # that is accompanied by two dots as such
    }x;

    $path =~ s{/\./}{/}gx;
    $path =~ s{$seqregex}{}gx;
    $path =~ s{$seqregex}{}x;

    # see https://rt.cpan.org/Public/Bug/Display.html?id=80077
    $path =~ s{^//}{/}x;
    return $path;
}

# stolen from Hash::Merge::Simple
sub _merge {
    my ($left, @right) = @_;

    return $left unless @right;
    return _merge($left, _merge(@right)) if @right > 1;

    my ($right) = @right;
    my %merged = %{$left};

    for my $key (keys %{$right}) {
        my ($hr, $hl) = map { ref($_->{$key}) eq "HASH" } $right, $left;

        if ($hr and $hl) {
            $merged{$key} = _merge($left->{$key}, $right->{$key});
        } else {
            $merged{$key} = $right->{$key};
        }
    }

    return \%merged;
}

1;

=head1 NAME

Prancer::Config

=head1 SYNOPSIS

    # load a configuration file when creating a PSGI application
    # this loads only one configuration file
    my $psgi = Foo->new("/path/to/foobar.yml")->to_psgi_app();

    # just load the configuration and use it wherever
    # this loads all configuration files from the given path using logic
    # described below to figure out which configuration files take precedence
    my $app = Prancer::Core->new("/path/to/mysite/conf");

    # the configuration can be accessed as either a global method or as an
    # instance method, depending on how you loaded Prancer
    print $app->config->get('foo');
    print config->get('bar');

=head1 DESCRIPTION

Prancer uses L<Config::Any> to process configuration files. Anything supported
by that will be supported by this. It will load configuration files from the
configuration file or from configuration files in a path based on what you set
when you create your application.

To find configuration files from given directory, Prancer::Config follows this
logic. First, it will look for a file named C<config.ext> where C<ext> is
something like C<yml> or C<ini>. Then it will look for a file named after the
currently defined environment like C<develoment.ext> or C<production.ext>. The
environment is determined by looking first for an environment variable called
C<ENVIRONMENT> and then for an environment variable called C<PLACK_ENV>. If
neither of those exist then the default is C<development>.

Configuration files will be merged such that configuration values pulled out of
the environment configuration file will take precedence over values from the
global configuration file. For example, if you have two configuration files:

    config.ini
    ==========
    foo = bar
    baz = bat

    development.ini
    ===============
    foo = bazbat

After loading these configuration files the value for C<foo> will be C<bazbat>
and the value for C<baz> will be C<bat>.

If you just have one configuration file and have no desire to load multiple
configuration files based on environments you can specify a file rather than a
directory when your application is created.

Arbitrary configuration directives can be put into your configuration files
and they can be accessed like this:

    $config->get('foo');

The configuration accessors will only give you the configuration directives
found at the root of the configuration file. So if you use any data structures
you will have to decode them yourself. For example, if you create a YAML file
like this:

    foo:
        bar1: asdf
        bar2: fdsa

Then you will only be able to get the value to C<bar1> like this:

    my $foo = config->get('foo')->{'bar1'};

=head2 Reserved Configuration Options

To support the components of Prancer, some keys are otherwise "reserved" in
that you aren't able to use them. For example, trying to use the config key
C<session> will only result in sessions being enabled and you not able to see
your configuration values. These reserved keys are: C<session> and C<static>.

=head1 METHODS

=over

=item has I<key>

This will return true if the named key exists in the configuration:

    if ($config->has('foo')) {
        print "I see you've set foo already.\n";
    }

It will return false otherwise.

=item get I<key> [I<default>]

The get method takes two arguments: a key and a default value. If the key does
not exist then the default value will be returned instead. If the value in the
configuration is a reference then a clone of the value will be returned to
avoid modifying the configuration in a strange way. Additionally, this method
is context sensitive.

    my $foo = $config->get('foo');
    my %bar = $config->get('bar');
    my @baz = $config->get('baz');

=item set I<key> I<value>

The set method takes two arguments: a key and a value. If the key already
exists in the configuration then it will be overwritten and the old value will
be returned in a context sensitive way. If the value is a reference then it
will be cloned before being saved into the configuration to avoid any
strangeness.

    my $old_foo = $config->set('foo', 'bar');
    my %old_bar = $config->set('bar', { 'baz' => 'bat' });
    my @old_baz = $config->set('baz', [ 'foo', 'bar', 'baz' ]);
    $config->set('whatever', 'do not care');

=item remove I<key>

The remove method takes one argument: the key to remove. The value that was
removed will be returned in a context sensitive way.

=back

=head1 SEE ALSO

=over

=item L<Config::Any>

=back

=cut
