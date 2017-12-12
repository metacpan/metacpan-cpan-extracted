package Net::Hadoop::YARN::Roles::AppMasterHistoryServer;
$Net::Hadoop::YARN::Roles::AppMasterHistoryServer::VERSION = '0.203';
use strict;
use warnings;
use 5.10.0;

use Carp qw( croak );
use Hash::Path;
use Moo::Role;

my %validation_pattern = (
    appid     => 'application_[0-9]+_[0-9]+',
    jobid     => 'job_[0-9]+_[0-9]+',
    taskid    => 'task_[0-9]+_[0-9]+_[a-z]_[0-9]+',
    attemptid => 'attempt_[0-9]+_[0-9]+_[a-z]_[0-9]+_[0-9]+',
);

my $RE_EXTRACT_VALIDS = sprintf '(?:%s)',
                                join '|',
                                    map { $validation_pattern{$_} }
                                    keys %validation_pattern;

# used by consuming classes, for specific cases
sub _validate_id {
    my $self = shift;
    return $_[1] =~ /^$validation_pattern{$_[0]}$/;
}

sub _extract_valid_params {
    # TODO: this doesn't recognise container or attempt etc ids per above hash
    #
    my $self = shift;
    my $str  = shift || return;

    my @ids;
    while ( my($type) = $str =~ /$RE_EXTRACT_VALIDS/gc ) {
        push @ids, $type;
    }

    return @ids;
}

sub _mk_subs {
    my $methods_urls = shift;
    my $opt          = shift || {};
    my $pfix         = $opt->{prefix} || '';

    for my $key ( keys %{$methods_urls} ) {

        # use a closure to only run the preprocessing once per method for
        # validation. URL params are of the form {appid}, {taskid}, hence the
        # regexes to find them
        my @param_names = $methods_urls->{$key}[0] =~ m/\{([a-z]+)\}/g;
        my @validations = map {
            my $name = $_;
            {
                name     => $name,
                validate => sub {
                    my $val = shift || return;
                    $val =~ /^$validation_pattern{$name}$/
                },
            };
        } @param_names;

        my $url       = $methods_urls->{$key}[0];
        my $json_path = $methods_urls->{$key}[1];

        my $new_method = sub {
            my $self       = shift;
            # check the list of params validates against the list of
            # placeholders gathered in the url split above
            my $params_idx = 0;

            for my $param ( @_ ) {
                my $v = $validations[ $params_idx ]
                            || do {
                                my $what = $key =~ m{ \A _ }xms
                                         ? do {
                                                if ( my $who = (caller 1)[3] ) {
                                                    my($short) = (split m{ [:]{2} }xms, $who)[-1];
                                                    sprintf qq{%s` via: `%s}, $short, $who;
                                                }
                                                else {
                                                    $key;
                                                }
                                            }
                                         : $key
                                         ;
                                croak sprintf "No validator for `%s` [%s]. Be sure that `%s` is a valid API endpoint for this object",
                                                    $param,
                                                    $params_idx,
                                                    $what,
                                    ;
                                };

                if ( ! ref $param && ! $v->{validate}->( $param ) ) {
                    croak sprintf "Param `%s` doesn't satisfy pattern /%s/ in call to `%s`.",
                                    $param || '',
                                    $validation_pattern{  $v->{name}  },
                                    $key,
                    ;
                }
                $params_idx++;
            }

            # now replace all url placeholders with the params we were given;
            # extra parameters (in a hashref) will be passed as regular URL
            # params, not interpolated in the path
            my $interp_url = $url;
            my $extra_params;
            while (my $param = shift) {
                if (! @_ && ref $param) {
                    $extra_params = $param;
                    last;
                }
                $interp_url =~ s/\{[a-z]+\}/$param/;
            }
            my $res = $self->_get($interp_url, { params => $extra_params });

            # Only return the JSON fragment we need
            return Hash::Path->get($res, split(/\./, $json_path));
        };
        {
            # limit the scope of non-strict-ness
            # insert the method for the endpoint in the using class
            no strict 'refs';
            *{ ( caller() )[0] . '::' . $pfix . $key } = $new_method;
        }
    }
}

sub _mk_uri {
    my $self = shift;
    my ($server, $path, $params) = @_;
    my $uri = $server . "/" . $path;
    $uri =~ s#//+#/#g;
    $uri = URI->new("http://" . $uri);
    if ($params) {
        $uri->query_form($params);
    }
    return $uri;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::Roles::AppMasterHistoryServer

=head1 VERSION

version 0.203

=head1 METHODS

The methods below work the same in L<Net::Hadoop::YARN::ApplicationMaster> and
L<Net::Hadoop::YARN::HistoryServer>, to the exception that the App Master ones
need an application ID as a first parameter. Methods take arguments in a list
ordered according to the endpoint URL mentioned.

=head2 jobs

Jobs API

for the appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs

for the history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs

=head2 Job API

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}

history:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}

http://<proxy http address:port>/proxy/application_1326232085508_0004/ws/v1/mapreduce/jobs/{jobid}

=head2 Job Attempts API

NOTE the documentation gives a wrong address for the appmaster version

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/jobattempts

history server:
    http://<history server http address:port>/ws/v1/history/jobs/{jobid}/jobattempts

=head2 Job Counters API

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/counters

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/counters

=head2 Job Conf API

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/conf

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/conf

=head2 Tasks API

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks

=head2 Task API

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks/{taskid}

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}

=head2 Task Counters API

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks/{taskid}/counters

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/counters

=head2 Task Attempts API

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts

=head2 Task Attempt API

NOTE: documentation misses the ending s for attempts

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}

=head2 Task Attempt Counters API

history server:
    http://<history server http address:port>/ws/v1/history/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}/counters

appmaster:
    http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}/counters

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
