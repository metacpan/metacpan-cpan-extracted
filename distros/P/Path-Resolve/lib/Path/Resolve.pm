package Path::Resolve;
use warnings;
use strict;
use Carp;
use Data::Dumper;

our $VERSION = '0.0.2';

my $isWindows = $^O eq 'MSWin32';

if ($isWindows) {
    eval "use base 'Path::Resolve::Win'";
    *splitPath = *Path::Resolve::Win::splitPath;
} else {
    eval "use base 'Path::Resolve::POSIX'";
    *splitPath = *Path::Resolve::POSIX::splitPath;
}

sub new {
    bless {}, __PACKAGE__;
}

sub dirname {
    my ($self,$path) = @_;
    my @result = splitPath($path);
    my $root = $result[0],
    my $dir = $result[1];
    if (!$root && !$dir) {
        #No dirname whatsoever
        return '.';
    }
    if ($dir) {
        #It has a dirname, strip trailing slash
        $dir = substr $dir,0, length($dir) - 1;
    }
    return $root . $dir;
}

sub extname {
    my ($self,$path) = @_;
    return (splitPath($path))[3];
}

sub basename {
    my ($self, $path, $ext) = @_;
    my $f = (splitPath($path))[2];
    #TODO: make this comparison case-insensitive on windows?
    if ($ext && (substr $f, -1 * length $ext) eq $ext) {
        $f = substr $f, 0, length($f) - length($ext);
    }
    return $f;
}

