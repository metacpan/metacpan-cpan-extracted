# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Parser;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';
use List::Util     'first';


#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my $skip = delete $args->{skip_links} || [];
    my @skip = map { ref $_ eq 'Regexp' ? $_ : qr/^\Q$_\E(?:\:\:|$)/ }
        ref $skip eq 'ARRAY' ? @$skip : $skip;
    $self->{skip_links} = \@skip;

    $self;
}

#-------------------------------------------


sub parse(@) {panic}

#-------------------------------------------


sub skipManualLink($)
{   my ($self, $package) = @_;
    (first { $package =~ $_ } @{$self->{skip_links}}) ? 1 : 0;
}


sub cleanup($$$)
{   my ($self, $formatter, $manual, $string) = @_;

    return $self->cleanupPod($formatter, $manual, $string)
       if $formatter->isa('OODoc::Format::Pod');

    return $self->cleanupHtml($formatter, $manual, $string)
       if $formatter->isa('OODoc::Format::Html')
       || $formatter->isa('OODoc::Format::Html2');

    error __x"the formatter type {type} is not known for cleanup"
      , type => ref $formatter;

    $string;
}


1;

