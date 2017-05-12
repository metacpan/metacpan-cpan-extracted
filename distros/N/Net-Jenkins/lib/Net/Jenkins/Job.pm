package Net::Jenkins::Job;
use methods;
use Moose;
use Net::Jenkins::Job::Build;
use Net::Jenkins::Job::QueueItem;

has name => ( is => 'rw' , isa => 'Str' );

# 'color' => 'grey',
has color => ( is => 'rw' );

# 'url' => 'http://localhost:8080/job/Phifty/',
has url => ( is => 'rw' , isa => 'Str' );

has api => ( is => 'rw' , isa => 'Net::Jenkins' );

method delete {
    return $self->api->delete_job( $self->name );
}

method update ($xml) {
    return $self->api->update_job( $self->name, $xml );
}

method copy ($new_job_name) {
    return $self->api->copy_job( $new_job_name , $self->name );
}


method enable {
    return $self->api->enable_job($self->name);
}

method disable {
    return $self->api->disable_job($self->name);
}


# trigger a build
method build {
    return $self->api->build_job($self->name);
}


# get job configuration
method details {
    return $self->api->get_job_details( $self->name );
}

method description {
    return $self->details->{description};
}

method desc {
    return $self->description;
}

method in_queue {
    return $self->details->{inQueue};
}

method queue_item {
    return Net::Jenkins::Job::QueueItem->new( %{ $self->details->{queueItem} } , api => $self->api , job => $self );
}

# get builds
method builds {
    return map { Net::Jenkins::Job::Build->new( %$_ , api => $self->api, job => $self ) } 
            $self->api->get_builds( $self->name );
}

method last_build {
    my $b = $self->details->{lastBuild};
    return Net::Jenkins::Job::Build->new( %$b , api => $self->api , job => $self ) if $b && %$b;
}

method first_build {
    my $b = $self->details->{firstBuild};
    return Net::Jenkins::Job::Build->new( %$b , api => $self->api , job => $self ) if $b && %$b;
}

method to_hashref ($with_details,$with_builds) {
    return {
        name    => $self->name,
        color   => $self->color,
        url     => $self->url,
        ($with_details) ? ( details => $self->details ) : (),
        ($with_builds)  ? (
            builds => [ map { 
                    $_->to_hashref($with_details) 
                } $self->builds ],
        ) : (),
    };
}

1;
__END__
=pod

=head1 NAME

Net::Jenkins::Job

=head1 ATTRIBUTES

=head2 name

=head2 color

=head2 url

=head2 api

=head1 METHODS

=head2 delete

Delete this job.

=head2 update ($xml)

$xml [Str]

Update job configuration from XML.

=head2 copy ($new_job_name)

$new_job_name [Str]

Copy from a job.

=head2 enable 

Enable this job.

=head2 disable

Disable this job.

=head2 build

Trigger build

=head2 details

[HashRef] Get job details

=head2 description

[Str] Get job description

=head2 in_queue

[Bool] Is this job in queue ?

=head2 builds

L<Net::Jenkins::Job::Build>[] get build objects.

=head2 last_build

L<Net::Jenkins::Job::Build> Get last build.

=head2 first_build

L<Net::Jenkins::Job::Build> Get first build.

=cut
