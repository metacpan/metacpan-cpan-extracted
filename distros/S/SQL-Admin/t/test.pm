
package test;
use base qw( Exporter );

use strict;
use warnings;

use Data::Dumper;

use Test::More;

END {
    &run_registered_tests;
    done_testing;
}

######################################################################

use Attribute::Handlers;

our @EXPORT = (
    qw( run_registered_tests ),

    qw( parser   test_rule     rule_alias ),
    qw( producer test_products ),
);

my (%test_only, %test_dump);
my (@tests, %tests, %aliases);

my ($parser, $producer);

our $subtest_name;

######################################################################
######################################################################
sub run_registered_tests {               # ;
    my %only = %test_only;
    %only = %tests unless %only;

    for my $rule (grep $only{$_}, grep $tests{$_}, @tests) {
        my @data =  $tests{$rule}->();
        for my $name ($rule, @{ $aliases{$rule} || [] }) {
            test_rule ($name, @data);
        }
    }
}


######################################################################
######################################################################
sub UNIVERSAL::Test : ATTR(CODE) {       # ;
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my $name = *{ $symbol }{NAME};

    unless (exists $tests{$name}) {
        $tests{$name} = $referent;
        push @tests, $name;
    }
}

######################################################################
######################################################################
sub UNIVERSAL::TestOnly : ATTR(CODE) {   # ;
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my $name = *{ $symbol }{NAME};

    $test_only{$name} = 1;
    unless (exists $tests{$name}) {
        $tests{$name} = $referent;
        push @tests, $name;
    }
}

######################################################################
######################################################################
sub UNIVERSAL::Rule : ATTR(CODE) {       # ;
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my $name = *{ $symbol }{NAME};

    unless (exists $tests{$name}) {
        $tests{$name} = $referent;
        push @tests, $name;
    }
}

######################################################################
######################################################################
sub UNIVERSAL::RuleOnly : ATTR(CODE) {   # ;
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my $name = *{ $symbol }{NAME};

    $test_only{$name} = 1;
    unless (exists $tests{$name}) {
        $tests{$name} = $referent;
        push @tests, $name;
    }
}

######################################################################
######################################################################
sub UNIVERSAL::RuleDump : ATTR(CODE) {   # ;
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my $name = *{ $symbol }{NAME};

    $test_only{$name} = 1;
    $test_dump{$name} = 1;
    unless (exists $tests{$name}) {
        $tests{$name} = $referent;
        push @tests, $name;
    }
}

######################################################################
######################################################################
sub rule_alias ( @ ) {                   # ;
    my ($orig) = (caller (1))[3];
    $orig = substr $orig, 2 + rindex $orig, '::';

    push @{ $aliases{$orig} ||= []}, @_;
}


######################################################################
######################################################################
sub refhash ( ;$ ) {                     # ;
    'HASH' eq ref (@_ ? $_[0] : $_);
}


######################################################################
######################################################################
sub refarray ( ;$ ) {                    # ;
    'ARRAY' eq ref (@_ ? $_[0] : $_);
}


######################################################################
######################################################################
sub parser ( ;$ ) {                      # ;
    if (@_) {
        my $class = shift;

        $::RD_ERRORS = undef;
        $::RD_WARN = undef;

        use_ok ($class);
        $parser = new_ok ($class, \ @_);
    }

    $parser;
}


######################################################################
######################################################################
sub producer ( ;$ ) {                    # ;
    if (@_) {
        my $class = shift;

        use_ok ($class);
        $producer = new_ok ($class, \ @_);
    }

    $producer;
}


######################################################################
######################################################################
sub rule_ok {                            # ;
    my ($rule, $text, $value, $name) = @_;
    $name = join ': ', $rule, $text unless defined $name;

    is_deeply ($parser->$rule ($text), $value, $name);
}


######################################################################
######################################################################
sub rule_ok_multi {                      # ;
    my ($rule, @list) = @_;

    note ('subtest: ' . $rule);
    subtest $rule, sub {
        plan tests => scalar @list;
        rule_ok ($rule, @$_) for @list;
    };
}


######################################################################
######################################################################
sub rule_ok_multi_dump {                 # ;
    my ($rule, @list) = @_;

    rule_ok_dump ($rule, @$_) for @list;
}


######################################################################
######################################################################
sub rule_ok_dump {                       # ;
    my ($rule, $text, $value, $name) = @_;

    local $\ = "\n";
    print $text,' : ', Data::Dumper::Dumper ($parser->$rule ($text));
}


######################################################################
######################################################################
sub test_rule ( $@ ) {                   # ;
    my $rule = shift;
    my @data = map {
        my ($arg, $data) = @$_;
        if (refhash ($data) and exists $data->{_}) {
            $data = { %$data };
            $data->{$rule} = delete $data->{_};
        }

        [ $arg, $data ]
    } @_;

    ##################################################################

    return rule_ok_multi_dump ($rule => @data)
      if exists $test_dump{$rule};

    rule_ok_multi ($rule => @data)
}


######################################################################
######################################################################
sub test_products ( @ ) {                # ;
    my $method = $subtest_name;
    $method = shift unless ref $_[0];

    my @plan = @_;

    return unless defined $method;
    return unless @plan;

    subtest $method => sub {
        plan tests => scalar @plan;

        for my $plan (@plan) {
            my ($test, $data, @args) = @$plan;
            my $def = { $method => $data, map %$_, @args };

            #my $out = $producer->$method (@data);
            local $, = ' ';
            my $out = $producer->__call ($method, $def);

            my ($res, $val) = ($out, $test);
            for ($res, $val) {
                s/\s+/ /g;
                s/ ?\B ?//g;

                #my ($res) = map { s/\s+//g; lc $_ } $out;
                #my ($val) = map { s/\s+//g; lc $_ } $test;
            }

            is (lc $res, lc $val, $method . ': ' . $plan->[0]);
        }
    }
}


######################################################################
######################################################################


package test;

1;
