# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Manifest;

use File::Copy;
use File::Spec;
use File::Basename;
use IO::File;
use List::Util 'first';


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args) or return;

    $self->{O_pkg}    = {};

    my $distribution  = $self->{O_distribution} = delete $args->{distribution};
    defined $distribution
        or error __x"the produced distribution needs a project description";

    $self->{O_project} = delete $args->{project} || $distribution;

    my $version        = delete $args->{version};
    unless(defined $version)
    {   my $fn         = -f 'version' ? 'version'
                       : -f 'VERSION' ? 'VERSION'
                       : undef;
        if(defined $fn)
        {   my $v = IO::File->new($fn, 'r')
                or fault __x"cannot read version from file {file}", file=> $fn;
            $version = $v->getline;
            $version = $1 if $version =~ m/(\d+\.[\d\.]+)/;
            chomp $version;
        }
    }

    defined $version
        or error __x"no version specified for distribution '{dist}'"
              , dist  => $distribution;

    $self->{O_version} = $version;
    $self;
}

#-------------------------------------------


sub distribution() {shift->{O_distribution}}


sub version() {shift->{O_version}}


sub project() {shift->{O_project}}

#-------------------------------------------


sub selectFiles($@)
{   my ($self, $files) = (shift, shift);

    my $select
      = ref $files eq 'Regexp' ? sub { $_[0] =~ $files }
      : ref $files eq 'CODE'   ? $files
      : ref $files eq 'ARRAY'  ? $files
      : error __x"use regex, code reference or array for file selection";

    return ($select, [])
        if ref $select eq 'ARRAY';

    my (@process, @copy);
    foreach my $fn (@_)
    {   if($select->($fn)) {push @process, $fn}
        else               {push @copy,    $fn}
    }

    ( \@process, \@copy );
}


