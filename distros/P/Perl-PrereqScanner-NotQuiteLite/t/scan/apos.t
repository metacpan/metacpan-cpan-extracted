use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # PHRED/WebService-NetSuite-0.04/lib/WebService/NetSuite.pm
    if (ref($hashOrInternalId) eq'HASH') {
        foreach my $k (keys %{$hashOrInternalId}) {
            $req{$k} = $hashOrInternalId->{$k};
        }
    } else {
        $req{'internalId'} = $hashOrInternalId;
    }
TEST

test(<<'TEST'); # SPROUT/WWW-Scripter-0.031/lib/WWW/Scripter.pm
    $self->{page_stack} = WWW'Scripter'History->new( $self );

    weaken(my $self_fc = $self); # for closures
    $class_info{$self} = [
     \(%HTML::DOM'Interface, %CSS'DOM'Interface, our%Interface), {
      'WWW::Scripter::Image' => "Image",
       Image                 => {
        _constructor => sub {
         my $i = $self_fc->document->createElement('img');
         @_ and $i->attr('width',shift);
         @_ and $i->attr('height',shift);
         $i
        }
       },
     }
    ];
TEST

done_testing;
