package Nginx::Simple::Dispatcher;

use base qw(
    Exporter
    Nginx::Simple::Dispatcher::Attributes
);

use strict;

our @EXPORT = qw(dig_for_dispatch);

# keep a list of dispatched paths
my %path_cache;

=head1 NAME 

Nginx::Simple::Dispatcher

=head1 Synopsis

Automatic dispatcher built on code attributes.

=head1 Methods

=cut

sub dig_for_dispatch
{
    my ($self, %params) = @_;
    my $class       = $params{class};
    my $path        = $params{path};
    my $called_path = $path || $params{called_path}; # the complete path

    # reset self
    $self = $params{self} if $params{self};

    # dereference class
    $class    = ref $class ? ref $class : $class;

    # sanitize path
    {
        # remove starting slash
        $path =~ s/^\///;

        # remove trailing slash
        $path =~ s/\/+$//;

        # remove index trailing (you can't call index directly)
        $path =~ s/(\/|^)index$//;

        # append 'index' if no path given
        $path .= 'index' unless $path;
    }

    # check cache (for fast dispatches)
    return $path_cache{$called_path}
        if $path_cache{$called_path};

    # build list of paths
    my @paths = split('/', $path);

    # build method call
    my $call_class   = $class;
    my $method       = pop @paths;
    my $remote_class = $class;
       $remote_class = join('::', $class, join('::', @paths))
           if @paths;

    &_class_is_imported($remote_class) if $params{auto_import};

    if (UNIVERSAL::can($remote_class, 'get_dispatch_flags'))
    {
        my $methods    = $remote_class->get_dispatch_flags;
        my $used_index = 0;

        # if this is a page index, find the index sub name
        if ($method eq 'index')
        {
            ($method) = grep { $methods->{$_} eq 'index' } keys %$methods;
            $used_index = 1;
        }

        if ($methods->{$method})
        {
            # perform dispatch
            {
                no strict 'refs'; # evil
                my $subptr = join('::', $remote_class, $method);

                # store path in cache
                $path_cache{$called_path} = {
                    class  => $remote_class,
                    method => $method,
                    sub    => \&$subptr,
                    index  => $used_index,
                };

                return $path_cache{$called_path};
            }
        }
        else
        {
            my $jump_class = join('::', $remote_class, $method);

            &_class_is_imported($jump_class) if $params{auto_import};

            if (UNIVERSAL::can($jump_class, 'get_dispatch_flags'))
            {
                return $jump_class->dig_for_dispatch(
                    self        => $self,
                    class       => $jump_class,
                    path        => '',
                    called_path => $called_path,
                );
            }

            return { error => 'bad_dispatch' };
        }
    }
    else # get_dispatch_flags is not assessable
    {
        return { error => 'bad_dispatch' };
    }
}

# _class_is_imported(Some::Class)
#
# If a class is not imported, import it.
#

sub _class_is_imported
{
    my $class = shift;

    (my $class_file = $class) =~ s{::}{/}g;
    $class_file .= '.pm'; # Let's assume all class files end in .pm

    if (not exists $INC{$class_file})
    {
        for my $base_path (@INC)
        {
            my $full_path = join('/', $base_path, $class_file);
            
            if (-e $full_path)
            {
                eval qq{use $class;};
                warn "-->$@<--" if $@;
                return;
            }
        }        
    }
}

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;