sub processFiles(@)
{   my ($self, %args) = @_;

    exists $args{workdir}
        or error __x"requires a directory to write the distribution to";

    my $dest    = $args{workdir};
    my $source  = $args{source};
    my $distr   = $args{distribution} || $self->distribution;

    my $version = $args{version};
    unless(defined $version)
    {   my $fn  = defined $source ? File::Spec->catfile($source, 'version')
                :                   'version';
        $fn     = -f $fn          ? $fn
                : defined $source ? File::Spec->catfile($source, 'VERSION')
                :                   'VERSION';
        if(defined $fn)
        {   my $v = IO::File->new($fn, "r")
                or fault __x"cannot read version from {file}", file => $fn;
            $version = $v->getline;
            $version = $1 if $version =~ m/(\d+\.[\d\.]+)/;
            chomp $version;
        }
        elsif($version = $self->version) { ; }
        else
        {   error __x"there is no version defined for the source files";
        }
    }

    my $notice = '';
    if($notice = $args{notice})
    {   $notice =~ s/^(\#\s)?/# /mg;       # put comments if none
    }

    #
    # Split the set of files into those who do need special processing
    # and those who do not.
    #

    my $manfile
      = exists $args{manifest} ? $args{manifest}
      : defined $source        ? File::Spec->catfile($source, 'MANIFEST')
      :                          'MANIFEST';

    my $manifest = OODoc::Manifest->new(filename => $manfile);

    my $manout;
    if(defined $dest)
    {   my $manif = File::Spec->catfile($dest, 'MANIFEST');
        $manout   = OODoc::Manifest->new(filename => $manif);
        $manout->add($manif);
    }
    else
    {   $manout   = OODoc::Manifest->new(filename => undef);
    }

    my $select    = $args{select} || qr/\.(pm|pod)$/;
    my ($process, $copy) = $self->selectFiles($select, @$manifest);

    trace @$process." files to process and ".@$copy." files to copy";

    #
    # Copy all the files which do not contain pseudo doc
    #

    if(defined $dest)
    {   foreach my $filename (@$copy)
        {   my $fn = defined $source ? File::Spec->catfile($source, $filename)
                   :                   $filename;

            my $dn = File::Spec->catfile($dest, $fn);
            unless(-f $fn)
            {   warning __x"no file {file} to include in the distribution"
                  , file => $fn;
                next;
            }

            unless(-e $dn && ( -M $dn < -M $fn ) && ( -s $dn == -s $fn ))
            {   $self->mkdirhier(dirname $dn);

                copy $fn, $dn
                   or fault __x"cannot copy distribution file {from} to {to}"
                        , from => $fn, to => $dest;

                trace "  copied $fn to $dest";
            }

            $manout->add($dn);
        }
    }

    #
    # Create the parser
    #

    my $parser = $args{parser} || 'OODoc::Parser::Markov';
    my $skip_links = delete $args{skip_links};

    unless(ref $parser)
    {   eval "require $parser";
        error __x"cannot compile {pkg} class: {err}", pkg => $parser, err => $@
            if $@;

        $parser = $parser->new(skip_links => $skip_links)
           or error __x"parser {name} could not be instantiated", name=>$parser;
    }

    #
    # Now process the rest
    #

    foreach my $filename (@$process)
    {   my $fn = $source ? File::Spec->catfile($source, $filename) : $filename; 

        unless(-f $fn)
        {   warning __x"no file {file} to include in the distribution"
              , file => $fn;
            next;
        }

        my $dn;
        if($dest)
        {   $dn = File::Spec->catfile($dest, $fn);
            $self->mkdirhier(dirname $dn);
            $manout->add($dn);
        }

        # do the stripping
        my @manuals = $parser->parse
          ( input        => $fn
          , output       => $dn
          , distribution => $distr
          , version      => $version
          , notice       => $notice
          );

        trace "stripped $fn into $dn" if defined $dn;
        trace $_->stats for @manuals;

        foreach my $man (@manuals)
        {   $self->addManual($man) if $man->chapters;
        }
    }

    # Some general subtotals
    trace $self->stats;

    $self;
}

#-------------------------------------------


sub prepare(@)
{   my ($self, %args) = @_;

    info "collect package relations";
    $self->getPackageRelations;

    info "expand manual contents";
    foreach my $manual ($self->manuals)
    {   trace "  expand manual $manual";
        $manual->expand;
    }

    info "Create inheritance chapter";
    foreach my $manual ($self->manuals)
    {   trace "  create inheritance for $manual";
        $manual->createInheritance;
    }

    $self;
}


sub getPackageRelations($)
{   my $self = shift;
    my @manuals  = $self->manuals;  # all

    #
    # load all distributions (which are not loaded yet)
    #

    info "compile all packages";

    foreach my $manual (@manuals)
    {    next if $manual->isPurePod;
         trace "  require package $manual";

         eval "require $manual";
         warning __x"errors from {manual}: {err}", manual => $manual, err =>$@
            if $@ && $@ !~ /can't locate/i && $@ !~ /attempt to reload/i;
    }

    info "detect inheritance relationships";

    foreach my $manual (@manuals)
    {
        trace "  relations for $manual";

        if($manual->name ne $manual->package)  # autoloaded code
        {   my $main = $self->mainManual("$manual");
            $main->extraCode($manual) if defined $main;
            next;
        }
        my %uses = $manual->collectPackageRelations;

        foreach (defined $uses{isa} ? @{$uses{isa}} : ())
        {   my $isa = $self->mainManual($_) || $_;

            $manual->superClasses($isa);
            $isa->subClasses($manual) if ref $isa;
        }

        if(my $realizes = $uses{realizes})
        {   my $to  = $self->mainManual($realizes) || $realizes;

            $manual->realizes($to);
            $to->realizers($manual) if ref $to;
        }
    }

    $self;
}

#-------------------------------------------


our %formatters =
 ( pod   => 'OODoc::Format::Pod'
 , pod2  => 'OODoc::Format::Pod2'
 , pod3  => 'OODoc::Format::Pod3'
 , html  => 'OODoc::Format::Html'
 , html2 => 'OODoc::Format::Html2'
 );

sub create($@)
{   my ($self, $format, %args) = @_;

    my $dest    = $args{workdir}
       or error __x"create requires a directory to write the manuals to";

    #
    # Start manifest
    #

    my $manfile  = exists $args{manifest} ? $args{manifest}
                 : File::Spec->catfile($dest, 'MANIFEST');
    my $manifest = OODoc::Manifest->new(filename => $manfile);

    # Create the formatter

    unless(ref $format)
    {   $format = $formatters{$format}
            if exists $formatters{$format};

        eval "require $format";
        error __x"formatter {name} has compilation errors: {err}"
          , name => $format, err => $@ if $@;

        my $options    = delete $args{format_options} || [];

        $format = $format->new
          ( manifest    => $manifest
          , workdir     => $dest
          , project     => $self->distribution
          , version     => $self->version
          , @$options
          );
    }

    #
    # Create the manual pages
    #

    my $select = ! defined $args{select}     ? sub {1}
               : ref $args{select} eq 'CODE' ? $args{select}
               : sub { $_[0]->name =~ $args{select}};

    foreach my $package (sort $self->packageNames)
    {
        foreach my $manual ($self->manualsForPackage($package))
        {   next unless $select->($manual);

            unless($manual->chapters)
            {   trace "  skipping $manual: no chapters";
                next;
            }

            trace "  creating manual $manual with ".(ref $format);

            $format->createManual
              ( manual         => $manual
              , template       => $args{manual_templates}
              , append         => $args{append}
              , format_options => ($args{manual_format} || [])
              );
        }
    }

    #
    # Create other pages
    #

    trace "creating other pages";
    $format->createOtherPages
     ( source   => $args{other_templates}
     , process  => $args{process_files}
     );

    $format;
}


sub stats()
{   my $self = shift;
    my @manuals  = $self->manuals;
    my $manuals  = @manuals;
    my $realpkg  = $self->packageNames;

    my $subs     = map {$_->subroutines} @manuals;
    my @options  = map { map {$_->options} $_->subroutines } @manuals;
    my $options  = @options;
    my $examples = map {$_->examples}    @manuals;

    my $diags    = map {$_->diagnostics} @manuals;
    my $distribution   = $self->distribution;
    my $version  = $self->version;

    <<STATS;
$distribution version $version
  Number of package manuals: $manuals
  Real number of packages:   $realpkg
  documented subroutines:    $subs
  documented options:        $options
  documented diagnostics:    $diags
  shown examples:            $examples
STATS
}

#-------------------------------------------


1;
