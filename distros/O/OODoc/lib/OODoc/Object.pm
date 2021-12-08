# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Object;
use vars '$VERSION';
$VERSION = '2.02';


use strict;
use warnings;

use Log::Report    'oodoc';


sub new(@)
{   my $class = shift;

    my %args = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   error __xn"unknown option {options}", "unknown options {options}"
           , scalar @missing, options => @missing;
    }

    $self;
}

sub init($)
{   my ($self, $args) = @_;
    $self->{OO_extends} = [];
    $self;
}

#-------------------------------------------


sub extends(;$)
{   my $self = shift;
    my $ext  = $self->{OO_extends};
    push @$ext, @_;

    wantarray ? @$ext : $ext->[0];
}

#-------------------------------------------


sub mkdirhier($)
{   my $thing = shift;
    my @dirs  = File::Spec->splitdir(shift);
    my $path  = $dirs[0] eq '' ? shift @dirs : '.';

    while(@dirs)
    {   $path = File::Spec->catdir($path, shift @dirs);
        -d $path || mkdir $path
            or fault __x"cannot create {dir}", dir => $path;
    }

    $thing;
}


sub filenameToPackage($)
{   my ($thing, $package) = @_;
    $package =~ s!^lib/!!;
    $package =~ s#/#::#g;
    $package =~ s/\.(pm|pod)$//g;
    $package;
}

#-------------------------------------------


my %packages;
my %manuals;

sub addManual($)
{   my ($self, $manual) = @_;

    ref $manual && $manual->isa('OODoc::Manual')
         or panic "manual definition requires manual object";

    push @{$packages{$manual->package}}, $manual;
    $manuals{$manual->name} = $manual;
    $self;
}


sub mainManual($)
{  my ($self, $name) = @_;
   (grep {$_ eq $_->package} $self->manualsForPackage($name))[0];
}


sub manualsForPackage($)
{   my ($self,$name) = @_;
    $name ||= 'doc';
    defined $packages{$name} ? @{$packages{$name}} : ();
}


sub manuals() { values %manuals }


sub manual($) { $manuals{ $_[1] } }


sub packageNames() { keys %packages }

1;
