package Net::Twitter::Loader;
use strict;
use warnings;
use JSON qw(decode_json encode_json);
use Try::Tiny;
use Carp;
use Time::HiRes qw(sleep);

our $VERSION = "0.04";

our @CARP_NOT = qw(Try::Tiny Net::Twitter Net::Twitter::Lite Net::Twitter::Lite::WithAPIv1_1);

sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;
    croak "backend parameter is mandatory" if not defined $params{backend};
    $self->{backend} = $params{backend};
    $self->_set_param(\%params, 'filepath', undef);
    $self->_set_param(\%params, 'page_max', 10);
    $self->_set_param(\%params, 'page_max_no_since_id', 1);
    $self->_set_param(\%params, 'page_next_delay', 0);
    $self->_set_param(\%params, "logger", undef);
    return $self;
}

sub backend { $_[0]->{backend} }

sub _set_param {
    my ($self, $params_ref, $key, $default) = @_;
    $self->{$key} = defined($params_ref->{$key}) ? $params_ref->{$key} : $default;
}

sub _load_next_since_id_file {
    my ($self) = @_;
    return {} if not defined($self->{filepath});
    open my $file, "<", $self->{filepath} or return undef;
    my $json_text = do { local $/ = undef; <$file> };
    close $file;
    my $since_ids = try {
        decode_json($json_text);
    }catch {
        my $e = shift;
        $self->_log("warn", "failed to decode_json");
        return {};
    };
    $since_ids = {} if not defined $since_ids;
    return $since_ids;
}

sub _log {
    my ($self, $level, $msg) = @_;
    $self->{logger}->($level, $msg) if defined $self->{logger};
}

sub _save_next_since_id_file {
    my ($self, $since_ids) = @_;
    return if not defined($self->{filepath});
    open my $file, ">", $self->{filepath} or die "Cannot open $self->{filepath} for write: $!";
    try {
        print $file encode_json($since_ids);
    }catch {
        my $e = shift;
        $self->_log("error", $e);
    };
    close $file;
}

sub _log_query {
    my ($self, $method, $params) = @_;
    $self->_log("debug", sprintf(
        "%s: method: %s, args: %s", __PACKAGE__, $method,
        join(", ", map {"$_: " . (defined($params->{$_}) ? $params->{$_} : "[undef]")} keys %$params)
    ));
}

sub _normalize_search_result {
    my ($self, $nt_result) = @_;
    if(!ref($nt_result)) {
        confess "Scalar is returned by the backend. Something is wrong.";
    }elsif(ref($nt_result) eq 'ARRAY') {
        return $nt_result;
    }elsif(ref($nt_result) eq 'HASH') {
        if(ref($nt_result->{statuses}) eq 'ARRAY') {    ## REST API v1.1
            return $nt_result->{statuses};
        }elsif(ref($nt_result->{results}) eq 'ARRAY') { ## REST API v1.0
            return $nt_result->{results};
        }
    }
    confess "Unknown type of data returned by the backend. Something is wrong.";
}

sub _load_timeline {
    my ($self, $nt_params, $method, @label_params) = @_;
    my %params = defined($nt_params) ? %$nt_params : ();
    if(not defined $method) {
        $method = (caller(1))[3];
        $method =~ s/^.*:://g;
    }
    my $label = "$method," .
        join(",", map { "$_:" . (defined($params{$_}) ? $params{$_} : "") } @label_params);
    my $since_ids = $self->_load_next_since_id_file();
    my $since_id = $since_ids->{$label};
    $params{since_id} = $since_id if !defined($params{since_id}) && defined($since_id);
    my $page_max = defined($params{since_id}) ? $self->{page_max} : $self->{page_max_no_since_id};
    if($method eq 'public_timeline') {
        $page_max = 1;
    }
    my $max_id = undef;
    my @result = ();
    my $load_count = 0;
    my %loaded_ids = ();
    my $next_since_id;
    while($load_count < $page_max) {
        $params{max_id} = $max_id if defined $max_id;
        $self->_log_query($method, \%params);
        my $loaded;
        try {
            $loaded = $self->_normalize_search_result($self->{backend}->$method({%params}));
        }catch {
            my $e = shift;
            $self->_log("error", $e);
            die $e;
        };
        return undef if not defined $loaded;
        @$loaded = grep { !$loaded_ids{$_->{id}} } @$loaded;
        last if !@$loaded;
        $loaded_ids{$_->{id}} = 1 foreach @$loaded;
        $max_id = $loaded->[-1]{id};
        $next_since_id = $loaded->[0]{id} if not defined $next_since_id;
        push(@result, @$loaded);
        $load_count++;
        sleep($self->{page_next_delay});
    }
    if($load_count == $self->{page_max}) {
        $self->_log("notice", "page has reached the max value of " . $self->{page_max});
    }
    if(defined($next_since_id)) {
        $since_ids = $self->_load_next_since_id_file();
        $since_ids->{$label} = $next_since_id;
        $self->_save_next_since_id_file($since_ids);
    }
    return \@result;
}

sub user_timeline {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params, undef, qw(id user_id screen_name));
}

sub public_timeline {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params);
}

sub home_timeline {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params);
}

sub list_statuses {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params, undef, qw(list_id slug owner_screen_name owner_id));
}

sub search {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params, undef, qw(q lang locale));
}

sub favorites {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params, undef, qw(id user_id screen_name))
}

sub mentions {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params);
}

