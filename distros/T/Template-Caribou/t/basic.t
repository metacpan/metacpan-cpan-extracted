use strict;
use warnings;

use 5.10.0;

use Test::More;

use Template::Caribou;
use Template::Caribou::Tags qw/ render_tag /;

use experimental 'signatures';

has '+indent' => ( default => 0 );

my $self = __PACKAGE__->new;

template inner_tmpl => sub {
    warn 'inner here';
    'hello world';
};

template outer => sub($self) {
    print 'x';
    $self->inner_tmpl;
    print 'x';
};

subtest 'inner_tmpl' => sub {
    is $self->inner_tmpl => 'hello world';
};

$::NOW = 1;
subtest 'outer' => sub {
    is $self->outer => 'xhello worldx';
};

sub foo :prototype(&) { render_tag( 'foo', shift ) }
sub bar :prototype(&) { render_tag( 'bar', shift ) }

template 'escape_outer' => sub {
    my $self = shift;
    foo {};
    foo { $self->escape_inner; };
    foo {};
};

template 'escape_inner' => sub {
    bar { '<yay>' };
};

subtest 'escaping' => sub {
    is $self->escape_outer
        => qq{<foo /><foo><bar>&lt;yay></bar></foo><foo />};
};

template 'end_show' => sub {
    foo { };
    $_[0]->inner_tmpl;
    return;
};

subtest 'end_show' => sub {
    is $self->end_show => '<foo />hello world';
};

template 'attributes' => sub {
    foo {
        attr foo => 'bar';
        attr 'foo';
    };
    foo {
        attr a => 1, b => 2;
        attr '+a' => 3, b => 4;
    }
};

subtest attributes => sub {
    is $self->attributes => 
        '<foo foo="bar">bar</foo><foo a="1 3" b="4" />';
};

subtest "print vs say" => sub {
    TODO: {
        local $TODO = "Perl bug, should be fixed in 5.18";

        is $self->render(sub{
            print "one";
            say "two";
            print ::RAW "three";
            say ::RAW "four";
        }) => "onetwo\nthreefour\n";
    }
};

done_testing;
