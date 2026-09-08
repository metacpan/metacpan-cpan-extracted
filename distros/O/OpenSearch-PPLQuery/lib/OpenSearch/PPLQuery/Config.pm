package OpenSearch::PPLQuery::Config;
$OpenSearch::PPLQuery::Config::VERSION = '1.0.0';
# Reader and validator for the named-connection JSON file. The file format is
# documented for users in PPLQuery.pod under "NAMED CONNECTIONS"; this module's
# interface is described here in comments because it is internal to the
# pplquery command.
#
# Interface, for maintainers:
#
#   ->load($path)      parse and fully validate, or throw; returns an object
#   ->default_path     platform location (APPDATA on Windows, else XDG)
#   ->path             absolute path of the loaded file
#   ->default_name     name of the declared default connection, or undef
#   ->names            configured connection names, sorted
#   ->connection($n)   a shallow copy of one connection's normalized settings
#   ->descriptions     all connections in the shape --list-connections prints
#
# Validation is strict and happens entirely in _validate at load time, so a
# malformed file is rejected before any network call rather than producing a
# confusing failure later. Unknown properties are errors, not warnings: a
# misspelled key that was ignored would leave the user believing a security
# setting had been applied when it had not.
#
# ->connection returns a copy because bin/pplquery deletes the password-source
# keys from what it gets back before merging the rest into client options.
#
# Passwords are never read here. The file names a password *source*; resolving
# it belongs to the command, which is where the CLI and environment overrides
# that outrank it also live.

use v5.36;
use utf8;

use B ();
use Cpanel::JSON::XS ();
use File::Basename qw(dirname);
use File::Spec ();
use OpenSearch::PPLQuery ();
use URI ();

my $JSON = Cpanel::JSON::XS->new->utf8(0)->canonical(1);

sub load {
    my ($class, $path) = @_;
    die "Connection configuration path is required\n" if !defined($path) || $path eq '';

    open my $handle, '<:encoding(UTF-8)', $path or die "Cannot open connection configuration $path: $!\n";
    local $/;
    my $text = <$handle> // '';
    close $handle or die "Cannot close connection configuration $path: $!\n";

    my $document;
    {
        local $@;
        $document = eval { $JSON->decode($text) };
        die "Connection configuration $path is not valid JSON: $@" if $@ ne '';
    }
    my $absolute_path = File::Spec->rel2abs($path);
    my $self = bless {path => $absolute_path}, $class;
    $self->_validate($document);
    return $self;
}

sub default_path {
    if ($^O eq 'MSWin32') {
        my $appdata = _environment_text('APPDATA');
        die "APPDATA is required to locate the default connection configuration\n" if !defined($appdata) || $appdata eq '';
        return File::Spec->catfile($appdata, 'pplquery', 'connections.json');
    }
    my $base = _environment_text('XDG_CONFIG_HOME');
    if (!defined($base) || $base eq '') {
        my $home = _environment_text('HOME');
        die "HOME is required to locate the default connection configuration\n" if !defined($home) || $home eq '';
        $base = File::Spec->catdir($home, '.config');
    }
    return File::Spec->catfile($base, 'pplquery', 'connections.json');
}

sub path { return $_[0]{path}; }
sub default_name { return $_[0]{default}; }
sub names { return sort keys %{$_[0]{connections}}; }

sub connection {
    my ($self, $name) = @_;
    die "Connection name is required\n" if !defined($name) || $name eq '';
    die "Connection '$name' does not exist in $self->{path}\n" if !exists $self->{connections}{$name};
    return {%{$self->{connections}{$name}}};
}

sub descriptions {
    my ($self) = @_;
    return [map {
        my $connection = $self->{connections}{$_};
        +{
            name => $_,
            url => $connection->{url},
            authentication => {
                type => $connection->{auth_type},
                ($connection->{auth_type} eq 'basic' ? (username => $connection->{user}) : ()),
                (defined($connection->{password_environment}) ? (passwordEnvironment => $connection->{password_environment}) : ()),
                (defined($connection->{password_file}) ? (passwordFile => $connection->{password_file}) : ()),
            },
            tls => {
                verify => $connection->{insecure} ? Cpanel::JSON::XS::false : Cpanel::JSON::XS::true,
                (defined($connection->{ca_file}) ? (caFile => $connection->{ca_file}) : ()),
            },
            timeoutSeconds => $connection->{timeout},
        }
    } $self->names];
}

