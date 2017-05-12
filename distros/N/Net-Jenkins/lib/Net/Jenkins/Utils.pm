package Net::Jenkins::Utils;
use warnings;
use strict;
use URI;
use Net::Jenkins;
use Net::Jenkins::Job;
use Net::Jenkins::Job::Build;
use parent 'Exporter';

our @EXPORT_OK = qw(build_job_object build_build_object build_api_object);

sub build_job_object;
sub build_api_object;
sub build_build_object;

sub build_api_object ($) {
    my $url = shift;
    my $uri = ref($url) eq 'URI' ? $url : URI->new( $url );
    return Net::Jenkins->new( 
        host => $uri->host, 
        port => $uri->port , 
        scheme => $uri->scheme );
}

sub build_build_object ($) {
    my $build_url = shift;
    my $uri = URI->new( $build_url );

    # http://ci.jruby.org/job/jruby-git/4259/api/json
    my ($job_name,$build_id) = 
        ($build_url =~ m{/job/([^/]+)/([^/]+)});


    my ($job_url) = ($build_url =~ m{^(.*/job/[^/]+)});

    my $job = build_job_object $job_url;
    my $build = Net::Jenkins::Job::Build->new(
        number => $build_id,
        url => $build_url,
        job => $job,
        api => build_api_object($job_url),
    );
    return $build;
}

sub build_job_object ($) {
    my $job_url = shift;
    my $uri = URI->new($job_url);
    my ($job_name) = ($job_url =~ m{job/([^/]+)});

    my $job = Net::Jenkins::Job->new( 

        # XXX: color attribute
        name => $job_name,
        url => $job_url,
        api => build_api_object $job_url,
    );
    return $job;
}


1;
__END__

=head2 build_job_object (Str $job_url)

@return Net::Jenkins::Job

=cut


