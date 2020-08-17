package Net::EtcDv2::Node::Directory {
    use v5.30;
    use strictures;
    use utf8;
    use English;

    use feature ":5.30";
    use feature 'lexical_subs';
    use feature 'signatures';
    use feature 'switch';
    no warnings "experimental::signatures";
    no warnings "experimental::smartmatch";

    use boolean;
    use Data::Dumper;
    use Errno qw(:POSIX);
    use HTTP::Request;
    use HTTP::Status qw(:constants);
    use JSON;
    use LWP::UserAgent;
    use Throw qw(throw classify);
    use Try::Tiny qw(try catch);

    use Net::EtcDv2::Node;

    # class references
    my $node = undef;

    # class member data
    my $debug    = false;
    my $host     = undef;
    my $port     = undef;
    my $user     = undef;
    my $password = undef;

    sub new ($class, %args) {
        if (exists $args{'debug'} && $args{'debug'} eq true) {
            $debug = true;
        }

        my $sub = (caller(0))[3];
        if ($debug eq true) {
            say "DEBUG: Sub: $sub";
            say "DEBUG: Constructing object";
        }

        $host     = $args{'host'};
        $port     = $args{'port'};

        if (exists $args{'user'}) {
            $user     = $args{'user'};
        }
        if (exists $args{'password'}) {
            $password = $args{'password'};
        }

        $node = Net::EtcDv2::Node->new(
            'debug'     => $debug,
            'host'      => $host,
            'password'  => $password,
            'port'      => $port,
            'user'      => $user
        );

        my $self = {};
        bless $self, $class;
    }

    our sub mkdir ($self, $path) {
        my $sub = (caller(0))[3];
        say STDERR "DEBUG: Sub: $sub" if $debug;

        my $content        = undef;
        my $request_struct = undef;
        my $status         = undef;
        # we cannot create a directory if it already exists
        try {
            $content = $node->stat($path) or throw "HTTP error", {
                'type' => int($ERRNO),
                'error_string' => $ERRNO,
                'info' => 'Attempted to create directory in cluster'
            };
            if (defined $content && $content->{'type'} eq 'dir') {
                throw 'Directory Exists', {
                    'type'         => 200,
                    'error_string' => 'item exists',
                    'info'         => 'Attempted to create directory in cluster'
                };
            } elsif (defined $content && $content->{'type'} ne 'dir') {
                throw 'Not a Directory', {
                    'type'         => 400,
                    'error_string' => 'item exists, not a directory',
                    'info'         => 'Attempted to create directory in cluster'
                }
            } else {
                throw 'No Such Directory', {
                    'type'         => 404,
                    'error_string' => 'item not found',
                    'info'         => 'Attempted to create directory in cluster'
                }
            }
        } catch {
            say "DEBUG: args" . Dumper($ARG) if $debug;
            my $exception_type = $ARG->{'error'};
            my $error_code     = $ARG->{'type'};
            my $error_string   = $ARG->{'error_string'};
            my $info           = $ARG->{'info'};
            say "DEBUG: code; $error_code" if $debug;
            classify $ARG, {
                200 => sub {
                    say "DEBUG: Path '$path' already exists. Cannot create directory" if $debug;
                    $status = false;
                    throw $exception_type, {
                        'type'         => $error_code,
                        'error_string' => $error_string,
                        'info'         => $info
                    }
                },
                404 => sub {
                    say "DEBUG: Path '$path' does not exist. Creating directory" if $debug;
                    # now we can actually create the directory
                    my $ua = LWP::UserAgent->new();
                    unless (defined $user && defined $password) {
                        my %args = ('dir' => 'true');
                        my $request = $ua->put("$host:$port/v2/keys$path", \%args);
                        say "DEBUG: request: ". Dumper($request) if $debug;
                        $status = true;
                        $request_struct = $request->content();
                    } else {
                        my $response = $ua->credentials("$host:$port", 'Basic', $user, $password);
                        my %args = ('dir' => 'true');
                        my $request = $ua->put("$host:$port/v2/keys$path". \%args);
                        say "DEBUG: request: ". Dumper($request) if $debug;
                        $status = true;
                        $request_struct = $request->content();
                    }
                },
                default => sub {
                    say STDERR "DEBUG: Got a default error:" if $debug;
                    say STDERR "DEBUG: ". Dumper($ARG) if $debug;
                    throw $ARG->{'error'}, {
                        'type'         => $ARG->{'type'},
                        'error_string' => $ARG->{'error_string'},
                        'info'         => $ARG->{'info'}
                    };
                }
            };
        };
        if ($status = true) {
            return ($JSON::true, $request_struct);
        } else {
            return ($JSON::false, '{"error":"Entry already exists"}');
        }
    }

    our sub rmdir ($self, $path, $recursive = false) {
        my $sub = (caller(0))[3];
        say STDERR "DEBUG: Sub: $sub" if $debug;

        my $content        = undef;
        my $request_struct = undef;
        my $status         = undef;
        # we cannot create a directory if it already exists
        try {
            $content = $node->stat($path) or throw "HTTP error", {
                'type' => int($ERRNO),
                'error_string' => $ERRNO,
                'info' => 'Attempted to create directory in cluster'
            };
            if (defined $content && $content->{'type'} eq 'dir') {
                throw 'Directory Exists', {
                    'type'         => 200,
                    'error_string' => 'item exists',
                    'info'         => 'Attempted to remove directory in cluster'
                };
            } elsif (defined $content && $content->{'type'} ne 'dir') {
                throw 'Not a Directory', {
                    'type'         => 400,
                    'error_string' => 'item exists, not a directory',
                    'info'         => 'Attempted to remove directory in cluster'
                }
            } else {
                throw 'No Such Directory', {
                    'type'         => 404,
                    'error_string' => 'item not found',
                    'info'         => 'Attempted to remove directory in cluster'
                }
            }
        } catch {
            say "DEBUG: args" . Dumper($ARG) if $debug;
            my $exception_type = $ARG->{'error'};
            my $error_code     = $ARG->{'type'};
            my $error_string   = $ARG->{'error_string'};
            my $info           = $ARG->{'info'};
            say "DEBUG: code; $error_code" if $debug;
            classify $ARG, {
                200 => sub {
                    say "DEBUG: Path '$path' exists. Attempting to delete directory" if $debug;
                    $status = true;
                    my $ua = LWP::UserAgent->new();
                    unless (defined $user && defined $password) {
                        my $request = undef;
                        if ($recursive eq true) {
                            $request = $ua->delete("$host:$port/v2/keys$path?recursive=true");
                            say "DEBUG: request: ". Dumper($request) if $debug;
                        } else {
                            $request = $ua->delete("$host:$port/v2/keys$path?dir=true");
                            say "DEBUG: request: ". Dumper($request) if $debug;
                        }
                        $status = true;
                        $request_struct = $request->content();
                    } else {
                        my $response = $ua->credentials("$host:$port", 'Basic', $user, $password);
                        my $request = undef;
                        if ($recursive eq true) {
                            $request = $ua->delete("$host:$port/v2/keys$path?recursive=true");
                            say "DEBUG: request: ". Dumper($request) if $debug;
                        } else {
                            $request = $ua->delete("$host:$port/v2/keys$path?dir=true");
                            say "DEBUG: request: ". Dumper($request) if $debug;
                        }
                        $status = true;
                        $request_struct = $request->content();
                    }
                },
                404 => sub {
                    say "DEBUG: Path '$path' does not exist. Cannot remove non-existing directory" if $debug;
                    $status = false;
                    throw $exception_type, {
                        'type'         => $error_code,
                        'error_string' => $error_string,
                        'info'         => $info
                    }
                },
                default => sub {
                    say STDERR "DEBUG: Got a default error:" if $debug;
                    say STDERR "DEBUG: ". Dumper($ARG) if $debug;
                    throw $ARG->{'error'}, {
                        'type'         => $ARG->{'type'},
                        'error_string' => $ARG->{'error_string'},
                        'info'         => $ARG->{'info'}
                    };
                }
            };
        };
        if ($status = true) {
            return ($JSON::true, $request_struct);
        } else {
            return ($JSON::false, '{"error":"Entry does not exist"}');
        }
    }

    true; # End of Net::EtcDv2
}