sub retweets_of_me {
    my ($self, $nt_params) = @_;
    return $self->_load_timeline($nt_params);
}


1;
__END__

=pod

=head1 NAME

Net::Twitter::Loader - repeat loading Twitter statuses up to a certain point

=head1 SYNOPSIS

    use Net::Twitter::Loader;
    use Net::Twitter;
    
    my $loader = Net::Twitter::Loader->new(
        backend => Net::Twitter->new(
            traits => [qw(OAuth API::RESTv1_1)],
            consumer_key => "YOUR_CONSUMER_KEY_HERE",
            consumer_secret => "YOUR_CONSUMER_SECRET_HERE",
            access_token => "YOUR_ACCESS_TOKEN_HERE",
            access_token_secret => "YOUR_ACCESS_TOKEN_SECRET_HERE",
            ssl => 1,
    
            #### If you access to somewhere other than twitter.com,
            #### set the apiurl option
            ## apiurl => "http://example.com/api/",
        ),
        filepath => 'next_since_ids.json',
        logger => sub {
            my ($level, $msg) = @_;
            warn "$level: $msg\n";
        },
    );
    
    ## First call to home_timeline
    my $arrayref_of_statuses = $loader->home_timeline();
    
    ## The latest loaded status ID is saved to next_since_ids.json
    
    ## Subsequent calls to home_timeline automatically load
    ## all statuses that have not been loaded yet.
    $arrayref_of_statuses = $loader->home_timeline();
    
    
    ## You can load other timelines as well.
    $arrayref_of_statuses = $loader->user_timeline({screen_name => 'hoge'});
    
    
    foreach my $status (@$arrayref_of_statuses) {
        printf("%s: %s\n", $status->{user}{screen_name}, Encode::encode('utf8', $status->{text}));
    }


=head1 DESCRIPTION

This module is a wrapper for L<Net::Twitter> (or L<Net::Twitter::Lite>) to make it easy
to load a lot of statuses from timelines.

=head1 FEATURES

=over

=item *

It repeats requests to load a timeline that expands over multiple pages.
C<max_id> param for each request is adjusted automatically.

=item *

Optionally it saves the latest status ID to a file.
The file will be read to set C<since_id> param for the next request,
so that it can always load all the unread statuses.

=back

=head1 CLASS METHODS

=head2 $loader = Net::Twitter::Loader->new(%options);

Creates the object with the following C<%options>.

=over

=item backend => OBJECT (mandatory)

Backend L<Net::Twitter> object. L<Net::Twitter::Lite> object can be used, too.

=item filepath => FILEPATH (optional)

File path for saving and loading the next C<since_id>.
If this option is not specified, no file will be created or loaded.

=item page_max => INT (optional, default: 10)

Maximum number of pages this module tries to load when C<since_id> is given.

=item page_max_no_since_id => INT (optional, default: 1)

Maximum number of pages this module tries to load when no C<since_id> is given.

=item page_next_delay => NUMBER (optional, default: 0)

Delay in seconds before loading the next page. Fractional number can be used.

=item logger => CODE (optional)

A code-ref for logging. If specified, it is called to log what this module is doing.

    $logger->($level, $message)

The logger is called with C<$level> and C<$message>.
C<$level> is the log level string (e.g. C<"debug">, C<"error"> ...) and C<$message> is the log message.

If C<logger> is omitted, the log is suppressed.

=back

=head1 OBJECT METHODS

=head2 $status_arrayref = $loader->home_timeline($options_hashref)

=head2 $status_arrayref = $loader->user_timeline($options_hashref)

=head2 $status_arrayref = $loader->list_statuses($options_hashref)

=head2 $status_arrayref = $loader->public_statuses($options_hashref)

=head2 $status_arrayref = $loader->favorites($options_hashref)

=head2 $status_arrayref = $loader->mentions($options_hashref)

=head2 $status_arrayref = $loader->retweets_of_me($options_hashref)

Wrapper methods for corresponding L<Net::Twitter> methods. See L<Net::Twitter> for specification of C<$options_hashref>.

Note that L<Net::Twitter> accepts non-hashref arguments for convenience, but this is not supported by L<Net::Twitter::Loader>.
You always need to give a hash-ref to these methods.

If C<since_id> is given in C<$options_hashref> or it is loaded from the file specified by C<filepath> option,
these wrapper methods repeatedly call L<Net::Twitter>'s corresponding methods to load a complete timeline newer than C<since_id>.
If C<filepath> option is enabled, the latest ID of the loaded status is saved to the file.

The max number of calling the backend L<Net::Twitter> methods is limited to C<page_max> option
if C<since_id> is specified or loaded from the file. The max number is limited to C<page_max_no_since_id> option
if C<since_id> is not specified.

If the operation succeeds, the return value of these methods is an array-ref of unique status objects.

If something is wrong (e.g. network failure), these methods throw an exception.
In this case, the error is logged if C<logger> is specified in the constructor.

=head2 $status_arrayref = $loader->search($options_hashref)

Same as other timeline methods, but note that it returns only the statuses of the search result.

Original Twitter API returns other fields such as C<"search_metadata">, but those are discarded.

=head2 $backend = $loader->backend()

Get the backend L<Net::Twitter> or L<Net::Twitter::Lite> object.

=head1 SEE ALSO

=over

=item *

L<Net::Twitter>

=item *

L<Net::Twitter::Lite>

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/Net-Twitter-Loader>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Net-Twitter-Loader/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter-Loader>.
Please send email to C<bug-Net-Twitter-Loader at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

