# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Text::Subroutine;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;

    exists $args->{name}
        or error __x"no name for subroutine";

    $self->SUPER::init($args)
        or return;

    $self->{OTS_param}    = delete $args->{parameters};
    $self->{OTS_options}  = {};
    $self->{OTS_defaults} = {};
    $self->{OTS_diags}    = [];
    $self;
}

#-------------------------------------------


sub extends($)
{   my $self  = shift;
    @_ or return $self->SUPER::extends;

    my $super = shift;
    if($self->type ne $super->type)
    {   my ($fn1, $ln1) = $self->where;
        my ($fn2, $ln2) = $super->where;
        my ($t1,  $t2 ) = ($self->type, $super->type);

        warning __x"subroutine {name}() extended by different type:\n  {type1} in {file1} line {line1}\n  {type2} in {file2} line {line2}"
          , name => "$self"
          , type1 => $t1, file1 => $fn1, line1 => $ln1
          , type2 => $t2, file2 => $fn2, line2 => $ln2;
    }

    $self->SUPER::extends($super);
}

#-------------------------------------------


sub parameters() {shift->{OTS_param}}

#-------------------------------------------


sub location($)
{   my ($self, $manual) = @_;
    my $container = $self->container;
    my $super     = $self->extends
        or return $container;

    my $superloc  = $super->location;
    my $superpath = $superloc->path;
    my $mypath    = $container->path;

    return $container if $superpath eq $mypath;

    if(length $superpath < length $mypath)
    {   return $container
            if substr($mypath, 0, length($superpath)+1) eq "$superpath/";
    }
    elsif(substr($superpath, 0, length($mypath)+1) eq "$mypath/")
    {   if($superloc->isa("OODoc::Text::Chapter"))
        {   return $self->manual
                        ->chapter($superloc->name);
        }
        elsif($superloc->isa("OODoc::Text::Section"))
        {   return $self->manual
                        ->chapter($superloc->chapter->name)
                        ->section($superloc->name);
        }
        else
        {   return $self->manual
                        ->chapter($superloc->chapter->name)
                        ->section($superloc->section->name)
                        ->subsection($superloc->name);
        }
   }

   unless($manual->inherited($self))
   {   my ($myfn, $myln)       = $self->where;
       my ($superfn, $superln) = $super->where;

       warning __x"subroutine {name}() location conflict:\n  {path1} in {file1} line {line1}\n  {path2} in {file2} line {line2}"
         , name => "$self"
         , path1 => $mypath, file1 => $myfn, line1 => $myln
         , path2 => $superpath, file2 => $superfn, line2 => $superln;
   }

   $container;
}


sub path() { shift->container->path }

#-------------------------------------------


sub default($)
{   my ($self, $it) = @_;
    ref $it
        or return $self->{OTS_defaults}{$it};

    my $name = $it->name;
    $self->{OTS_defaults}{$name} = $it;
    $it;
}

#-------------------------------------------


sub defaults() { values %{shift->{OTS_defaults}} }


sub option($)
{   my ($self, $it) = @_;
    ref $it
        or return $self->{OTS_options}{$it};

    my $name = $it->name;
    $self->{OTS_options}{$name} = $it;
    $it;
}



sub findOption($)
{   my ($self, $name) = @_;
    my $option = $self->option($name);
    return $option if $option;

    my $extends = $self->extends or return;
    $extends->findOption($name);
}


sub options() { values %{shift->{OTS_options}} }


sub diagnostic($)
{   my ($self, $diag) = @_;
    push @{$self->{OTS_diags}}, $diag;
    $diag;
}


sub diagnostics() { @{shift->{OTS_diags}} }


sub collectedOptions(@)
{   my ($self, %args) = @_;
    my @extends   = $self->extends;
    my %options;
    foreach ($self->extends)
    {   my $options = $_->collectedOptions;
        @options{ keys %$options } = values %$options;
    }

    $options{$_->name}[0] = $_ for $self->options;

    foreach my $default ($self->defaults)
    {   my $name = $default->name;

        unless(exists $options{$name})
        {   my ($fn, $ln) = $default->where;
            warning __x"no option {name} for default in {file} line {line}"
              , name => $name, file => $fn, line => $ln;
            next;
        }
        $options{$name}[1] = $default;
    }

    foreach my $option ($self->options)
    {   my $name = $option->name;
        next if defined $options{$name}[1];

        my ($fn, $ln) = $option->where;
        warning __x"no default for option {name} defined in {file} line {line}"
          , name => $name, file => $fn, line => $ln;

        my $default = $options{$name}[1] =
        OODoc::Text::Default->new
          ( name => $name, value => 'undef'
          , subroutine => $self, linenr => $ln
          );

        $self->default($default);
    }

    \%options;
}

1;
