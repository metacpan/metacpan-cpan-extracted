package Perlipse::SourceParser::AST;
use base qw(Class::Accessor);

use strict;
use fields qw(pkgs curPkg);

use XML::Writer;

my $util = 'Perlipse::SourceParser::AST::Util';

my @accessors = qw();
__PACKAGE__->mk_accessors(@accessors);

sub new
{
    my $class = shift;
    my $self  = fields::new($class);

    $self->{pkgs} = [];

    return $self;
}

sub addPkg
{
    my $self = shift;
    my ($pkg) = @_;

    # closeout an existing package
    if (defined $self->{curPkg})
    {
        my $sEnd = $pkg->sourceStart() - 1;
        $self->{curPkg}->sourceEnd($sEnd);
    }

    # add to the list of packages
    push @{$self->{pkgs}}, $pkg;
    
    # this package is now the current package
    $self->{curPkg} = $pkg;
}

sub curPkg
{
    my $self = shift;

    if (!defined $self->{curPkg})
    {
        $self->{curPkg} = _createMain($self);
        $self->addPkg($self->{curPkg});
    }
    
    return $self->{curPkg};    
}

sub createNode
{
    my $self = shift;
    my %args = @_;

    if (!exists $args{element})
    {
        my $type = $args{type};
        delete $args{type};

        return Perlipse::SourceParser::AST::Node->new($type, %args);
    }

    my $element = $args{element};
    # grab the keyword and it's value, ie: sub foo
    my ($keyword, $value) = $element->schildren;

    #
    # the offsets tell us where the keyword/value start and end based
    # upon their position in the document
    #
    my $k_offset = $keyword->location->[3];
    my $v_offset = $value->location->[3];

    return Perlipse::SourceParser::AST::Node->new(
        $element->class,
        name   => $value->content,
        nStart => $v_offset,
        nEnd   => $v_offset + $value->length,
        sStart => $k_offset,
    );
}

sub toXml
{
    my $self = shift;

    my $writer = new XML::Writer(DATA_INDENT => 2, DATA_MODE => 1);

    $writer->startTag('module');
    foreach my $pkg (@{$self->{pkgs}})
    {
        $pkg->toXml($writer);
    }

    $writer->endTag;
    $writer->end;
}

sub _createMain
{
    return shift->createNode(
        type   => 'PPI::Statement::Package',
        name   => 'main',
        nStart => 0,
        nEnd   => 0,
        sStart => 0,
    );    
}

package Perlipse::SourceParser::AST::Node;

use strict;
use fields qw(body type attr);

use Hash::Util;

my @keys = qw(name nStart nEnd sStart sEnd);

sub new
{
    my $class = shift;
    my $type  = shift;
    my %args  = @_;
    Hash::Util::lock_keys(%args, @keys);

    my $self = fields::new($class);

    $self->{body} = [];
    $self->{type} = $type;

    if (!exists $args{sEnd})
    {
        $args{sEnd} = 0;
    }

    $self->{attr} = \%args;

    return $self;
}

sub addStatement
{
    my $self = shift;
    my ($node) = @_;

    push @{$self->{body}}, $node;
}

sub nameEnd
{
    return shift->{attr}->{nEnd};
}

sub sourceStart
{
    my $self = shift;
    my ($start) = @_;

    if ($start)
    {
        $self->{attr}->{sStart} = $start;
    }

    return $self->{attr}->{sStart};
}

sub sourceEnd
{
    my $self = shift;
    my ($end) = @_;

    if ($end)
    {
        $self->{attr}->{sEnd} = $end;
    }

    return $self->{attr}->{sEnd};
}

sub toXml
{
    my $self = shift;
    my ($writer) = @_;

    my $type = $util->getType($self->{type});
    $writer->startTag($type, %{$self->{attr}});

    foreach my $node (@{$self->{body}})
    {
        $node->toXml($writer);
    }

    $writer->endTag;
}

package Perlipse::SourceParser::AST::Util;

use strict;

sub getType
{
    my $class = shift;
    my ($type) = @_;

    $type =~ m/.*\:\:(.*)/;

    return lcfirst($1);
}

1;
