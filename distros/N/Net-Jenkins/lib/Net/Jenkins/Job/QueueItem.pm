package Net::Jenkins::Job::QueueItem;
use Moose;
use methods;
use Net::Jenkins::Job;

has id  => ( is => 'rw' );

has why  => ( is => 'rw' );

has stuck  => ( is => 'rw' );

has buildable  => ( is => 'rw' );

has inQueueSince  => ( is => 'rw' );

has params  => ( is => 'rw' );

has timestamp  => ( is => 'rw' );

has blocked  => ( is => 'rw' );

has job => ( is => 'rw' );

has _api => ( is => 'rw' , isa => 'Net::Jenkins' );

sub BUILDARGS {
    my ($self,%args) = @_;
    $args{job} = Net::Jenkins::Job->new( %{ $args{task} } , $args{_api} ) if $args{task} && ! $args{job};
    return \%args;
}

sub to_hashref {
    my ($self,$with_details) = @_;
    return {
        id => $self->id,
        why => $self->why,
        stuck => $self->stuck,
        params => $self->params,
        buildable => $self->buildable,
        blocked => $self->blocked,
        timestamp => $self->timestamp,
        inQueueSince => $self->inQueueSince,
    };
}

=pod 

{
    'stuck' => $VAR1->{'concurrentBuild'},
    'buildable' => $VAR1->{'concurrentBuild'},
    'task' => {
                'url' => 'http://localhost:8080/job/Phifty/',
                'name' => 'Phifty'
                },
    'inQueueSince' => '1337737814477',
    'params' => '',
    'timestamp' => '1337737819477',
    'blocked' => $VAR1->{'concurrentBuild'},
    'id' => 35,
    'why' => 'In the quiet period. Expires in 4.9 sec'
},

=cut

1;
