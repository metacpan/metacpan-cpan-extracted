package MyTest;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Panda::next;

sub import {
    my ($class) = @_;
    
    my $caller = caller();
    foreach my $sym_name (qw/Config is cmp_deeply ok done_testing skip isnt Dumper noclass subtest define undefine/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
        *{"${caller}::$sym_name"} = *$sym_name;
    }
}

sub define {
    my ($what, @where) = @_;
    foreach my $where (@where) {
        die unless $where =~ /(\d+)/;
        my $num = $1;
        my $code;
        if ($what eq 'can') {
            $code = "return \$_[0]->next::can";
        }
        elsif ($what eq 'next') {
            $code = $num == 1 ? "return 1" : "return shift->next::method(@_)+$num";
        }
        else { die "what: $what" }
        
        my $sub = "t_$what";
        eval "
            package $where;
            no warnings 'redefine';
            sub $sub { $code }
        ";
    }
}

sub undefine {
    my ($what, @where) = @_;
    foreach my $where (@where) {
        no strict 'refs';
        my $stash = \%{"${where}::"};
        delete $stash->{"t_$what"};
    }
}

{
    package M1;
    
    package M2;
    our @ISA = 'M1';
    
    package M3;
    our @ISA = 'M1';
    
    package M4;
    our @ISA = ('M2', 'M3');
}