sub _validate {
    my ($self, $document) = @_;
    _object($document, 'Connection configuration');
    _keys($document, 'Connection configuration', qw(default connections));
    _object($document->{connections}, 'Connection configuration connections');
    die "Connection configuration must define at least one connection\n" if !keys %{$document->{connections}};

    my %connections;
    my $directory = dirname($self->{path});
    for my $name (keys %{$document->{connections}}) {
        die "Connection name '$name' is invalid\n" if $name !~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
        my $input = $document->{connections}{$name};
        _object($input, "Connection '$name'");
        _keys($input, "Connection '$name'", qw(url authentication tls timeoutSeconds));
        my $url = _nonempty_string($input->{url}, "Connection '$name' url");

        my $authentication = $input->{authentication};
        _object($authentication, "Connection '$name' authentication");
        _keys($authentication, "Connection '$name' authentication", qw(type username passwordEnvironment passwordFile));
        my $auth_type = _nonempty_string($authentication->{type}, "Connection '$name' authentication type");
        die "Connection '$name' authentication type must be 'none' or 'basic'\n" if $auth_type ne 'none' && $auth_type ne 'basic';
        my ($user, $password_environment, $password_file);
        if ($auth_type eq 'basic') {
            $user = _nonempty_string($authentication->{username}, "Connection '$name' authentication username");
            die "Connection '$name' authentication username must contain only ASCII characters\n" if $user =~ /[^\x00-\x7f]/;
            die "Connection '$name' authentication cannot specify both passwordEnvironment and passwordFile\n"
                if exists($authentication->{passwordEnvironment}) && exists($authentication->{passwordFile});
            if (exists $authentication->{passwordEnvironment}) {
                $password_environment = _nonempty_string($authentication->{passwordEnvironment}, "Connection '$name' authentication passwordEnvironment");
                die "Connection '$name' authentication passwordEnvironment is not a valid environment variable name\n"
                    if $password_environment !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
            }
            if (exists $authentication->{passwordFile}) {
                $password_file = _nonempty_string($authentication->{passwordFile}, "Connection '$name' authentication passwordFile");
                $password_file = File::Spec->rel2abs($password_file, $directory);
            }
        } elsif (exists $authentication->{username}) {
            die "Connection '$name' authentication username requires basic authentication\n";
        } elsif (exists($authentication->{passwordEnvironment}) || exists($authentication->{passwordFile})) {
            die "Connection '$name' authentication password source requires basic authentication\n";
        }

        my ($ca_file, $insecure);
        if (exists $input->{tls}) {
            my $tls = $input->{tls};
            _object($tls, "Connection '$name' tls");
            _keys($tls, "Connection '$name' tls", qw(verify caFile));
            if (exists $tls->{verify}) {
                die "Connection '$name' tls verify must be a JSON boolean\n" if !Cpanel::JSON::XS::is_bool($tls->{verify});
                $insecure = $tls->{verify} ? 0 : 1;
            }
            if (exists $tls->{caFile}) {
                $ca_file = _nonempty_string($tls->{caFile}, "Connection '$name' tls caFile");
                $ca_file = File::Spec->rel2abs($ca_file, $directory);
            }
            die "Connection '$name' tls caFile cannot be used when verification is disabled\n" if defined($ca_file) && $insecure;
        }

        my $timeout = 60;
        if (exists $input->{timeoutSeconds}) {
            $timeout = $input->{timeoutSeconds};
            die "Connection '$name' timeoutSeconds must be a positive integer\n" if !_json_integer($timeout) || $timeout <= 0;
        }
        _validate_endpoint($name, $url, $auth_type, defined($input->{tls}), $ca_file, $insecure);
        $connections{$name} = {
            url => $url, auth_type => $auth_type, (defined($user) ? (user => $user) : ()),
            (defined($password_environment) ? (password_environment => $password_environment) : ()),
            (defined($password_file) ? (password_file => $password_file) : ()),
            (defined($ca_file) ? (ca_file => $ca_file) : ()), insecure => $insecure ? 1 : 0, timeout => 0 + $timeout,
        };
    }

    if (exists $document->{default}) {
        my $default = _nonempty_string($document->{default}, 'Connection configuration default');
        die "Default connection '$default' does not exist\n" if !exists $connections{$default};
        $self->{default} = $default;
    }
    $self->{connections} = \%connections;
}

sub _object {
    my ($value, $label) = @_;
    die "$label must be a JSON object\n" if ref($value) ne 'HASH';
}

sub _keys {
    my ($value, $label, @allowed) = @_;
    my %allowed = map { $_ => 1 } @allowed;
    for my $key (keys %$value) {
        die "$label contains unknown property '$key'\n" if !$allowed{$key};
    }
}

sub _nonempty_string {
    my ($value, $label) = @_;
    die "$label must be a nonempty JSON string\n" if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _json_integer {
    my ($value) = @_;
    return 0 if !defined($value) || ref($value);
    my $flags = B::svref_2object(\$value)->FLAGS;
    return ($flags & B::SVp_IOK) && !($flags & (B::SVp_NOK | B::SVp_POK));
}

sub _validate_endpoint {
    my ($name, $url, $auth_type, $has_tls, $ca_file, $insecure) = @_;
    die "Connection '$name' url must contain only ASCII characters\n" if $url =~ /[^\x00-\x7f]/;
    my $uri = URI->new($url);
    die "Connection '$name' url must use http or https\n" if !defined($uri->scheme) || ($uri->scheme ne 'http' && $uri->scheme ne 'https');
    die "Connection '$name' url must include a host\n" if !defined($uri->host) || $uri->host eq '';
    die "Connection '$name' url must not include credentials, a query, or a fragment\n" if defined($uri->userinfo) || defined($uri->query) || defined($uri->fragment);
    die "Connection '$name' url must be a base URL without a path\n" if $uri->path ne '' && $uri->path ne '/';
    die "Connection '$name' basic authentication requires an https URL\n" if $auth_type eq 'basic' && $uri->scheme ne 'https';
    die "Connection '$name' tls settings require an https URL\n" if $has_tls && $uri->scheme ne 'https';
}

sub _environment_text {
    my ($name) = @_;
    return undef if !exists $ENV{$name};
    return OpenSearch::PPLQuery::decode_utf8($ENV{$name}, "environment variable $name");
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

OpenSearch::PPLQuery::Config - Named-connection configuration for pplquery

=head1 DESCRIPTION

Internal support module for the C<pplquery> command. It loads and validates the named-connection file, whose format is documented in L<pplquery> under B<NAMED CONNECTIONS>.

This module is not a public interface and carries no compatibility guarantee. Its methods are described in comments in the source.

=head1 SEE ALSO

L<pplquery>, L<OpenSearch::PPLQuery>

=head1 LICENSE

Copyright 2026 John Karr.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 or later.

=cut
