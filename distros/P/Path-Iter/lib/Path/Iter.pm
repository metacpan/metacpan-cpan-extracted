package Path::Iter;

use strict;
use warnings;
use File::Spec ();

$Path::Iter::VERSION = 0.2;

sub get_iterator {
    my @queue = @_;

    my %args = ();
    if (ref $queue[-1] eq 'HASH') {
        %args = (%args, %{ pop @queue });
    }

    @{ $args{'errors'} }  = (); # empty an existing one
    %{ $args{'initial'} } = (); # empty an existing one
    
    for my $queue_item (@queue) {
        $queue_item = File::Spec->catdir($queue_item); # File::Spec version of =~ s{/+$}{};
        $args{'initial'}{$queue_item} = 1;
    }

    return sub {
        return if !@queue;

        my $path = shift @queue;       
        $path = File::Spec->catdir($path); # File::Spec version of =~ s{/+$}{};

        # make it possible to handle symlinks how they want/need
        # return $path if -l $path; 
        if (-l $path) {
             if (ref $args{'symlink_handler'} eq 'CODE') {
                 my $is_initial = exists $args{'initial'}->{$path} ? 1 : 0;
                 my ($symlink_traverse) = $args{'symlink_handler'}->($path, $is_initial);
        
                 if (defined $symlink_traverse && $symlink_traverse) {
                     if ($symlink_traverse == 2) {
                         delete $args{'initial'}->{$path} if $is_initial;
                         $path = readlink($path);
                         $path = File::Spec->catdir($path); # File::Spec version of =~ s{/+$}{};
                         $args{'initial'}->{$path}++ if $is_initial;
                     }
                 }
                 else {
                     return $path;
                 }
             }
             else {
                 return $path;
             }
        }

        if (-d $path) {
            if (opendir DIR, $path) {
                my @dir_contents = grep { $_ ne '.' && $_ ne '..' } readdir DIR;
                closedir DIR;
                
                if (@dir_contents) {
                    if (ref $args{'readdir_handler'} eq 'CODE') {
                        push @queue, $args{'readdir_handler'}->( $path, map { File::Spec->catdir($path,$_) } @dir_contents);
                    }
                    else {
                        push @queue, map { File::Spec->catdir($path,$_) } @dir_contents;
                    }
                }
            }  
            else {
                push @{$args{'errors'}}, {
                    'path'     => $path,
                    'function' => 'opendir',
                    'args'     => [\*DIR, $path],
                    'errno'    => int($!), 
                    'error'    => int($!) . ": $!", 
                };
                return if $args{'stop_when_opendir_fails'};
            }
        }
        
        return $path;
    }
}

1;