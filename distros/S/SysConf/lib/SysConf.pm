package SysConf;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Carp;
use Switch;

use constant true   => (1==1);
use constant false  => (1==0);

my (%rc,%_mount);


=head1 NAME

SysConf - Create/Read/Update files in CentOS and Red Hat sysconfig directory

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';


=head1 SYNOPSIS



    use SysConf;

    my $sysconf_file   = 'name_of_file';
    my $sysconf_path   = '/etc/sysconfig';
    my $foo = SysConf->new({'file' => $sysconf_file ,'path' => $sysconf_path});
    
    # attach the object to the file
    $foo->attach;
    
    # get a list of all keys in the file (ignore commented ones)
    my @k = $foo->keys;
    
    # set a particular key to a particular value (will insert the key if needed)
    $foo->update('bar'=>1);
    
    # get a particular value given a key
    my $val = $foo->retrieve('oof');
    
    # delete a key/value pair
    my $rv = $foo->delete('bar');
    
    # detach the object from the file
    $foo->detach;
    
    ...


=head1 SUBROUTINES/METHODS

=cut

sub new {
            my $this = shift;
            my $args = shift;
            my $class = ref($this) || $this;
            my $self = {};
            bless $self, $class;
            if ($args) {
                foreach my $arg (keys %{$args}) {
                    switch ($arg) {
                        case "path"     { $self->path($args->{$arg})}
                        case "file"     { $self->file($args->{$arg})}
                        case "debug"    { $self->debug($args->{$arg})}
                        else            { $self->{'_'.$arg}= $args->{$arg}}
                    }
                }
            }
            return $self;
    }

=head2 
    path	set or get the path in the file system where the file resides
=cut

sub path {
    my $self = shift;
    if(@_) { $self->{path} = $_[0]; }
    return $self->{path};
}

=head2 file
    file	set or get the name of the file
=cut

sub file {
    my $self = shift;
    if(@_) { $self->{file} = $_[0]; }
    return $self->{file};
}

=head2 debug
    debug	set or get the debugging switch
=cut

sub debug {
    my $self = shift;
    if(@_) { $self->{debug} = $_[0]; }
    return $self->{debug};
}

    
=head2 new

    new 	Create an instance of this object.  You may
		initialize class variables with an anonymous hash

=cut

sub keys {
    my $self = shift;
    return keys %{$self->{'_conf'}};
}

=head2 keys

    keys        return a list of keys stored in the file

=cut

sub attach {
    use File::Spec;
    my $self = shift;
    my %rc;
    my $full_path   = File::Spec->catfile($self->path,$self->file);
    
    if (!-e $full_path) {
        printf STDERR "D[%i] touching file = %s\n",$$,$full_path if ($self->debug);
        open(my $fh, ">".$full_path) or die "FATAL ERROR: unable to open file = $full_path\n";
        printf $fh '# this file intentionally left blank'."\n";
        close($fh);
    }
    die   "File $full_path not found" if (!-e $full_path);
    die   "File $full_path not readable" if (!-r $full_path);
    carp  "File $full_path not writable" if (!-w $full_path);
    $self->_read;
    $self->{'attached'}=true;
    return true;
}

sub _read {
    use Data::Dumper;
    my $self = shift;
    my $file = File::Spec->catfile($self->path,$self->file);
    open(my $fh, "<".$file) or die "FATAL ERROR: unable to open file = $file\n";
    my (@lines,$line,$count);
    $count=0;
    while ($line = <$fh>) {
        if ($line =~ /^\s{0,}(\S+)\s{0,}=\s{0,}(.*?)\s\#{0,}.*/) {
            $self->{'_conf'}->{$1} = $2;
            $count++;
        }
    }
    
    close($fh);
    return $count;
}

=head2 attach

=cut


sub detach {
    my $self = shift;
    my $file   = File::Spec->catfile($self->path,$self->file);
    $self->_write;
    delete $self->{'_conf'};
    $self->{'attached'}=false;
    return true;
}

sub _write {
    my $self = shift;
    my $file   = File::Spec->catfile($self->path,$self->file);
    open(my $fh, ">".$file) or die "FATAL ERROR: unable to open file = $file\n";
    while (my ($k,$v) = each %{$self->{'_conf'}}) {
        printf $fh "%s=%s\n",$k,$v;
    }
    close($fh);
}

=head2 detach

=cut

sub retrieve {
    use Data::Dumper;
    my $self = shift;
    my $k    = shift;
    return undef if (!$self->{'attached'});
    
    printf STDERR "D[%i] key = %s\n",$$,$k if ($self->debug);
    
    if (defined($self->{'_conf'}))
       {
        my %h =     %{$self->{'_conf'}};
        my $v;
        $v = $h{$k} if (defined($h{$k}));
        printf STDERR "D[%i] val = %s\n",$$,( defined($v) ? $v : "undef") if ($self->debug);
        return $v;
       }
      else
       { return undef }
}

=head2 retrieve

=cut


sub update {
    my $self    = shift;
    my $kvp     = shift;
    return undef if (!$self->{'attached'});
    my ($k,$v);    
    while (($k,$v) = each %{$kvp}) { $self->{'_conf'}->{$k} = $v; }            
    $self->_write;
}

=head2 update

=cut

sub delete {
    my $self = shift;
    my $k    = shift;
    if (defined($self->{'conf'}))
       {
        if (defined($self->{'_conf'}->{$k}))
           {
            delete $self->{'_conf'}->{$k};
            return true;
           }
          else
           { return false ;}
       }
      else
       { return undef }
}

=head2 delete

=cut


=head1 AUTHOR

Joe Landman, C<< <landman at scalableinformatics.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sysconf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SysConf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SysConf


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SysConf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SysConf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SysConf>

=item * Search CPAN

L<http://search.cpan.org/dist/SysConf/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Scalable Informatics.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of SysConf