package
    Path::Resolve::Win; {
    use Carp;
    use strict;
    use warnings;
    use Cwd();
    use Data::Dumper;

    my $splitDeviceRe =   qr/^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/;
    my $splitTailRe   =   qr/^([\s\S]*?)((?:\.{1,2}|[^\\\/]+?|)(\.[^.\/\\]*|))(?:[\\\/]*)$/;
    my $CWD = Cwd::cwd();

    sub sep {'\\'};
    sub delimiter {';'};

    sub splitPath {
        my ($filename) = @_;
        my @result = Path::Resolve::Utils::exec($splitDeviceRe,$filename);
        my $device = ($result[1] || '') . ($result[2] || '');
        my $tail = $result[3] || '';
        #Split the tail into dir, basename and extension
        my @result2 = Path::Resolve::Utils::exec($splitTailRe,$tail);
        my $dir = $result2[1];
        my $basename = $result2[2];
        my $ext = $result2[3];
        return ($device, $dir, $basename, $ext);
    }

    sub parse {
        my ($self, $path) = @_;
        if (!$path || ref $path){
            croak("Parameter 'pathString' must be a string");
        }

        my @allParts = splitPath($path);
        
        if (!@allParts || scalar @allParts != 4) {
            croak("Invalid path '" . $path . "'");
        }

        return {
            root => $allParts[0],
            dir  => $allParts[0] . substr ($allParts[1], 0, -1),
            base => $allParts[2],
            ext  => $allParts[3],
            name => substr ($allParts[2], 0, length($allParts[2]) - length($allParts[3]))
        };
    }

    sub format {
        my ($self, $pathObject) = @_;
        if ( ref $pathObject ne 'HASH' ) {
            croak "Parameter 'pathObject' must be an Hash Ref";
        }

        my $root = $pathObject->{root} || '';
        if (!defined $root || ref $root) {
            croak 'pathObject->{root} must be a string or undefined';
        }

        my $dir = $pathObject->{dir};
        my $base = $pathObject->{base} || '';
        if (!$dir) {
            return $base;
        }

        my $t = substr $dir, length($dir) - 1,  2;
        if ($t eq $self->sep) {
            return $dir . $base;
        }

        return $dir . $self->sep . $base;
    }

    sub isAbsolute {
        my ($self, $path) = @_;
        my @result = Path::Resolve::Utils::exec($splitDeviceRe,$path);
        my $device = $result[1] || '';
        my $isUnc = $device && $device !~ /^.:/;
        ##UNC paths are always absolute
        return !!$result[2] || $isUnc;
    }

    sub normalizeUNCRoot {
        my $device = shift;
        $device =~ s/^[\\\/]+//;
        $device =~ s/[\\\/]+/\\/g;
        return '\\\\' . $device;
    }

    sub resolve {
        my $self = shift;
        my $resolvedDevice = '';
        my $resolvedTail = '';
        my $resolvedAbsolute = 0;
        my $isUnc;
        my @args = @_;
        for (my $i = (scalar @args) - 1; $i >= -1; $i--) {
            my $path;
            if ($i >= 0) {
                $path = $_[$i];
            } elsif (!$resolvedDevice) {
                $path = $CWD;
            } else {
                ##TODO
            }
            
            ## skip empty paths
            if (!$path) {
                next;
            }
            
            my @result = Path::Resolve::Utils::exec($splitDeviceRe,$path);
            my $device = $result[1] || '';
            $isUnc = $device && $device !~ /^.:/;
            my $isAbsolute = $self->isAbsolute($path);
            my $tail = $result[3];
            if ($device &&
                $resolvedDevice &&
                ( lc $device ne lc $resolvedDevice ) ) {
                #This path points to another device so it is not applicable
                next;
            }
            
            if (!$resolvedDevice) {
                $resolvedDevice = $device;
            }
            if (!$resolvedAbsolute) {
                $resolvedTail = $tail . '\\' . $resolvedTail;
                $resolvedAbsolute = $isAbsolute;
            }
            if ($resolvedDevice && $resolvedAbsolute) {
                last;
            }
        }
        
        #Convert slashes to backslashes when `resolvedDevice` points to an UNC
        #root. Also squash multiple slashes into a single one where appropriate.
        if ($isUnc) {
            $resolvedDevice = normalizeUNCRoot($resolvedDevice);
        }
        
        my @resolvedTail = grep {$_ if $_} split /[\\\/]+/, $resolvedTail;
        @resolvedTail = Path::Resolve::Utils::normalizeArray(\@resolvedTail,!$resolvedAbsolute);
        $resolvedTail = join '\\',@resolvedTail;
        my $ret = ($resolvedDevice . ($resolvedAbsolute ? '\\' : '') . $resolvedTail) || '.';
        return $ret;
    }

    sub normalize {
        my ($self, $path) = @_;
        my @result = Path::Resolve::Utils::exec($splitDeviceRe,$path);
        my $device = $result[1] || '';
        my @device = split '',$device;
        my $isUnc = @device && $device[1] ne ':';
        my $isAbsolute = !!$result[2] || $isUnc;
        my $tail = $result[3];
        my $trailingSlash = $tail =~ /[\\\/]$/;
        #If device is a drive letter, we'll normalize to lower case.
        if (@device && $device[1] eq ':') {
            $device = lc $device;
        }
        
        my @tail = grep {$_ if $_} split /[\\\/]+/, $tail;
        @tail = Path::Resolve::Utils::normalizeArray(\@tail,!$isAbsolute);
        $tail = join '\\', @tail;
        if (!$tail && !$isAbsolute) {
            $tail = '.';
        }
        if ($tail && $trailingSlash) {
            $tail .= '\\';
        }
        #Convert slashes to backslashes when `device` points to an UNC root.
        #Also squash multiple slashes into a single one where appropriate.
        if ($isUnc) {
            $device = normalizeUNCRoot($device);
        }
        
        return $device . ($isAbsolute ? '\\' : '') . $tail;
    }

    sub join {
        my $self = shift;
        my @paths = grep {$_ if $_} @_;
        my $joined = join '\\', @paths;
        if ( @paths && $paths[0] !~ /^[\\\/]{2}[^\\\/]/ ) {
            $joined =~ s/^[\\\/]{2,}/\\/;
        }
        return $self->normalize($joined);
    }

    sub _trim {
        my @arr = @_;
        my $start = 0;
        foreach my $a (@arr) {
            last if ($a ne '');
            $start++;
        }
        my $end = scalar @arr - 1;
        while ($end >= 0) {
            last if ($arr[$end] ne '');
            $end--;
        }
        return () if ($start > $end);
        return splice @arr,$start, $end - $start + 1;
    }

    sub relative {
        my ($self, $from, $to) = @_;
        $from = $self->resolve($from);
        $to = $self->resolve($to);
        #windows is not case sensitive
        my $lowerFrom = lc $from;
        my $lowerTo = lc $to;
        my @toParts = _trim(split(/\\/, $to));
        my @lowerFromParts = _trim(split(/\\/,$lowerFrom));
        my @lowerToParts = _trim(split(/\\/,$lowerTo));
        my $length = do {
            my $len = scalar @lowerFromParts;
            my $len2 = scalar @lowerToParts;
            $len < $len2 ? $len : $len2;
        };
        
        my $samePartsLength = $length;
        for (my $i = 0; $i < $length; $i++) {
            if ($lowerFromParts[$i] ne $lowerToParts[$i]) {
                $samePartsLength = $i;
                last;
            }
        }
        if ($samePartsLength == 0) {
            return $to;
        }
        
        my @outputParts = ();
        for (my $i = $samePartsLength; $i < scalar @lowerFromParts; $i++) {
            push @outputParts, ('..');
        }
        
        push @outputParts, ( splice(@toParts,$samePartsLength) );
        return CORE::join '\\',@outputParts;
    }
} #end Path::Resolve::Win


