package Mustache::Simple::ContextStack;

use strict;
use warnings;
use 5.10.1;
use version;

our $VERSION = version->declare('v1.3.6');

use Scalar::Util qw(blessed reftype);
use Carp;
our @CARP_NOT = qw(Mustache::Simple);

# Don't forget to change the version in the pod

#use Data::Dumper;
#$Data::Dumper::Useqq = 1;
#$Data::Dumper::Deparse = 1;
#
#use Data::Dump qw(dumpf);
#
#sub debug($)
#{
#    say dumpf(shift, sub {
#            my ($ctx, $ref) = @_;
#            return { dump => qq(<$ref>) } if $ctx->object_isa('DateTime');
#        }
#    );
#    say "-" x 50;
#}

sub new
{
    my $class = shift;
    my $self = [];
    bless $self, $class;
}

sub push
{
    my $self = shift;
    my $context = shift;
    push @$self, $context;
}

sub pop
{
    my $self = shift;
    my $context = pop @$self;
    return $context;
}

sub search
{
    my $self = shift;
    my $element = shift;
    for (my $i = $#$self; $i >= 0; $i--)
    {
	my $context = $self->[$i];
        if (blessed $context)
        {
	    if ($context->can($element)) {
		my @ret = $context->$element(); # array context
		return @ret if wantarray();
		return $ret[0]; # first elt will be answer if non-array context
	    }
        }
	next unless reftype $context eq 'HASH';

	return $context->{$element} if exists $context->{$element};
    }
    return undef;
}

sub top
{
    my $self = shift;
    return $self->[-1];
}

1;
