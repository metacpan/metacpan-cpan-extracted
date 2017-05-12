##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4::Header;

use strict;
use warnings;
use vars qw($AUTOLOAD);

use RPM4;
use Digest::SHA1;
use Carp;

sub new {
    my ($class, $arg) = @_;
    
    if ($arg) {
	if (ref $arg eq 'GLOB') {
	    return RPM4::stream2header($arg);
	} elsif (-f $arg) {
	    return RPM4::rpm2header($arg);
	} else {
	    croak("Invalid argument $arg");
	}
    } else {
	return RPM4::headernew();
    }
}

# proxify calls to $header->tag()
sub AUTOLOAD {
    my ($header) = @_;

    my $tag = $AUTOLOAD;
    $tag =~ s/.*:://;
    return $header->tag($tag);
}

sub writesynthesis {
    my ($header, $handle, $filestoprovides) = @_;
    $handle ||= *STDOUT;
   
    my $sinfo = $header->synthesisinfo($filestoprovides);
    
    foreach my $deptag (qw(provide conflict obsolete require)) {
        printf($handle '@%ss@%s'."\n", 
            $deptag, 
            join('@', @{$sinfo->{$deptag}})) if (@{$sinfo->{$deptag} || []});
    }
    
    printf($handle '@summary@%s'. "\n",
        $sinfo->{summary},
    );
    printf($handle '@info@%s@%d@%d@%s'."\n",
        $sinfo->{fullname},
        $sinfo->{epoch},
        $sinfo->{size},
        $sinfo->{group},
    );
    return 1;
}

sub synthesisinfo {
    my ($header, $filestoprovides) = @_;
    my $synthinfo = {
        fullname => scalar($header->fullname()),
        summary => $header->tag(1004),
        epoch => $header->tag(1003) || 0,
        size => $header->tag(1009),
        group => $header->tag(1016),
        os => $header->tag('OS'),
        hdrid => pack("H*",$header->tag('HDRID')),
    };


    my @pkgfiles;
    if (my $files = $header->files()) {
        $files->init();
        while($files->next() >= 0) {
            my $f = $files->filename();
            foreach(@{$filestoprovides}) {
                $_ eq $f and do {
                    push @pkgfiles, "$f";
                    last;
                };
            }
        }
    }
    foreach my $deptag (qw(provide conflict obsolete require)) {
        my @deps;
        $deptag eq 'provide' and push(@deps, @pkgfiles);
        if (my $dep = $header->dep(uc($deptag . "name")) || undef) {
            $dep->init();
            while ($dep->next() >= 0) {
                ($dep->flags() & (1 << 24)) and next;
                my @d = $dep->info();
                #$d[1] =~ /^rpmlib\(\S*\)$/ and next;
                push(@deps, sprintf(
                        "%s%s%s",
                        "$d[1]",
                        ($dep->flags() & RPM4::flagvalue('sense', [ 'PREREQ' ])) ? '[*]' : '',
                        $d[2] ? '[' . ($d[2] eq '=' ? '==' : $d[2]) . " $d[3]\]" : '' ));
             }
        }
        
        { my %uniq; @uniq{@deps} = (); @deps = keys(%uniq); }
        push(@{$synthinfo->{$deptag}}, @deps) if(@deps);
    }

    $synthinfo;
}

# return an array of required files
sub requiredfiles {
    my ($header) = @_;
    grep { m:^/: } $header->tag(1049);
}

