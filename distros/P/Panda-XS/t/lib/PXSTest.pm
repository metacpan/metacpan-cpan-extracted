package PXSTest;
use 5.012;
use warnings;

use Config;
use Panda::XS;
use Test::More;
use Test::Deep;
use Data::Dumper;

sub import {
    my ($class, @reqs) = @_;
    if (@reqs) {
        require_full();
        no strict 'refs';
        &{"require_$_"}() for @reqs;
    }
    
    my $caller = caller();
    foreach my $sym_name (qw/Config is cmp_deeply ok done_testing skip isnt Dumper noclass/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
    }
    
    foreach my $sym_name (qw/dcnt/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *{"Panda::XS::Test::$sym_name"};
    }
    
}

sub require_full {
    plan skip_all => 'rebuild Makefile.pl adding TEST_FULL=1 to enable all tests'
        unless Panda::XS::Test->can('i8');
}

sub require_threads {
    plan skip_all => 'threaded perl required to run these tests'
        unless eval "use threads; use threads::shared; 1;";
}

{
    package Panda::XS::Test::Mixin;
    use mro 'c3';
    our @ISA = qw/Panda::XS::Test::MixPluginB Panda::XS::Test::MixPluginA Panda::XS::Test::MixBase/;
    
    
    package Panda::XS::Test::BadMixin;
    use mro 'c3';
    our @ISA = qw/Panda::XS::Test::MixPluginB Panda::XS::Test::MixBase/;


    package Panda::XS::Test::MyPTRBRUnit;
    our @ISA = 'Panda::XS::Test::PTRBRUnit';
    
    sub id { my $self = shift; return $self->SUPER::id() + 111 }
    
    package Panda::XS::Test::MyBRUnit;
    our @ISA = 'Panda::XS::Test::BRUnit';
    
    sub id { my $self = shift; return @_ ? $self->SUPER::id(@_) : ($self->SUPER::id() + 111) }
    
    
    package Panda::XS::Test::MyBRUnitAdvanced;
    our @ISA = 'Panda::XS::Test::MyBRUnit';
    
    sub new {
        my $special = pop;
        my $self = shift->new_enabled(@_);
        Panda::XS::obj2hv($self);
        $self->{special} = $special;
        return $self;
    }
    
    sub special { shift->{special} }    


    package Panda::XS::Test::MyBRUnitSP;
    our @ISA = 'Panda::XS::Test::BRUnitSP';
    
    sub id { my $self = shift; return @_ ? $self->SUPER::id(@_) : ($self->SUPER::id() + 111) }
}

1;
