use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN{ 

unless( $ENV{AWS_ACCESS_KEY_ID} && 
        $ENV{AWS_ACCESS_KEY_SECRET} && 
        $ENV{AWS_TEMPLATE_BUCKET} ){

  plan skip_all => "We need Amazon Environment information to run tests. The following variables are needed.\n AWS_TEMPLATE_BUCKET,AWS_ACCESS_KEY_SECRET, AWS_ACCESS_KEY_ID ";

}

eval 'use Template';
plan skip_all => 'Test can not continue withot Template Toolkit installed. ' if $@;
eval 'use Net::Amazon::S3';
plan skip_all => 'Test can not continue withote Net::Amazon::S3 installed. ' if $@;
use_ok('Template::Provider::Amazon::S3') 
}

sub process_template($$$$) {
   my ($template, $template_name, $vars, $expected) = @_;
    my $output = "";
    ok( $template->process( $template_name, $vars, \$output ), 
        "Processing the template($template_name)." );
    my $err = $template->error();
    diag(' Got template error of: '. $err ) if $err;
    SKIP:{
      skip 'Can not check an undefined value. ', 1 unless defined $output;
      ok($output=~/$expected/i, 'Content is what we expected');
      note("The output is: $output");
    }
}
sub template_setup() {
    my $ts3 = Template::Provider::Amazon::S3->new( INCLUDE_PATH => ['.','blue','layout' ] ); #let's use the environment variables.
    my $template = Template->new( 
        LOAD_TEMPLATES => [ $ts3 ],
        INCLUDE_PATH => [ '.','blue','layout' ]
    );
    ok( $template , 'We go a template object');
    return ($ts3, $template);
}
sub do_template_tests {
    my ($ts3, $template) = template_setup;
    SKIP:{ 
       skip 'Can not continue without a template object', 2*2 unless $template;
       process_template $template, 'helloworld.tt', { name => 'John' }, qr/Hello\s+John/;
       process_template $template, 'blue/helloworld.tt', { name => 'John' }, qr/Blue Hello\s+John/;
       process_template $template, 'html_wrapper.tt', { name => 'John' }, qr/simple HTML wrapper/;
    }
}

sub do_simple_wrapped_tests {
    my ($ts3, $template) = template_setup;
    SKIP:{ 
       skip 'Can not continue without a template object', 2*1 unless $template;

       process_template $template, 'wrapped_content.tt', { name => 'Foo' }, qr/This is a simple HTML wrapper/;
    
    };
}

do_template_tests;
do_simple_wrapped_tests;
done_testing;