# is this usefull
# @keeptags can/should be reworks
sub buildlight {
    my ($header, $hinfo) = @_;
    
    {
    my @n = $hinfo->{fullname} =~ m/^(.*)-([^-]*)-([^-]*)\.([^.]*)/;

    $header->addtag(1000, 6, $n[0]); # Name
    $header->addtag(1001, 6, $n[1]); # Version
    $header->addtag(1002, 6, $n[2]); # Release
    if ($n[3] eq 'src') {
        $header->addtag(1022, 6, RPM4::getarchname()); # Arch
    } else {
        $header->addtag(1022, 6, $n[3]);
        $header->addtag(1044, 6, "RPM4-Fake-1-1mdk.src.rpm");    
    }
    }
    $header->addtag(1004, 6, $hinfo->{summary});
    $header->addtag(1003, 4, $hinfo->{epoch}) if ($hinfo->{epoch});
    $header->addtag(1009, 4, $hinfo->{size});
    $header->addtag(1016, 6, $hinfo->{group});
    $header->addtag("OS", 6, $hinfo->{os} ? $hinfo->{os} : RPM4::getosname());

    foreach my $dep (qw(provide require conflict obsolete)) {
        my $deptag = $dep; $deptag = uc($deptag);
        foreach my $entry (@{$hinfo->{$dep} || []}) {
            my ($name, $pre, $fl, $version) = $entry =~ m/([^\[]*)(\[\*\])?(?:\[(\S*)(?:\s*(\S*))?\])?/;
            $fl ||= '';
            $dep eq 'provide' && substr($name, 0, 1) eq '/'  and do {
                $header->addtag('OLDFILENAMES', 8, $name);
                next;
            };
            #print "$deptag . 'NAME', 8, $name\n";
            $header->addtag($deptag . 'NAME', 8, $name);
            $header->addtag($deptag . 'FLAGS', 'INT32', RPM4::flagvalue("sense", $fl || "") | ($pre ? RPM4::flagvalue("sense", [ 'PREREQ' ]) : 0));
            $header->addtag($deptag . 'VERSION', 8, $version || "");
        }
    }
   
    if (!$hinfo->{hdrid}) {
        my $sha = Digest::SHA1->new;

        foreach my $tag ($header->listtag()) {
            $sha->add(join('', $header->tag($tag)));
        }

        $hinfo->{hdrid} = $sha->digest;
    }
    
    $header->addtag("HDRID", "BIN", $hinfo->{hdrid});
}

sub getlight {
    my ($header, $reqfiles) = @_;
    my $hi = RPM4::headernew();
    $hi->buildlight($header->synthesisinfo($reqfiles));
    $hi
}

sub osscore {
    my ($header) = @_;
    my $os = $header->tag("OS");
    defined $os ? RPM4::osscore($os) : 1;
}

sub archscore {
    my ($header) = @_;
    $header->issrc and return 0;
    my $arch = $header->tag("ARCH");
    defined($arch) ? RPM4::archscore($arch) : 1;
}
    
sub is_better_than {
    my ($header, $h) = @_;

    if ($header->tag(1000) eq $h->tag(1000)) {
        my $c = $header->compare($h);
        $c != 0 and return $c;
        return 1 if $header->osscore < $h->osscore;
        return 1 if $header->archscore < $h->archscore;
    } elsif (my $obs = $header->dep('OBSOLETENAME')) {
        $obs->init();
        while ($obs->next >= 0) {
            $obs->name eq $h->tag(1000) or next;
            return 1 if ($obs->matchheadername($h));
        }
    }
    0;
}

sub sourcerpmname {
    $_[0]->queryformat('%|SOURCERPM?{%{SOURCERPM}}:{%{NAME}-%{VERSION}-%{RELEASE}.src.rpm}|')
}

1;

__END__

=head1 NAME

RPM4::Header

=head1 DESCRIPTION

The header contains informations about a rpms, this object give methods
to manipulate its.

=head1 METHODS

=head2 RPM4::Header->new($item)

Create a new C<RPM4::Header> instance from:

=over 4

=item a file

if $item is an rpm file, returns the corresponding object.

=item a file handler

if $item is a file handler, returns an object corresponding to the next header there.

=item nothing

if $item is omitted, returns an empty object.

=back

If data are unreadable for whatever reason, returns undef.

=head2 write(*FILE)

Dump header data into file handle.

Warning: Perl modifier (like PerlIO::Gzip) won't works.

=head2 hsize()

Returns the on-disk size of header data, in bytes.

=head2 copy()

Returns a RPM4::Header object copy.

=head2 removetag(tagid)

Remove tag 'tagid' from header.

=head2 addtag(tagid, tagtype, value1, value2...)

Add a tag into the header:
- tagid is the integervalue of tag
- tagtype is an integer, it identify the tag type to add (see rpmlib headers 
files). Other argument are value to put in tag.

=head2 listtag()

Returns a list of tag id present in header.

=head2 hastag(tagid)

Returns true if tag 'tagid' is present in header.

Ex:
    $header->hastag(1000); # Returns true if tag 'NAME' is present.

=head2 tagtype(tagid)

Returns the tagtype value of tagid. Returns 0 if tagid is not found.

=head2 tag(tagid)

Returns array of tag value for tag 'tagid'.

    $header->tag(1000); # return the name of rpm header.

=head2 queryformat($query)

Make a formated query on the header, macros in I<$query> are evaluated.
This function works like C<rpm --queryformat ...>

    $header->queryformat("%{NAME}-%{VERSION}-%{RELEASE}");

=head2 fullname

In scalar context return the "name-version-version.arch" of package.
In array context return (name, version, release, arch) of package.

=head2 issrc()

Returns true if package is a source package.

=head2 compare(header)

Compare the header to another, return 1 if the object is higher, -1 if
header passed as argument is better, 0 if update is not possible.

=head2 dep($deptype)

Return a RPM4::Header::Dependencies object containing dependencies of type
$deptype found in the header.

=head2 files()

Return a RPM4::Header::Files object containing the set of files include in
the rpm.

=head1 SEE ALSO

L<RPM4>
