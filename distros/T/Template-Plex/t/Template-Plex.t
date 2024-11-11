use strict;
use warnings;
use feature qw<say>;

use Test::More tests => 22;
use Log::OK {sys=>"Log::ger"};

BEGIN { use_ok('Template::Plex') };

use Template::Plex;

my $default_data={data=>[1,2,3,4]};

my $template=q|@{[ do {
		my $s="";
		for my $d ($fields{data}->@*) {
			$s.="row $d\n"
		}
		$s;
	}]}|;


$template=Template::Plex->load([$template], $default_data);
my $result=$template->render();
my $expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Base values";

$default_data->{data}=[5,6,7,8];
$result=$template->render();
$expected="";
for(5,6,7,8){
        $expected.="row $_\n";
}
ok $result eq $expected, "Updated Base values";



my $override_data={data=>[9,10,11,12]};
$result=$template->render($override_data);
$expected="";
for(9,10,11,12){
        $expected.="row $_\n";
}
ok $result eq $expected, "Using override values";



$template=q|@{[init {}]}
@{[
        do {
                my $s="";
                for my $d ($data->@*) {
                        $s.="row $d\n"
                }
                $s;
        }
]}|;

$default_data={data=>[1,2,3,4]};
$template=Template::Plex->load([$template], $default_data);
$template->setup;
$result=$template->render($override_data);
$expected="";
for(1,2,3,4){
        $expected.="row $_\n";
}
ok $result eq $expected, "Lexical access";


$template=q|@{[init {}]}my name is $name not $fields{name}|;
$default_data={name=>"John"};
$override_data={name=>"Jill"};

$template=Template::Plex->load([$template], $default_data);
$template->setup;
$result=$template->render($override_data);
$expected="";
ok $result eq "my name is John not Jill", "Lexical and override access";

{
        my $top_level=["Hello"];
        my @t=(undef, undef);
        for my $t (@t){
                $t=Template::Plex->cache(undef, $top_level);
        }
        ok $t[0]==$t[1], "Cached template reused";
}


{
        my $top_level='@{[init{}]}top level template recursively using another:@{[immediate undef, "sub1.plex"]}';

        my $t=Template::Plex->load([$top_level], {}, root=> "t");
        my $text=$t->render;
        my($first,$last)=split ":", $text;
        ok $last eq 'Sub template 1', "Recursive plex";
}

{
        my $top_level='@{[init{}]}top level template recursively using another:@{[immediate undef, "sub2.plex"]}';
        my %vars=(value=>10,user=>{});
        my $t=Template::Plex->load([$top_level], \%vars, root=> "t");
        my $text=$t->render;
        my($first,$last)=split ":", $text;
        ok $last eq 'Sub template 2 10', "Recursive plex, top aliased";
        ok $vars{user}{new_field} eq "NEW", "New field from sub template";
}


{
        my $top_level='This template is loaded,cached and executed automatically. $value';
        my %vars=(value=>10);
        for(10,20){
                $vars{value}=$_;
                my $output= Template::Plex->immediate(undef, [$top_level], \%vars);
                ok $output =~ /$_/, "immediate rendering ok";
        }
}

{
        my $top_level='@{[init{}]}skipped:@{[immediate undef, "sub3.plex"]}';
        my %vars=(value=>10);
        my $t=Template::Plex->load([$top_level], \%vars, root=> "t");

        my $text=$t->render;
        ok $text eq 'skipped:', "skip template";
}

{
        #Testing base class
        my %vars;
        my $result=Template::Plex->immediate(undef, ['@{[init{}]}@{[$self->__internal_test_proxy__]}'], \%vars);


        ok $result eq "PROXY", "Base class methods";

}
{
        #Testing sub class
        package My::Base{
                use parent "Template::Plex";
                sub __internal_test_proxy__{
                        "OVERRIDE";

                }
        }
        my %vars;
        my $result= Template::Plex->immediate(undef, ['@{[$self->__internal_test_proxy__]}'], \%vars, base=>"My::Base");

        ok $result eq "OVERRIDE", "Subclass methods";

}

{

        #Testing perpare/init
        my $tt=[
                '@{[init{
                        $self->args->{test}="testing";
                } ]}Hello!'
        ];

        my %vars;
        my $template=Template::Plex->load($tt, \%vars);
        ok $vars{test} eq "testing", "Setup without render";

        #my $setup=$template->setup;
        my $render=$template->render;
        ok $render eq "Hello!", "Render";
}


{
  # Test catching compile time errors
  
  my $tt=[
    '@{[init{
    $self->args->{test}="testing";
    {1+a
    } ]}Hello!'
  ];
        my %vars;
        my $template=
        eval {
          Template::Plex->load($tt, \%vars);
        };
        ok !defined($template), "Template load fail ok";

        ok $@, "Compile error set";
        if($@){
          my $expected='4=>     } ]}Hello!';
          #say STDERR "RESULT: $@";
          #say STDERR "Expected $expected";
          ok $@=~/$expected/s, "Error as expected";
          #test for the correct line number
        }
}

{
  # Test catching errors in body
  
  my $tt=[
    '@{[init{
    $self->args->{test}="testing";
    } ]}Hello!
    {]1+a'


  ];
        my %vars;
        my $template=
        eval {
          Template::Plex->load($tt, \%vars);
        };
        ok !defined($template), "Template load failed ok";

        ok $@, "Compile error set";

        if($@){
          #my $expected='4=>     \} \]\}Hello\!';
          #say STDERR "RESULT: $@";
          #ok $@=~/$expected/s;
          #test for the correct line number
        }
}