=head1 NAME

Net::EtcDv2::DirectoryActions - A object oriented Perl module to create or remove directories with the EtcD version 2 API

=head1 VERSION

Version 0.0.3

=head1 SYNOPSIS

    use feature say;
    use Data::Dumper;
    use Net::EtcDv2::DirectoryActions;

    # create an un-authenticated object for an etcd running on localhost on
    # port 2379
    my $foo = Net::EtcDv2->new(
        'host' => "http://localhost",
        'port' => 2379
    );
    
    my $stat_struct = $foo->stat('/myDir');
    say Dumper $stat_struct;

    # outputs the following if '/myDir' exists and is a directory
    # $VAR1 = {
    #   'type' => 'dir',
    #   'uri' => 'http://localhost:2379/myDir',
    #   'ace' => '*:POST, GET, OPTIONS, PUT, DELETE',
    #   'entryId' => 'cdf818194f3b8d32:23'
    # };
    #
    # The ACE is the access allowed methods and and origin for that path, and
    # the 'entryId' is made up from the cluster ID and the etcd item index ID

=head1 DESCRIPTION

The Net::EtcDv2::DirectoryActions is an internal module to the Net::EtcDv2
distribution. This module allows code to create, list, and delete directories
in an etcd cluster.

=head1 METHODS

