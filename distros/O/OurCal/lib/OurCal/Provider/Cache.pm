package OurCal::Provider::Cache;

use strict;
use File::Spec::Functions qw(catfile rel2abs);
use File::Path;
use Storable;
use OurCal::Provider;

=head1 NAME

OurCal::Provider::Cache - a caching provider 

=head1 SYNOPSIS

    [a_cache]
    type  = cache
    dir   = .cache
    child = a_provider

=head1 CONFIG OPTIONS

=over 4

=item dir

The directory to cache into. Defaults to '.cache'

=item child

An optional child to cache stuff from. This will instantiate the 
provider and feed stuff through to it, caching appropriately.

=item cache_expiry

How long to cache for in seconds. Defaults to 1800 (30 mins).

=back

=head1 METHODS

=cut

=head2 new <param[s]>

Requires an C<OurCal::Config> object as config param and a name param.

=cut

sub new {
    my $class = shift;
    my %what  = @_;
    my $conf  = $what{config}->config($what{name});
    if (defined $conf->{child}) {
        $what{_provider}      = OurCal::Provider->load_provider($conf->{child}, $what{config}); 
            $what{_provider_name} = $conf->{child}; 
    }
    $what{_cache_dir}     = $conf->{dir} || '.cache';
    $what{_cache_expiry}  = $conf->{cache_expiry} || 60 * 30;
    return bless \%what, $class;
}


sub todos {
    my $self = shift;
    return $self->_do_cached('todos', @_);
}

sub has_events {
    my $self = shift;
    return ($self->_do_cached('has_events', @_))[0];
}

sub events {
    my $self   = shift;
    my %opts   = @_;
    my @events = $self->_do_cached('events', %opts);
    @events    = splice @events, 0, $opts{limit} if defined $opts{limit};
    return @events;
}

sub users {
    my $self = shift;
    return $self->_do_cached('users', @_);
}

sub save_todo {
    my $self = shift;
    return $self->_do_default('save_todo', @_);
}

sub del_todo {
    my $self = shift;
    return $self->_do_default('del_todo', @_);
}


sub save_event {
    my $self = shift;
    return $self->_do_default('save_event', @_);
}

sub del_event {
    my $self = shift;
    return $self->_do_default('del_event', @_);
}

sub _do_cached {
    my $self   = shift;
    my $sub    = shift;
    my $thing  = shift;
    return unless defined $self->{_provider};    
    my $file   = $self->{_provider_name}."+".$sub."@".$self->_flatten_args($thing, @_);
    return $self->cache($file, sub { $self->{_provider}->$sub($thing, @_) });
}


=head2 cache <file> <subroutine>

Retrieve the cache file and returns a list of objects serialised in it.

If the cache has expired then runs the subroutine passed to fetch more 
data.

=cut

# TODO perhaps the caching code should be refactored out into
# ::Cache::Simple and ::Provider::Cache could take an optional
# 'class' parameter. This will do for now though.
sub cache {
    my $self   = shift;
    my $file   = shift;
    my $sub    = shift;
    my $dir    = rel2abs($self->{_cache_dir});
    -d $dir   || eval { mkpath($dir) } || die "Couldn't create cache directory $dir: $@\n";
    my $cache  = catfile($dir, $file);    
    my $expire = $self->{_cache_expiry};
    my $mtime  = (stat($cache))[9]; 
    my $time   = time;
    my @res    = ();
    if (-e $cache && ($time-$mtime < $expire)) {
        @res  = @{Storable::retrieve( $cache )};
    } else {
        @res =  $sub->();
        Storable::store( [@res], $cache );
    }
    return @res;
}

sub _flatten_args {
    my $self = shift;
    my %opts = @_;
    my $flat = "";
    foreach my $key (sort keys %opts) {
        $flat .= "$key=$opts{$key};"
    }
    return $flat;
}

sub _do_default {
    my $self  = shift;
    my $sub   = shift;
    my $thing = shift;
    return unless defined $self->{_provider};    
    return $self->{_provider}->$sub($thing, @_);
}

=head2 todos

Returns all the todos on the system.

=head2 has_events <param[s]>

Returns whether there are events given the params.

=head2 events <param[s]>

Returns all the events for the given params.

=head2 users

Returns the name of all the users on the system.

=head2 save_todo <OurCal::Todo>

Save a todo.

=head2 del_todo <OurCal::Todo>

Delete a todo.


=head2 save_event <OurCal::Event>

Save an event.

=head2 del_event <OurCal::Event>

Delete an event..

=cut


1;

