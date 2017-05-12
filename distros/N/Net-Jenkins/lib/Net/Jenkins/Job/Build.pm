package Net::Jenkins::Job::Build;
use Moose;
use methods;
use DateTime;


# {
# 'number' => 2,
# 'url' => 'http://localhost:8080/job/Phifty/2/'
# },

has number => ( is => 'rw' , isa => 'Int' );

has url => ( is => 'rw', isa => 'Str' );

has job => ( is => 'rw', isa => 'Net::Jenkins::Job' );

has api => ( is => 'rw' , isa => 'Net::Jenkins' );

method details {
    return $self->api->get_build_details( $self->job->name, $self->number );
}

method result {
    return $self->details->{result};
}

method building {
    return $self->details->{building};
}

method id {
    return $self->details->{id};
}

method name {
    return $self->details->{fullDisplayName};
}

method created_at {
    return DateTime->from_epoch( epoch => $self->details->{timestamp} );
}

method console {
    return $self->api->get_build_console( $self->job->name, $self->number );
}

method console_handle {
    return $self->api->get_build_console_handle( $self->job->name , $self->number );
}

method to_hashref ($with_details) {
    return {
        number => $self->number,
        url => $self->url,
        job => $self->job->to_hashref,
        ($with_details ? 
            ( details => $self->details ) : () ),
    };
}

1;
__END__
=head1 NAME

Net::Jenkins::Job::Build

=head1 ATTRIBUTES

=head2 number

[Int] The build number

=head2 url

[Str] The build page url

=head2 job

[L<Net::Jenkins::Job>] The Job object 

=head2 api

[L<Net::Jenkins>] The API object 

=head1 METHODS

=head2 details

[HashRef] Get details 

=head2 name

[Str] Job name

=head2 id

[Int] Job ID

=head2 created_at

[DateTime] created at 

=head2 console

[Str] Console Output Content

=head2 console_handle

Console FH

=head2 building

[Bool] is this build is building ?

=head2 result

[Str] Build result.

=cut