=head2 new

The constructor for the class. For now, we only support HTTP basic 
authentication.

If the DEBUG environment variable is set, the class will emit debugging
output on STDERR.

B<Parameters:>

  - class, SCALAR: The class name
  - args,  HASH:   A hash of named parameters:
    - host:        the hostname of the etcd endpoint
    - port:        the port number of the etcd endpoint
    - user:        the username authorized for the etcd environment
    - password:    the password for the user authorized for the etcd
                   environment

=head2 mkdir

This method creates a directory if the named object does not already exist
at that level of the heirarchy. If it already exists, no matter if it is a
key or directory, it emits an exception.

B<Parameters:>

  - self, SCALAR REF: the object reference
  - path, SCALAR:     the full path to create

B<Return type:>

  - path, SCALAR:     the full path that was created

B<Exceptions:>

If the named entry, irregardless of the type, exists, the method will emit
error EEXIST

=head2 rmdir

This method will delete a directory if the named object exists, and is empty.
If any of the following are true, the method emits and appropriate exception:

  - If the directory does not exist
  - If the directory is not empty unless the recursive flag is passed
  - If the object is not a directory

B<Parameters:>

  - self, SCALAR REF: the object reference
  - path, SCALAR:     the full path to delete
  - recursive, boolean: whether to recursively delete the directory if it
                        contains any content

B<Return type:>

  - path: SCALAR:       the path that was created

B<Exceptions:>

The following exceptions are emitted during error events:

  - If the directory does not exist, a 404 exception is thrown
  - If the directory is not empty, a 400 exception is thrown
  - If the object is not a directory, a 400 exception is thrown

=head1 AUTHOR

Gary L. Greene, Jr., C<< <greeneg at tolharadys.net> >>

=head1 BUGS

Please report any bugs or feature requests via this module's GitHub Issues tracker, here: 
L<https://github.com/greeneg/Net-EtcDv2>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::EtcDv2

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-EtcDv2>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-EtcDv2>

=item * Search CPAN

L<https://metacpan.org/release/Net-EtcDv2>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Gary L. Greene, Jr.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
