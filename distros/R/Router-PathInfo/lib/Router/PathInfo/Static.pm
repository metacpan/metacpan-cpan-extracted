package Router::PathInfo::Static;
use strict;
use warnings;

=head1 NAME

B<Router::PathInfo::Static> - static routing

=head1 DESCRIPTION

Class to describe the routing of statics.
Allows us to describe the statics as follows:

- Specify the starting segment of the URI

- Specify a directory on disk, which will host the search for static

Statics is divided into two parts:

- C<allready> - already exists (the "classic") static

- C<on_demand> - created on demand

Case C<allready> it's different css, js, images. C<on_demand> it's archives and another.
If the file to C<on_demand> not found, C<match> return undef - a signal that makes sense to continue search of L<Router::PathInfo::Controller> routing.

If successful, returns hashref:

    {
        type => 'static',
        mime_type => $mime_type,
        file_name => '/path/to/found.static',
    };
    
This ensures that the file exists, has size, and is readable.


If static is not found (for C<allready>) an error is returned:

    {
        type  => 'error',
        code => 404,
        desc  => sprintf('not found static for PATH_INFO = %s', $env->{PATH_INFO})
    }

If PATH_INFO contains illegal characters (such as C</../> or C</.file>)an error is returned:

    {
        type  => 'error',
        code => 403,
        desc  => sprintf('forbidden for PATH_INFO = %s', $env->{PATH_INFO})   
    }

Return C<undef> means that it makes sense to continue search of L<Router::PathInfo::Controller> routing.  

=head1 SYNOPSIS
    
    my $s = Router::PathInfo::Static->new(
            # describe simple static 
            allready => {
                path => $allready_path,
                first_uri_segment => 'static'
            },
            # describe on demand created static
            on_demand => {
                path => $on_demand_path,
                first_uri_segment => 'archives',
            }
    );
    
    my $env = {PATH_INFO => '/static/some.jpg'};
    my @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };

    my $res = $s->match($env);
    
    # $res = {
    #     type  => 'static',
    #     file  => $path_to_some_jpg,
    #     mime  => 'image/jpeg'
    # }

=head1 METHODS

=cut

use namespace::autoclean;
use Plack::MIME;
use File::Spec;
use File::MimeInfo::Magic qw(mimetype);

=head2 new(allready => {path => $dir, first_uri_segment => $uri_segment}, on_demand => {...})

The constructor accepts the description of the statics (allready) and/or static generated on demand (on_demand).
Each description is a hashref with the keys C<'path'> (directory path)
and C<'first_uri_segment'> (the first segment of a PATH_INFO, which defines namespace for designated purposes).    

All arguments are optional. If no arguments are given, the object is not created.

=cut
sub new {
	my $class = shift;
	my %param = @_;
	
	my $hash = {};
	
	for (qw(allready on_demand)) {
		my $token = delete $param{$_};
		if (ref $token) {
	        if (-e $token->{path} and -d _ and $token->{first_uri_segment}) {
	            $hash->{$_.'_path'}        = $token->{path};
	            $hash->{$_.'_uri_segment'} = $token->{first_uri_segment};
	            $hash->{$_}                = 1;
	        } else {
	            $hash->{$_}                = 0;
	        }
		}
	}

	return keys %$hash ? bless($hash, $class) : undef;
}

sub _type_uri {
    my $self          = shift;
    my $first_segment = shift;
    
    for (qw(allready on_demand)) {
    	return $_ if ($self->{$_} and $first_segment eq $self->{$_.'_uri_segment'});
    }
    
    return;
}

=head2 match({'psgix.tmp.RouterPathInfo' => {...}})

Objects method. 
Receives a uri and return:

For C<on_demand> created static, return undef if file not found.

=cut
sub match {
    my $self = shift;
    my $env  = shift;
        
    my @segment = @{$env->{'psgix.tmp.RouterPathInfo'}->{segments}};

    my $serch_file = pop @segment;
    return unless ($serch_file and @segment);
    
    # проверим первый сегмент uri на принадлежность к статике
    my $type = $self->_type_uri(shift @segment);
    return unless $type;

    # среди прочего небольшая защита для никсойдов, дабы не отдать секьюрные файлы
    return {
        type  => 'error',
        code => 403,
        desc  => sprintf('forbidden for PATH_INFO = %s', $env->{PATH_INFO})   
    } if ($serch_file =~ /^\./ or $serch_file =~ /~/ or grep {$_ =~ /^\./ or $_ =~ /~/} @segment);

    $serch_file = File::Spec->catfile($self->{$type.'_path'}, @segment, $serch_file);
    if (-f $serch_file and -s _ and -r _) {
        return {
            type  => 'static',
            file  => $serch_file,
            mime  => Plack::MIME->mime_type($serch_file) || mimetype($serch_file)
        }
    } else {
        return $type eq 'allready' ?
            {
                type  => 'error',
                code => 404,
                desc  => sprintf('not found static for PATH_INFO = %s', $env->{PATH_INFO})
            } : 
            undef;
    }
}

=head1 DEPENDENCIES

L<Plack::MIME>, L<File::MimeInfo::Magic>

=head1 SEE ALSO

L<Router::PathInfo>, L<Router::PathInfo::Controller>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut
1;
__END__
