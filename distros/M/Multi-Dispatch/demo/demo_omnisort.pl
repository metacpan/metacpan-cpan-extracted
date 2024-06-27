#! /usr/bin/env perl

use v5.22;
use warnings;
use experimental qw< signatures  lexical_subs >;

use Multi::Dispatch;

sub show ($label, @data) { say "$label ", join ', ', @data }


package Simple::Subroutine::Version;
use List::Util 1.14 'uniq';
use Types::Standard ':all';

sub omnisort ($opts, @data) {
    if ($opts->{uniq}) { @data = uniq @data; }

    if ($opts->{key}) {
        if ($opts->{fold}) {
            @data = map { [$_, fc $opts->{key}->($_)] } @data;
        }
        else {
            @data = map { [$_,    $opts->{key}->($_)] } @data;
        }
        if ((ArrayRef[Tuple[Num,Any]])->check(\@data)) {
            @data = sort { $a->[1] <=> $b->[1] } @data;
        }
        else {
            @data = sort { $a->[1] cmp $b->[1] } @data;
        }
        @data = map { $_->[0] } @data;
    }
    elsif ((ArrayRef[Num])->check(\@data)) {
        @data = sort { $a <=> $b } @data;
    }
    elsif ($opts->{fold}) {
        @data = sort { fc $a cmp fc $b } @data;
    }
    else {
        @data = sort @data;
    }
    if ($opts->{rev}) {
        return reverse @data;
    }
    else {
        return @data;
    }
}


say "\nFirst via a simple sub...";

::show 'STD:  ', omnisort({},                 3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'UNIQ: ', omnisort({uniq=>1},          3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'QINU: ', omnisort({rev=>1, uniq=>1},  3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);

::show 'UNIQ: ', omnisort({uniq=>1},          'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'LEN:  ', omnisort({key=>sub{length}}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'uniq: ', omnisort({uniq=>1, fold=>1}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');

::show 'NUM:  ', omnisort({key=>sub{/\d+$/?$&:$_}}, 'a0001', 'b0009', 'c0', 'd01', 'e003');


package Pure::Functional::Version;
use List::Util 'uniq';
use Types::Standard ':all';

sub omnisort ($opt, @data) {
    my sub of             { @_                                        }
    my sub uniques        { $opt->{uniq} ?    uniq @_         : @_    }
    my sub order          { $opt->{rev}  ? reverse @_         : @_    }
    my sub fold           { $opt->{fold} ? fc(shift)          : shift }
    my sub key            { $opt->{key}  ? $opt->{key}(shift) : shift }
    my sub labelledvalues { map { [$_, fold key $_] } @_              }
    my sub plainvalues    { map { $_->[0] } @_                        }
    my sub sorting        { (ArrayRef[Tuple[Num,Any]])->check(\@_) ? sort {$a->[1] <=> $b->[1]} @_
                          : (ArrayRef[ArrayRef]      )->check(\@_) ? sort {$a->[1] cmp $b->[1]} @_
                          : (ArrayRef[Num]           )->check(\@_) ? sort {$a      <=> $b     } @_
                          :                                          sort                       @_
                          }

    return order of plainvalues of sorting of labelledvalues of uniques of @data;
}


say "\nNext via functional programming...";

::show 'STD:  ', omnisort({},                 3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'UNIQ: ', omnisort({uniq=>1},          3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'QINU: ', omnisort({rev=>1, uniq=>1},  3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);

::show 'UNIQ: ', omnisort({uniq=>1},          'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'LEN:  ', omnisort({key=>sub{length}}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'uniq: ', omnisort({uniq=>1, fold=>1}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');

::show 'NUM:  ', omnisort({key=>sub{/\d+$/?$&:$_}}, 'a0001', 'b0009', 'c0', 'd01', 'e003');


package Multiply::Dispatched::Version;
use List::Util 'uniq';
use Types::Standard ':all';

multi sorted (Tuple[Num,Any] @data) { sort {$a->[1] <=> $b->[1]} @data }
multi sorted (      ArrayRef @data) { sort {$a->[1] cmp $b->[1]} @data }
multi sorted (           Num @data) { sort {$a      <=> $b     } @data }
multi sorted (               @data) { sort                       @data }

multi omnisort ({fold=>1, key=>$key, %opts}, @data)
                                            { next::variant {%opts, key=>sub{fc $key->($_)}}, @data }
multi omnisort ({fold=>1,    %opts}, @data) { next::variant {%opts, key => \&CORE::fc}, @data }
multi omnisort ({uniq=>1,    %opts}, @data) { next::variant \%opts, uniq @data }
multi omnisort ({ rev=>1,    %opts}, @data) { reverse next::variant \%opts, @data }
multi omnisort ({ key=>$key, %opts}, @data) { map {$_->[0]} sorted map {[$_, $key->($_)]} @data }
multi omnisort ({            %opts}, @data) { sorted @data }


say "\nAnd now via multi...";

::show 'STD:  ', omnisort({},                 3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'UNIQ: ', omnisort({uniq=>1},          3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);
::show 'QINU: ', omnisort({rev=>1, uniq=>1},  3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3);

::show 'UNIQ: ', omnisort({uniq=>1},          'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'LEN:  ', omnisort({key=>sub{length}}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');
::show 'uniq: ', omnisort({uniq=>1, fold=>1}, 'elephant', 'cat', 'dog', 'fish', 'Cat', 'DOG');

::show 'NUM:  ', omnisort({key=>sub{/\d+$/?$&:$_}}, 'a0001', 'b0009', 'c0', 'd01', 'e003');