package
    Path::Resolve::POSIX; {
    use strict;
    use warnings;
    use Carp;
    use Cwd();
    my $CWD = Cwd::cwd();

    sub sep {'/'};
    sub delimiter {':'};

    #'root' is just a slash, or nothing.
    my $splitPathRe = qr/^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
    sub splitPath {
        my ($filename) = @_;
        my @res = Path::Resolve::Utils::exec($splitPathRe,$filename);
        return splice @res, 1;
    }

    sub parse {
        my ($self, $path) = @_;
        if (!$path || ref $path){
            croak("Parameter 'pathString' must be a string");
        }

        my @allParts = splitPath($path);
        
        if (!@allParts || scalar @allParts != 4) {
            croak("Invalid path '" . $path . "'");
        }
        
        $allParts[1] ||= '';
        $allParts[2] ||= '';
        $allParts[3] ||= '';
        
        return {
            root => $allParts[0],
            dir  => $allParts[0] . substr ($allParts[1], 0, -1),
            base => $allParts[2],
            ext  => $allParts[3],
            name => substr ($allParts[2], 0, length($allParts[2]) - length($allParts[3]))
        };
    }

    sub format {
        my ($self, $pathObject) = @_;
        if ( ref $pathObject ne 'HASH' ) {
            croak "Parameter 'pathObject' must be an Hash Ref";
        }

        my $root = $pathObject->{root} || '';
        if (!defined $root || ref $root) {
            croak 'pathObject->{root} must be a string or undefined';
        }

        my $dir = $pathObject->{dir} ? $pathObject->{dir} . $self->sep : '';
        my $base = $pathObject->{base} || '';
        return $dir . $base;
    }

    sub resolve {
        my $self = shift;
        my $resolvedPath = '';
        my $resolvedAbsolute = 0;
        my @args = @_;
        for (my $i = (scalar @args) - 1; $i >= -1 && !$resolvedAbsolute; $i--) {
            my $path = ($i >= 0) ? $args[$i] : $CWD;
            #Skip empty and invalid entries
            if (!$path) {
                next;
            }
            $resolvedPath = $path . '/' . $resolvedPath;
            $resolvedAbsolute = $path =~ m/^\//;
        }
        
        #At this point the path should be resolved to a full absolute path, but
        #handle relative paths to be safe (might happen when process.cwd() fails)
        #Normalize the path
        my @resolved = grep { $_ if $_ } split '/', $resolvedPath;
        $resolvedPath = join '/', Path::Resolve::Utils::normalizeArray(\@resolved, !$resolvedAbsolute);
        return (($resolvedAbsolute ? '/' : '') . $resolvedPath) || '.';
    }

    sub isAbsolute {
        my ($self, $path) = @_;
        return $path =~ /^\//;
    }

    sub normalize {
        my ($self, $path) = @_;
        my $isAbsolute = $self->isAbsolute($path);
        my $trailingSlash = (substr $path, -1) eq '/';
        #Normalize the path
        my @resolved = grep { $_ if $_ } split '/', $path;
        $path = join '/', Path::Resolve::Utils::normalizeArray(\@resolved, !$isAbsolute);
        if (!$path && !$isAbsolute) {
            $path = '.';
        }
        if ($path && $trailingSlash) {
            $path .= '/';
        }
        return ($isAbsolute ? '/' : '') . $path;
    }

    sub join {
        my $self = shift;
        my @paths = @_;
        my @norm = grep {$_ if $_} @paths;
        return $self->normalize( join('/', @norm) );
    }

    sub _trim {
        my @arr = @_;
        my $start = 0;
        foreach my $a (@arr) {
            last if ($a ne '');
            $start++;
        }
        my $end = scalar @arr - 1;
        while ($end >= 0) {
            last if ($arr[$end] ne '');
            $end--;
        }
        return () if ($start > $end);
        return splice @arr,$start, $end - $start + 1;
    }

    sub relative {
        my ($self, $from, $to) = @_;
        $from = substr resolve($self,$from),1;
        $to = substr resolve($self,$to),1;
        my @fromParts = _trim( split('/',$from) );
        my @toParts = _trim( split('/',$to) );   
        my $length = do {
            my $len = scalar @fromParts;
            my $len2 = scalar @toParts;
            $len < $len2 ? $len : $len2;
        };
        
        my $samePartsLength = $length;
        for (my $i = 0; $i < $length; $i++) {
            if ($fromParts[$i] ne $toParts[$i]) {
                $samePartsLength = $i;
                last;
            }
        }
        
        my @outputParts = ();
        for (my $i = $samePartsLength; $i < scalar @fromParts; $i++) {
            push @outputParts, ('..');
        }
        
        push @outputParts, ( splice(@toParts,$samePartsLength) );
        return CORE::join '/',@outputParts;
    }
} #end Path::Resolve::Posix

