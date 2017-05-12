# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Format::Pod2;
use vars '$VERSION';
$VERSION = '2.01';

use base qw/OODoc::Format::Pod OODoc::Format::TemplateMagic/;

use strict;
use warnings;

use Log::Report    'oodoc';
use Template::Magic;

use File::Spec;
use IO::Scalar;


my $default_template;
{   local $/;
    $default_template = <DATA>;
    close DATA;
}

sub createManual(@)
{   my ($self, %args) = @_;
    $self->{O_template} = delete $args{template} || \$default_template;
    $self->SUPER::createManual(%args) or return;
}

sub formatManual(@)
{   my ($self, %args) = @_;
    my $output    = delete $args{output};

    my %permitted =
     ( chapter     => sub {$self->templateChapter(shift, \%args) }
     , diagnostics => sub {$self->templateDiagnostics(shift, \%args) }
     , append      => sub {$self->templateAppend(shift, \%args) }
     , comment     => sub { '' }
     );

    my $template  = Template::Magic->new
     ( { -lookups => \%permitted }
     );

    my $layout  = ${$self->{O_template}};        # Copy needed by template!
    my $created = $template->output(\$layout);
    $output->print($$created);
}


sub templateChapter($$)
{   my ($self, $zone, $args) = @_;
    my $contained = $zone->content;
    defined $contained && length $contained
        or warning __x"no meaning for container {c} in chapter block"
             , c => $contained;

    my $attrs = $zone->attributes;
    my $name  = $attrs =~ s/^\s*(\w+)\s*\,?// ? $1 : undef;

    unless(defined $name)
    {   error __x"chapter without name in template.";
        return '';
    }

    my @attrs = $self->zoneGetParameters($attrs);
    my $out   = '';

    $self->showOptionalChapter($name, %$args
      , output => IO::Scalar->new(\$out), @attrs);

    $out;
}

sub templateDiagnostics($$)
{   my ($self, $zone, $args) = @_;
    my $out = '';
    $self->chapterDiagnostics(%$args, output => IO::Scalar->new(\$out));
    $out;
}

sub templateAppend($$)
{   my ($self, $zone, $args) = @_;
    my $out   = '';
    $self->showAppend(%$args, output => IO::Scalar->new(\$out));
    $out;
}


1;

__DATA__
=encoding utf8

{chapter NAME}
{chapter INHERITANCE}
{chapter SYNOPSIS}
{chapter DESCRIPTION}
{chapter OVERLOADED}
{chapter METHODS}
{chapter FUNCTIONS}
{chapter CONSTANTS}
{chapter EXPORTS}
{chapter DETAILS}
{diagnostics}
{chapter REFERENCES}
{chapter COPYRIGHTS}
{comment In stead of append you can also add texts directly}
{append}
