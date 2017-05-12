use strict;
use 5.010;
use Test::More;
use Pandoc::Filter;
use Pandoc::Elements;

# action function
my $action = sub {
    return unless $_[0]->name eq 'Header' and $_[0]->level >= 2;
    Para [ Emph $_[0]->content ];
};
my $h1 = Header(1, attributes {}, [ Str 'hello']);
my $h2 = Header(2, attributes {}, [ Str 'hello']);

is $action->($h1), undef, 'action';
is_deeply $action->($h2), Para [ Emph [ Str 'hello' ] ], 'action';


{
    my $doc = Document {}, [ $h1, $h2 ];
    Pandoc::Filter->new($action)->apply($doc);
    is_deeply $doc->content->[1], Para [ Emph [ Str 'hello' ] ], 'apply';
}

{
    my $doc = Document { title => MetaInlines [ Str 'test' ] }, [ $h1, $h2 ];
    Pandoc::Filter->new(  
        Header => sub { 
            Para [ Str $_[1] . ':' . $_[2]->{title}->string ]
        }
    )->apply($doc, 'html');
    is_deeply $doc->content->[1], Para [ Str 'html:test' ], 'format and metadata';
}

# TODO: should croak because 1 is no selector ( 1 => sub { } )
# eval { Pandoc::Filter->new( 1 ) }; ok $@, 'invalid filter';

my $doc = Document {}, [ Str "hello" ];
my $filter = Pandoc::Filter->new(sub {
    return if $_->name ne 'Str';
    $_->{c} = uc $_->{c};
    return [ $_, Str " world!" ];
});

$filter->apply($doc);

is_deeply $doc->content, [ Str('HELLO'), Str(' world!') ], "don't filter injected elements";

done_testing;