package 
    Path::Resolve::Utils; {
    use strict;
    use warnings;

    #==========================================================================
    # javascript like exec function
    # we can do it the perl way but for fun I want to emulate node path module
    # the way it is :)
    #==========================================================================
    sub exec {
        my ($expr,$string) = @_;
        my @m = $string =~ $expr;
        if (@m){
            unshift @m, substr $string,$-[0],$+[0];
        }
        return @m;
    }

    sub normalizeArray {
        my ($parts, $allowAboveRoot) = @_;
        #if the path tries to go above the root, `up` ends up > 0
        my @parts = @{$parts};
        my $up = 0;
        for (my $i = (scalar @parts) - 1; $i >= 0; $i--) {
            my $last = $parts->[$i];
            if ($last eq '.') {
                splice @parts, $i, 1;
            } elsif ($last eq '..') {
                splice @parts, $i, 1;
                $up++;
            } elsif ($up) {
                splice @parts, $i, 1;
                $up--;
            }
        }

        #if the path is allowed to go above the root, restore leading ..s
        if ($allowAboveRoot) {
            while ($up--) {
                unshift @parts, ('..');
            }
        }
        return @parts;
    }
} # end Path::Resolve::Utils

1;

__END__

=head1 NAME

Path::Resolve - node.js path module in perl

=for html
<a href="https://travis-ci.org/mamod/Path-Resolve"><img src="https://travis-ci.org/mamod/Path-Resolve.svg?branch=master"></a>

=head1 SYNOPSIS

    use Path::Resolve;
    
    my $path = Path::Resolve->new();
    
    my $file = $path->resolve('./r/p/../file.txt');
    my $ext  = $path->extname($file);

=head1 DESCRIPTION

This module behaves exactly like L<node.js path module|https://nodejs.org/api/path.html>, it doesn't check for path validity, 
it only works on strings and has utilities to resolve and normalize path strings.

If you're looking for system specific path module that can create, check, chmod, copy ... etc. then
take a look at L<Path::Tiny>

=head1 METHODS

For a complete documentations about supported methods please check node.js path module
L<api documentation|https://nodejs.org/api/path.html> all methods are supported

=over 4

=item normalize(p)

Normalize a string path, taking care of '..' and '.' parts.

=item join([path1][, path2][, ...])

Join all arguments together and normalize the resulting path.

=item resolve([from ...], to)

Resolves C<to> to an absolute path.

=item isAbsolute(path)

Determines whether path is an absolute path.

=item relative(from, to)

Solve the relative path C<from> from to C<to>. 

=item dirname(p)

Return the directory name of a path. Similar to the Unix C<dirname> command.

=item basename(p[, ext])

Return the last portion of a path. Similar to the Unix C<basename> command. 

=item extname(p)

Return the extension of the path, from the last '.' to end of string in the last portion of the path.

=item sep

he platform-specific file separator. '\\' or '/'.

=item delimiter

The platform-specific path delimiter, ; or ':'.

=item parse(pathString)

Returns a parsed object from a path string.

=item format(pathObject)

Returns a path string from an object, the opposite of C<parse> method above. 

=back

=head1 AUTHOR

Mamod A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself
