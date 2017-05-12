package Pinwheel::Helpers::Core;

use strict;
use warnings;

use Exporter;

use Pinwheel::Context;
use Pinwheel::View::String;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(content_for yield urlencode urldecode);


sub content_for
{
    my ($name, $fn) = @_;
    my ($ctx, $s);

    $ctx = Pinwheel::Context::get('render');
    $s = &$fn;
    $s = Pinwheel::View::String->new($s) unless ref($s);

    $ctx->{content}{$name} = ($ctx->{content}{$name} || '') . $s;
}

sub yield
{
    return Pinwheel::Context::get('render')->{content}{shift() || 'layout'};
}

sub urlencode
{
    my $str = shift;
    $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $str;
}

sub urldecode
{
    my $str = shift;
    $str =~ s/%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}


1;
